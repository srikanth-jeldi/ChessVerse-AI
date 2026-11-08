"""Reproducible offline cleanup/packing of the approved generated Staunton art.

No runtime filters or new dependencies. Preserve existing animation asset paths.
"""
from pathlib import Path
from collections import deque
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'docs/artwork/pieces-340'
OUT = ROOT / 'mobile/assets/pieces'
NAMES = ['king', 'queen', 'bishop', 'knight', 'rook', 'pawn']
HEIGHTS = [270, 238, 223, 218, 195, 169]
FINISHES = {
    'crimson-crown-3d': ((255, 235, 204), (154, 39, 55)),
    'inferno-gold': ((255, 207, 109), (100, 62, 29)),
    'ruby-emperor': ((255, 225, 226), (126, 24, 62)),
    'obsidian-regal': ((245, 243, 230), (50, 57, 70)),
    'sapphire-elite': ((220, 240, 255), (26, 78, 154)),
    'emerald-sovereign': ((222, 255, 235), (22, 108, 78)),
}

def clean(cell):
    # The generator left almost-transparent RGB speckles. Keep the main
    # connected silhouette above alpha 100; feather only its outer edge.
    a = cell.getchannel('A')
    w, h = cell.size
    eligible = {i for i, v in enumerate(a.getdata()) if v > 100}
    largest = set()
    while eligible:
        start = eligible.pop()
        component = {start}
        queue = deque([start])
        while queue:
            i = queue.popleft()
            x, y = i % w, i // w
            for j in (i-1 if x else -1, i+1 if x<w-1 else -1,
                      i-w if y else -1, i+w if y<h-1 else -1):
                if j in eligible:
                    eligible.remove(j); component.add(j); queue.append(j)
        if len(component) > len(largest): largest = component
    mask = Image.new('L', cell.size)
    mask.putdata([255 if i in largest else 0 for i in range(w*h)])
    cell.putalpha(mask)
    bounds = mask.getbbox()
    assert bounds and len(largest) > 5000
    return cell.crop(bounds)

def finish(image, tint, white):
    result = image.copy()
    pixels = []
    for r,g,b,a in image.getdata():
        # Retain metallic gold bands; tint the body while keeping reflections.
        gold = r > g * 1.08 and g > b * 1.15
        if a and not gold:
            lum = (r+g+b)/3
            if white:
                r,g,b = [round(lum * t/255) for t in tint]
            else:
                strength = min(1, lum/85)
                highlight = max(0, (lum-85)/170)
                r,g,b = [round(t*strength*(1-highlight)+255*highlight) for t in tint]
        pixels.append((r,g,b,a))
    result.putdata(pixels)
    return result

def main():
    atlas = Image.open(ART/'source.png').convert('RGBA')
    xs = [0,325,620,905,1190,1490,1774]
    tiles = {}
    for row, side in enumerate(['white','black']):
        for col, name in enumerate(NAMES):
            piece = clean(atlas.crop((xs[col], row*443, xs[col+1], min(887,(row+1)*443))))
            scale = min(HEIGHTS[col]/piece.height, 225/piece.width)
            piece = piece.resize((round(piece.width*scale), round(piece.height*scale)), Image.Resampling.LANCZOS)
            tile = Image.new('RGBA',(300,300))
            tile.alpha_composite(piece, ((300-piece.width)//2, 285-piece.height))
            tile.save(OUT/f'staunton_{side}_{name}.png', optimize=True)
            tiles[side,name] = tile
            for key, colors in FINISHES.items():
                themed = finish(tile, colors[row], row==0)
                for base in [OUT/'premium_individual'/key/side, OUT/'premium_individual/mobile-readable'/key/side]:
                    base.mkdir(parents=True,exist_ok=True)
                    themed.save(base/f'{name}.webp', lossless=True, method=2)
                themed.save(OUT/'premium_individual/mobile-readable'/key/side/f'{name}.png', optimize=True)
    # Inspect all finishes at actual board-like cell sizes, plus full board.
    preview = Image.new('RGB',(720, 7*144),(8,25,38))
    draw=ImageDraw.Draw(preview)
    for row,key in enumerate(['classic']+list(FINISHES)):
        draw.text((5,row*144+3),key,fill='white')
        for side_index,side in enumerate(['white','black']):
            for col,name in enumerate(NAMES):
                p=tiles[side,name] if key=='classic' else Image.open(OUT/'premium_individual'/key/side/f'{name}.webp')
                x=(side_index*6+col)*60; y=row*144+28
                draw.rectangle((x,y,x+59,y+95),fill=('#cdbd9d' if col%2 else '#594b3d'))
                p=p.resize((60,60),Image.Resampling.LANCZOS)
                preview.paste(p,(x,y+18),p)
    preview.save(ART/'all-finishes.png')
    board=Image.new('RGB',(640,640))
    draw=ImageDraw.Draw(board)
    order=['rook','knight','bishop','queen','king','bishop','knight','rook']
    for rank in range(8):
        for file in range(8):
            draw.rectangle((file*80,rank*80,file*80+79,rank*80+79),fill=('#ddd4b9' if (rank+file)%2==0 else '#16364c'))
            if rank in (0,1,6,7):
                side='black' if rank<2 else 'white'
                name=order[file] if rank in (0,7) else 'pawn'
                p=tiles[side,name].resize((80,80),Image.Resampling.LANCZOS)
                board.paste(p,(file*80,rank*80),p)
    board.save(ART/'board-preview.png')
    print('Updated 12 standard and 144 desktop/mobile premium runtime pieces; 72 source PNGs.')

if __name__=='__main__': main()

