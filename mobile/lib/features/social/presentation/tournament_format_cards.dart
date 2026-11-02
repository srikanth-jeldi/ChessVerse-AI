import 'package:flutter/material.dart';
import '../../../core/app_ui_localizations.dart';
import '../../../core/theme/app_colors.dart';

/// The two proposed eight-seat formats are opt-in design previews until
/// their competition rules are available on the server.
class TournamentFormatCards extends StatelessWidget {
  const TournamentFormatCards({
    super.key,
    required this.onPractice,
    this.previewFormats = const bool.fromEnvironment('TOURNAMENT_FORMAT_PREVIEW'),
  });
  final VoidCallback onPractice;
  final bool previewFormats;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final paired = box.maxWidth >= 680;
    final cards = [
      _FormatCard(title: uiText(context,'Daily Practice Cup'), icon: Icons.emoji_events,
        accent: AppColors.accentGold, seats: 6, rule: '1:00', ruleIcon: Icons.hourglass_bottom,
        stages: '5', artwork:'hyderabad-royal-cup', action: onPractice),
      if (previewFormats) ...[
        const _FormatCard(title:'Daily Knockout', icon: Icons.account_tree_rounded,
          accent: AppColors.accentGold, seats:8, rule:'5 + 0', ruleIcon: Icons.timer_outlined,
          stages:'8 → 4 → 2',artwork:'dubai-gold-open'),
        const _FormatCard(title:'Weekend Arena', icon: Icons.bolt_rounded,
          accent:Color(0xff62ddca), seats:8, rule:'3 + 0', ruleIcon: Icons.timer_outlined,
          stages:'20′ → 20′ → 2',artwork:'tokyo-neon-masters'),
      ],
    ];
    return Wrap(spacing:12,runSpacing:12,children:[
      for (var i=0;i<cards.length;i++)
        SizedBox(width:paired && i>0 ? (box.maxWidth-12)/2 : box.maxWidth,child:cards[i]),
    ]);
  });
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({required this.title,required this.icon,required this.accent,
    required this.seats,required this.rule,required this.ruleIcon,required this.stages,required this.artwork,this.action});
  final String title,rule,stages,artwork;
  final int seats;
  final IconData icon,ruleIcon;
  final Color accent;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    final shape=RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),
        side:BorderSide(color:accent.withValues(alpha:.65)));
    return Material(color:AppColors.surface,shape:shape,clipBehavior:Clip.antiAlias,child:InkWell(
      onTap:action,child:Ink(
        decoration:BoxDecoration(image:DecorationImage(image:AssetImage('assets/backgrounds/tournament-$artwork-v1.webp'),
          fit:BoxFit.cover,alignment:Alignment.centerRight,opacity:.22),
          gradient:const LinearGradient(colors:[Color(0xff173747),Color(0xff091729)],
          begin:AlignmentDirectional.topStart,end:AlignmentDirectional.bottomEnd)),
        padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            DecoratedBox(decoration:BoxDecoration(color:accent.withValues(alpha:.12),
              borderRadius:BorderRadius.circular(13)),child:Padding(padding:const EdgeInsets.all(10),child:Icon(icon,color:accent))),
            const SizedBox(width:12),
            Expanded(child:Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(
              color:AppColors.textPrimary,fontWeight:FontWeight.w800))),
            if(action!=null) Icon(Icons.arrow_forward,color:accent),
          ]),
          const SizedBox(height:15),
          Wrap(spacing:8,runSpacing:8,children:[
            _Metric(Icons.people_outline,'$seats',accent),
            _Metric(ruleIcon,rule,accent),
            _Metric(Icons.account_tree_outlined,stages,accent),
          ]),
        ]),
      ),
    ));
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon,this.value,this.color);
  final IconData icon;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context)=>DecoratedBox(decoration:BoxDecoration(
    color:const Color(0xff091826),borderRadius:BorderRadius.circular(12)),
    child:Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),child:Row(
      mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:16,color:color),const SizedBox(width:6),
        Text(value,textDirection:TextDirection.ltr,style:const TextStyle(color:AppColors.textPrimary))])));
}
