import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth/data/auth_session_store.dart';
import '../../online/data/online_match_api.dart';
import '../data/social_api.dart';
import '../data/community_api.dart';
import '../../notifications/presentation/notification_center_screen.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({this.onOpenMatch, this.previewHub, super.key});
  final ValueChanged<OnlineMatchDto>? onOpenMatch;
  final SocialHubDto? previewHub;
  @override State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> {
  static const SocialApi _api = SocialApi();
  static const CommunityApi _communityApi = CommunityApi();
  StoredAuthSession? _session;
  SocialHubDto? _hub;
  CommunityDto? _community;
  int _section = 0;
  String? _error;
  bool _busy = true;

  @override void initState() {
    super.initState();
    if (widget.previewHub != null) {
      _hub = widget.previewHub;
      _community = const CommunityDto(clubs: <ClubDto>[], tournaments: <TournamentDto>[], conversations: <ConversationDto>[], fairPlayScore: 100);
      _busy = false;
    } else {
      _refresh();
    }
  }
  Future<void> _refresh() async {
    if (mounted) setState(() { _busy = true; _error = null; });
    try {
      final StoredAuthSession? session = await const AuthSessionStore().read();
      if (session == null) throw const SocialException('Sign in to use friends and challenges.');
      final List<Object> values = await Future.wait<Object>(<Future<Object>>[_api.load(session.token), _communityApi.load(session.token)]);
      if (mounted) setState(() { _session = session; _hub = values[0] as SocialHubDto; _community = values[1] as CommunityDto; _busy = false; });
    } on SocialException catch (error) {
      if (mounted) setState(() { _error = error.message; _busy = false; });
    }
  }

  Future<void> _addFriend() async {
    final TextEditingController controller = TextEditingController();
    final String? username = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Add a ChessVerseAI friend'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(
        labelText: 'Username', prefixIcon: Icon(Icons.alternate_email_rounded))),
      actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Send request'))],
    ));
    controller.dispose();
    if (username == null || username.isEmpty || _session == null) return;
    await _act(() => _api.addFriend(_session!.token, username));
  }

  Future<void> _act(Future<SocialHubDto> Function() action) async {
    try { final SocialHubDto hub = await action(); if (mounted) setState(() => _hub = hub); }
    on SocialException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message))); }
  }

  Future<void> _challenge(SocialPlayerDto friend) async {
    int minutes = 10;
    final int? choice = await showModalBottomSheet<int>(context: context, backgroundColor: const Color(0xFF071927),
      builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text('Challenge ${friend.displayName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8), const Text('Choose an authoritative server clock.'), const SizedBox(height: 18),
          Wrap(spacing: 8, children: <int>[3,5,10,15].map((value) => ChoiceChip(label: Text('$value min'), selected: minutes == value,
            onSelected: (_) { minutes = value; Navigator.pop(context, value); })).toList()),
        ]))));
    if (choice == null || _session == null) return;
    try {
      final SocialChallengeDto value = await _api.challenge(_session!.token, friend.playerId, choice);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Challenge sent • room ${value.roomCode}')));
      await _refresh();
    } on SocialException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message))); }
  }

  Future<void> _accept(SocialChallengeDto challenge) async {
    if (_session == null) return;
    try { final OnlineMatchDto match = await _api.acceptChallenge(_session!.token, challenge.id);
      if (mounted) widget.onOpenMatch?.call(match);
    } on SocialException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message))); }
  }

  Future<void> _communityAct(Future<CommunityDto> Function() action) async {
    try { final CommunityDto value=await action(); if(mounted)setState(()=>_community=value); }
    on SocialException catch(error){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.message)));}
  }

  void _openPlayerProfile(SocialPlayerDto player) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _SocialPlayerProfile(
            player: player,
            onChallenge: () => _challenge(player),
          ),
        ),
      );

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF020D16),
    appBar: AppBar(title: const Text('COMMUNITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.3)),
      actions: <Widget>[IconButton(onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const NotificationCenterScreen())),tooltip:'Notifications',icon:const Icon(Icons.notifications_rounded)),if(_section==0) IconButton(onPressed: _addFriend, tooltip: 'Add friend', icon: const Icon(Icons.person_add_alt_1_rounded))],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(48),child: _CommunityTabs(selected:_section,onChanged:(value)=>setState(()=>_section=value)))),
    body: _busy ? const Center(child: CircularProgressIndicator()) : _error != null ? _Error(message: _error!, retry: _refresh) :
      _section==0 ? RefreshIndicator(onRefresh: _refresh, child: LayoutBuilder(builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= 820;
        final List<Widget> sections = <Widget>[
          _Hero(friendCount: _hub!.friends.length, challengeCount: _hub!.challenges.where((c) => c.status == 'PENDING').length),
          if (_hub!.incoming.isNotEmpty) _Section(title: 'FRIEND REQUESTS', icon: Icons.person_add_rounded,
            children: _hub!.incoming.map((player) => _PlayerCard(player: player,
              primaryLabel: 'Accept', onPrimary: () => _act(() => _api.respond(_session!.token, player.connectionId, true)),
              secondaryLabel: 'Decline', onSecondary: () => _act(() => _api.respond(_session!.token, player.connectionId, false)))).toList()),
          _Section(title: 'FRIENDS', icon: Icons.people_alt_rounded,
            empty: 'Add friends by their ChessVerseAI username.',
            children: _hub!.friends.map((player) => _PlayerCard(player: player, primaryLabel: 'Challenge', onTap:()=>_openPlayerProfile(player),onPrimary: () => _challenge(player))).toList()),
          _Section(title: 'CHALLENGES', icon: Icons.sports_martial_arts_rounded,
            empty: 'Your private challenges will appear here.',
            children: _hub!.challenges.where((c) => c.status == 'PENDING').map((challenge) => _ChallengeCard(challenge: challenge,
              onAccept: challenge.incoming ? () => _accept(challenge) : null,
              onDecline: challenge.incoming ? () => _act(() => _api.declineChallenge(_session!.token, challenge.id)) : null)).toList()),
        ];
        return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 40), children: <Widget>[
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: wide
            ? Wrap(spacing: 16, runSpacing: 16, children: sections.map((w) => SizedBox(width: w is _Hero ? 1180 : 570, child: w)).toList())
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections.expand((w) => <Widget>[w, const SizedBox(height: 14)]).toList())))
        ]);
      })) : _CommunitySection(section:_section,community:_community!,friends:_hub!.friends,onRefresh:_refresh,onClub:(club)=>_communityAct(()=>_communityApi.club(_session!.token,club.id,!club.joined)),onTournament:(event)=>_communityAct(()=>_communityApi.tournament(_session!.token,event.id,!event.joined)),api:_communityApi,token:_session!.token),
  );
}

class _CommunityTabs extends StatelessWidget {const _CommunityTabs({required this.selected,required this.onChanged});final int selected;final ValueChanged<int> onChanged;
 @override Widget build(BuildContext context)=>SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),child:Row(children:List<Widget>.generate(4,(i){const labels=<String>['Friends','Clubs','Tournaments','Chat'];const icons=<IconData>[Icons.people_alt_rounded,Icons.shield_rounded,Icons.emoji_events_rounded,Icons.forum_rounded];return Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:ChoiceChip(showCheckmark:false,avatar:Icon(icons[i],size:17),label:Text(labels[i]),selected:selected==i,onSelected:(_)=>onChanged(i)));})));
}

class _CommunitySection extends StatelessWidget {const _CommunitySection({required this.section,required this.community,required this.friends,required this.onRefresh,required this.onClub,required this.onTournament,required this.api,required this.token});final int section;final CommunityDto community;final List<SocialPlayerDto> friends;final Future<void> Function() onRefresh;final ValueChanged<ClubDto> onClub;final ValueChanged<TournamentDto> onTournament;final CommunityApi api;final String token;
 @override Widget build(BuildContext context){final List<Widget> cards=switch(section){1=>community.clubs.map((c)=>_ClubCard(club:c,onTap:()=>onClub(c))).toList(),2=>community.tournaments.map((t)=>_TournamentCard(event:t,onTap:()=>onTournament(t))).toList(),_=>friends.map((f)=>_ChatCard(friend:f,onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>_ChatScreen(friend:f,api:api,token:token))))).toList()};final String title=switch(section){1=>'CLUBS',2=>'TOURNAMENTS',_=>'CHAT & CHALLENGE'};return RefreshIndicator(onRefresh:onRefresh,child:ListView(padding:const EdgeInsets.fromLTRB(16,18,16,40),children:<Widget>[Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1100),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:<Widget>[_FairPlayBanner(score:community.fairPlayScore),const SizedBox(height:16),Text(title,style:const TextStyle(color:Color(0xFFE5B550),fontWeight:FontWeight.w900,letterSpacing:1.2)),const SizedBox(height:10),if(cards.isEmpty)const _EmptyCommunity() else LayoutBuilder(builder:(context,c)=>c.maxWidth>760?Wrap(spacing:14,runSpacing:14,children:cards.map((w)=>SizedBox(width:(c.maxWidth-14)/2,child:w)).toList()):Column(children:cards))])))]));}}

class _FairPlayBanner extends StatelessWidget {const _FairPlayBanner({required this.score});final int score;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:<Color>[Color(0xFF073C42),Color(0xFF0A1B2B)]),border:Border.all(color:const Color(0xFF43D8C3))),child:Row(children:<Widget>[const Icon(Icons.verified_user_rounded,color:Color(0xFF5DE3CF),size:34),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:<Widget>[Text('FAIR PLAY PROTECTED',style:TextStyle(fontWeight:FontWeight.w900)),Text('Server-validated moves • authoritative clocks • auditable signals',style:TextStyle(color:Color(0xFF9EB1BE),fontSize:12))])),Text('$score',style:const TextStyle(color:Color(0xFF5DE3CF),fontSize:26,fontWeight:FontWeight.w900))]));}
class _ClubCard extends StatelessWidget {const _ClubCard({required this.club,required this.onTap});final ClubDto club;final VoidCallback onTap;@override Widget build(BuildContext context){final (IconData,Color) identity=switch(club.name){'Royal Knights'=>(Icons.workspace_premium_rounded,const Color(0xFFE6B64E)),'Checkmate Academy'=>(Icons.school_rounded,const Color(0xFF8FA9C0)),'Blitz Warriors'=>(Icons.bolt_rounded,const Color(0xFFE29A42)),_=>(Icons.shield_rounded,const Color(0xFF55DCC8))};return _FeatureCard(icon:identity.$1,color:identity.$2,title:club.name,subtitle:club.description,meta:'${club.members} members • ${club.ratingRequirement}+ rating',button:club.joined?'Leave':'Join club',onTap:onTap);}}
class _TournamentCard extends StatelessWidget {const _TournamentCard({required this.event,required this.onTap});final TournamentDto event;final VoidCallback onTap;@override Widget build(BuildContext context)=>_FeatureCard(icon:Icons.emoji_events_rounded,color:const Color(0xFF54DFC9),title:event.name,subtitle:event.description,meta:'${event.minutes} min • ${event.players}/${event.capacity} players',button:event.joined?'Withdraw':'Join tournament',onTap:onTap);}
class _FeatureCard extends StatelessWidget {const _FeatureCard({required this.icon,required this.color,required this.title,required this.subtitle,required this.meta,required this.button,required this.onTap});final IconData icon;final Color color;final String title,subtitle,meta,button;final VoidCallback onTap;@override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xEE0A1C2B),borderRadius:BorderRadius.circular(22),border:Border.all(color:color.withValues(alpha:.55))),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:<Widget>[Row(children:<Widget>[CircleAvatar(backgroundColor:color.withValues(alpha:.13),child:Icon(icon,color:color)),const SizedBox(width:12),Expanded(child:Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)))]),const SizedBox(height:9),Text(subtitle,style:const TextStyle(color:Color(0xFFA7B7C2))),const SizedBox(height:9),Text(meta,style:TextStyle(color:color,fontWeight:FontWeight.w700)),const SizedBox(height:13),OutlinedButton(onPressed:onTap,child:Text(button))]));}
class _ChatCard extends StatelessWidget {const _ChatCard({required this.friend,required this.onTap});final SocialPlayerDto friend;final VoidCallback onTap;@override Widget build(BuildContext context)=>ListTile(onTap:onTap,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:const BorderSide(color:Color(0xFF2A485C))),tileColor:const Color(0xEE0A1C2B),leading:CircleAvatar(child:Text(friend.displayName.substring(0,1).toUpperCase())),title:Text(friend.displayName,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(friend.online?'Online • Tap to chat':'Offline • Messages sync securely'),trailing:const Icon(Icons.chevron_right_rounded));}
class _EmptyCommunity extends StatelessWidget {const _EmptyCommunity();@override Widget build(BuildContext context)=>const Padding(padding:EdgeInsets.all(34),child:Column(children:<Widget>[Icon(Icons.forum_outlined,size:46,color:Color(0xFF527080)),SizedBox(height:10),Text('Nothing here yet. Add a friend to start your chess network.',textAlign:TextAlign.center)]));}

class _ChatScreen extends StatefulWidget {const _ChatScreen({required this.friend,required this.api,required this.token});final SocialPlayerDto friend;final CommunityApi api;final String token;@override State<_ChatScreen> createState()=>_ChatScreenState();}
class _ChatScreenState extends State<_ChatScreen>{final TextEditingController _text=TextEditingController();List<MessageDto> _messages=<MessageDto>[];bool _busy=true;Timer? _pollTimer;@override void initState(){super.initState();_load();_pollTimer=Timer.periodic(const Duration(seconds:5),(_)=>_load(silent:true));}@override void dispose(){_pollTimer?.cancel();_text.dispose();super.dispose();}Future<void> _load({bool silent=false})async{try{final v=await widget.api.messages(widget.token,widget.friend.playerId);if(mounted)setState((){_messages=v;_busy=false;});}on SocialException catch(e){if(mounted){setState(()=>_busy=false);if(!silent)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}}}Future<void> _send()async{final body=_text.text.trim();if(body.isEmpty)return;_text.clear();try{final m=await widget.api.send(widget.token,widget.friend.playerId,body);if(mounted)setState(()=>_messages=<MessageDto>[..._messages,m]);}on SocialException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.friend.displayName)),body:Column(children:<Widget>[Expanded(child:_busy?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:_messages.map((m)=>Align(alignment:m.mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),constraints:const BoxConstraints(maxWidth:420),decoration:BoxDecoration(color:m.mine?const Color(0xFF0B5C58):const Color(0xFF142A3B),borderRadius:BorderRadius.circular(16)),child:Text(m.body)))).toList())),SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(12),child:Row(children:<Widget>[Expanded(child:TextField(controller:_text,maxLength:500,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:const InputDecoration(counterText:'',hintText:'Message your friend…'))),const SizedBox(width:8),IconButton.filled(onPressed:_send,icon:const Icon(Icons.send_rounded))])))]));}

class _Hero extends StatelessWidget { const _Hero({required this.friendCount, required this.challengeCount}); final int friendCount, challengeCount;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFF3ED7C0)),
    gradient: const LinearGradient(colors: <Color>[Color(0xFF073C42), Color(0xFF071A2A)])),
    child: Row(children: <Widget>[const CircleAvatar(radius: 32, backgroundColor: Color(0xFF0C5D59), child: Icon(Icons.groups_rounded, size: 35, color: Color(0xFF61E5D0))),
      const SizedBox(width: 18), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text('YOUR CHESS NETWORK', style: TextStyle(color: Color(0xFFE3B653), fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        SizedBox(height: 5), Text('Friends, private challenges and live rivals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))])),
      _Metric('$friendCount', 'FRIENDS'), const SizedBox(width: 18), _Metric('$challengeCount', 'OPEN')]),
  ); }
class _Metric extends StatelessWidget { const _Metric(this.value, this.label); final String value,label; @override Widget build(BuildContext context) => Column(children: <Widget>[
  Text(value, style: const TextStyle(color: Color(0xFF5FE3CE), fontSize: 25, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF93A7B4))) ]); }
class _Section extends StatelessWidget { const _Section({required this.title, required this.icon, required this.children, this.empty}); final String title; final IconData icon; final List<Widget> children; final String? empty;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xE60A1B2B), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF29475B))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
    Row(children: <Widget>[Icon(icon, color: const Color(0xFFE2AE49)), const SizedBox(width: 9), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1))]), const SizedBox(height: 12),
    if (children.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 22), child: Text(empty ?? 'Nothing here yet.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF91A4B0)))) else ...children])); }
class _PlayerCard extends StatelessWidget { const _PlayerCard({required this.player, required this.primaryLabel, required this.onPrimary, this.onTap,this.secondaryLabel, this.onSecondary}); final SocialPlayerDto player; final String primaryLabel; final VoidCallback onPrimary;final VoidCallback? onTap; final String? secondaryLabel; final VoidCallback? onSecondary;
  @override Widget build(BuildContext context) => InkWell(onTap:onTap,borderRadius:BorderRadius.circular(16),child:Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFF0C2638), borderRadius: BorderRadius.circular(16)), child: Row(children: <Widget>[
    Stack(children: <Widget>[CircleAvatar(backgroundImage: player.photoUrl == null ? null : NetworkImage(player.photoUrl!), child: player.photoUrl == null ? Text(player.displayName.substring(0,1).toUpperCase()) : null), Positioned(right: 0,bottom: 0,child: CircleAvatar(radius: 5,backgroundColor: player.online ? const Color(0xFF45E6A8) : const Color(0xFF607684)))]),
    const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(player.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), Text('@${player.username} • ${player.rating}', style: const TextStyle(color: Color(0xFF92A6B4), fontSize: 11))])),
    if (secondaryLabel != null) TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)), FilledButton(onPressed: onPrimary, child: Text(primaryLabel))]))); }

class _SocialPlayerProfile extends StatelessWidget{const _SocialPlayerProfile({required this.player,required this.onChallenge});final SocialPlayerDto player;final VoidCallback onChallenge;@override Widget build(BuildContext context){final int rate=player.gamesPlayed==0?0:(player.wins*100/player.gamesPlayed).round();return Scaffold(backgroundColor:const Color(0xFF020D16),appBar:AppBar(title:const Text('PLAYER PROFILE')),body:ListView(padding:const EdgeInsets.all(18),children:<Widget>[Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),gradient:const LinearGradient(colors:<Color>[Color(0xFF0A3C48),Color(0xFF091B2C)]),border:Border.all(color:const Color(0xFFE0AD45))),child:Column(children:<Widget>[CircleAvatar(radius:48,backgroundImage:player.photoUrl==null?null:NetworkImage(player.photoUrl!),child:player.photoUrl==null?Text(player.displayName.substring(0,1).toUpperCase(),style:const TextStyle(fontSize:34,fontWeight:FontWeight.w900)):null),const SizedBox(height:12),Text(player.displayName,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),Text('@${player.username} • ${player.country}',style:const TextStyle(color:Color(0xFF9DB0BC))),const SizedBox(height:14),Chip(label:Text(player.online?'ONLINE':'OFFLINE')),const SizedBox(height:14),FilledButton.icon(onPressed:(){Navigator.pop(context);onChallenge();},icon:const Icon(Icons.sports_martial_arts_rounded),label:const Text('CHALLENGE'))])),const SizedBox(height:16),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.8,mainAxisSpacing:10,crossAxisSpacing:10,children:<Widget>[_SocialMetric('${player.rating}','RATING'),_SocialMetric('${player.peakRating}','PEAK'),_SocialMetric('${player.gamesPlayed}','RATED GAMES'),_SocialMetric('$rate%','WIN RATE'),_SocialMetric('${player.wins}','WINS'),_SocialMetric('${player.draws}','DRAWS')]) ]));}}
class _SocialMetric extends StatelessWidget{const _SocialMetric(this.value,this.label);final String value,label;@override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:const Color(0xFF0A1C2B),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFF28485B))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:<Widget>[Text(value,style:const TextStyle(color:Color(0xFF5FE3CE),fontSize:22,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(color:Color(0xFF91A6B3),fontSize:10))]));}
class _ChallengeCard extends StatelessWidget { const _ChallengeCard({required this.challenge, this.onAccept, this.onDecline}); final SocialChallengeDto challenge; final VoidCallback? onAccept; final VoidCallback? onDecline;
  @override Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: const CircleAvatar(backgroundColor: Color(0xFF3B2C12), child: Icon(Icons.bolt_rounded, color: Color(0xFFFFC857))), title: Text(challenge.opponentName, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${challenge.minutes} min • Room ${challenge.roomCode}'), trailing: onAccept == null ? const Chip(label: Text('SENT')) : Row(mainAxisSize: MainAxisSize.min, children: <Widget>[IconButton(onPressed: onDecline, tooltip: 'Decline', icon: const Icon(Icons.close_rounded)), FilledButton(onPressed: onAccept, child: const Text('Play'))])); }
class _Error extends StatelessWidget { const _Error({required this.message, required this.retry}); final String message; final VoidCallback retry; @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[const Icon(Icons.cloud_off_rounded,size: 48), const SizedBox(height: 12), Text(message), const SizedBox(height: 12), FilledButton(onPressed: retry, child: const Text('Retry'))])); }
