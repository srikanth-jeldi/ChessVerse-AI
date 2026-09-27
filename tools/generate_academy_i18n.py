"""Generate static Academy UI translations with NLLB; build tooling only."""
import ast, json, os, re, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
ACADEMY=ROOT/'backend/src/main/resources/static/academy'
FILES=['portal.js','signin.js','onboarding.js','premium.js','workflow.js','index.html']
LANGS={'te':'tel_Telu','hi':'hin_Deva','ta':'tam_Taml','kn':'kan_Knda','ml':'mal_Mlym','mr':'mar_Deva','bn':'ben_Beng','gu':'guj_Gujr','pa':'pan_Guru','ur':'urd_Arab','ar':'arb_Arab','es':'spa_Latn','fr':'fra_Latn','de':'deu_Latn','it':'ita_Latn','pt':'por_Latn','ru':'rus_Cyrl','uk':'ukr_Cyrl','tr':'tur_Latn','fa':'pes_Arab','zh':'zho_Hans','ja':'jpn_Jpan','ko':'kor_Hang','id':'ind_Latn','ms':'zsm_Latn','th':'tha_Thai','vi':'vie_Latn','pl':'pol_Latn','nl':'nld_Latn','sv':'swe_Latn','el':'ell_Grek','he':'heb_Hebr','sw':'swh_Latn'}
SKIP=('SELECT ','INSERT ','UPDATE ','DELETE ','CREATE ','ALTER ',' WHERE ',' FROM ','/api/','https://','M3 ','rgba(','linear-gradient','data:')

def phrases():
    out=set()
    for name in FILES:
        text=(ACADEMY/name).read_text(encoding='utf-8')
        chunks=[]
        for m in re.finditer(r"(?P<q>['\"`])(?P<s>[^\r\n]*?)(?<!\\)(?P=q)",text): chunks.append(m.group('s'))
        for raw in chunks:
            raw=re.sub(r'\$\{.*?\}',' ',raw)
            raw=re.sub(r'<[^>]*>','\n',raw)
            raw=raw.replace('\\n','\n').replace('&nbsp;',' ')
            for part in re.split(r'[\n|]',raw):
                p=re.sub(r'\s+',' ',part).strip(' ·–—:;,.()[]{}')
                codeish=bool(re.search(r'[<>{}=$\\`;]|=>|\?\.|\b(?:const|let|function|return|map|join|filter|slice|state|item|class|textarea|input|button|option|section|span|div|svg|path|break|case|empty|badge|field|select)\b',p))
                svgpath=bool(re.fullmatch(r'[MmLlHhVvCcSsQqTtAaZz0-9 .,+-]+',p) and re.search(r'\d',p))
                if 2<=len(p)<=240 and re.search(r'[A-Za-z]',p) and (' ' in p or p[0].isupper()) and not codeish and not svgpath and not any(x in p for x in SKIP) and not re.fullmatch(r'[A-Z0-9_ -]+',p):out.add(p)
    # Core single-word controls and statuses are intentionally included.
    out.update('Dashboard Students Coaches Assignments Attendance Notifications Support Branding Billing Reports Announcements Search Save Cancel Close Edit Delete Approve Reject Active Inactive Completed Overdue Present Absent Late Excused Weekly Monthly Upgrade Downgrade'.split())
    out.update({'Billing & Licensing','Notification Preferences','Progress Reports','Academy invitations','Attendance register','Subscription change requests','Organization Audit Log','Academy Announcements','Roles & Permissions','Organization Members','Report schedules','Generated Reports','Payment failed','Invoice emailed','Renewal reminder','Send reminder','Invitation reminder sent','Member deactivated','Subscription request reviewed','Schedule progress reports','Change academy subscription'})
    out.difference_update({'⌘ K','T12:00:00Z','height: px','use strict','Content-Type','Escape','Enter','Choose','ChessVerseAI','by EpitomeHub','Powered by EpitomeHub','one month','recorded mistakes'})
    return sorted(out,key=lambda s:(len(s),s))

def main():
    from transformers import AutoTokenizer
    import ctranslate2
    ps=phrases();print(f'{len(ps)} source phrases',flush=True)
    model_id='facebook/nllb-200-distilled-600M'
    tok=AutoTokenizer.from_pretrained(model_id,src_lang='eng_Latn')
    model_path=Path(os.environ['TEMP'])/'academy-nllb-ct2'
    translator=ctranslate2.Translator(str(model_path),device='cpu',compute_type='int8')
    progress=Path(os.environ.get('TEMP','.' ))/'chessverse-academy-i18n-progress.json'
    catalog=json.loads(progress.read_text(encoding='utf-8')) if progress.exists() else {'en':{p:p for p in ps}}
    catalog['en']={p:p for p in ps}
    for code,target in LANGS.items():
        existing=catalog.get(code,{})
        missing=[p for p in ps if p not in existing]
        if not missing:
            catalog[code]={p:existing[p] for p in ps}
            print(code+' cached',flush=True)
            continue
        translated=[]
        for i in range(0,len(missing),64):
            batch=missing[i:i+64];sources=[tok.convert_ids_to_tokens(tok.encode(x,truncation=True,max_length=144)) for x in batch]
            generated=translator.translate_batch(sources,target_prefix=[[target]]*len(batch),beam_size=1,max_decoding_length=96)
            translated.extend(tok.decode(tok.convert_tokens_to_ids(r.hypotheses[0][1:]),skip_special_tokens=True) for r in generated)
        existing.update(dict(zip(missing,translated)));catalog[code]={p:existing[p] for p in ps};progress.write_text(json.dumps(catalog,ensure_ascii=False),encoding='utf-8');print(code,flush=True)
    output='window.ACADEMY_I18N='+json.dumps(catalog,ensure_ascii=False,separators=(',',':'))+';\n'
    (ACADEMY/'academy-i18n-catalog.js').write_text(output,encoding='utf-8')

if __name__=='__main__':main()
