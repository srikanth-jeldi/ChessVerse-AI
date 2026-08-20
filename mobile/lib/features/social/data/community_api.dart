import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'social_api.dart';

class ClubDto {
  const ClubDto({required this.id,required this.name,required this.description,required this.members,required this.ratingRequirement,required this.joined});
  final String id,name,description; final int members,ratingRequirement; final bool joined;
  factory ClubDto.fromJson(Map<String,dynamic> j)=>ClubDto(id:j['id'] as String? ?? '',name:j['name'] as String? ?? 'Club',description:j['description'] as String? ?? '',members:(j['members'] as num?)?.toInt()??0,ratingRequirement:(j['ratingRequirement'] as num?)?.toInt()??0,joined:j['joined'] as bool? ?? false);
}
class TournamentDto {
  const TournamentDto({required this.id,required this.name,required this.description,required this.minutes,required this.players,required this.capacity,required this.status,required this.joined});
  final String id,name,description,status; final int minutes,players,capacity; final bool joined;
  factory TournamentDto.fromJson(Map<String,dynamic> j)=>TournamentDto(id:j['id'] as String? ?? '',name:j['name'] as String? ?? 'Tournament',description:j['description'] as String? ?? '',minutes:(j['timeControlMinutes'] as num?)?.toInt()??10,players:(j['players'] as num?)?.toInt()??0,capacity:(j['capacity'] as num?)?.toInt()??0,status:j['status'] as String? ?? 'OPEN',joined:j['joined'] as bool? ?? false);
}
class ConversationDto {
  const ConversationDto({required this.playerId,required this.displayName,this.photoUrl,required this.online,required this.lastMessage,required this.unread});
  final String playerId,displayName,lastMessage; final String? photoUrl; final bool online; final int unread;
  factory ConversationDto.fromJson(Map<String,dynamic> j)=>ConversationDto(playerId:j['playerId'] as String? ?? '',displayName:j['displayName'] as String? ?? 'Player',photoUrl:j['photoUrl'] as String?,online:j['online'] as bool? ?? false,lastMessage:j['lastMessage'] as String? ?? '',unread:(j['unread'] as num?)?.toInt()??0);
}
class MessageDto {
  const MessageDto({required this.id,required this.senderId,required this.recipientId,required this.body,required this.mine});
  final String id,senderId,recipientId,body; final bool mine;
  factory MessageDto.fromJson(Map<String,dynamic> j)=>MessageDto(id:j['id'] as String? ?? '',senderId:j['senderId'] as String? ?? '',recipientId:j['recipientId'] as String? ?? '',body:j['body'] as String? ?? '',mine:j['mine'] as bool? ?? false);
}
class CommunityDto {
  const CommunityDto({required this.clubs,required this.tournaments,required this.conversations,required this.fairPlayScore});
  final List<ClubDto> clubs; final List<TournamentDto> tournaments; final List<ConversationDto> conversations; final int fairPlayScore;
  factory CommunityDto.fromJson(Map<String,dynamic> j){List<T> items<T>(String k,T Function(Map<String,dynamic>) f)=>(j[k] as List<dynamic>? ?? const <dynamic>[]).whereType<Map<String,dynamic>>().map(f).toList();return CommunityDto(clubs:items('clubs',ClubDto.fromJson),tournaments:items('tournaments',TournamentDto.fromJson),conversations:items('conversations',ConversationDto.fromJson),fairPlayScore:(j['fairPlayScore'] as num?)?.toInt()??100);}
}
class CommunityApi {
  const CommunityApi();
  Future<CommunityDto> load(String token) async=>CommunityDto.fromJson(await _request(token,'GET','/api/v1/community'));
  Future<CommunityDto> club(String token,String id,bool join) async=>CommunityDto.fromJson(await _request(token,'PUT','/api/v1/community/clubs/$id?join=$join'));
  Future<CommunityDto> tournament(String token,String id,bool join) async=>CommunityDto.fromJson(await _request(token,'PUT','/api/v1/community/tournaments/$id?join=$join'));
  Future<List<MessageDto>> messages(String token,String friendId) async=>(await _requestList(token,'GET','/api/v1/community/messages/$friendId')).whereType<Map<String,dynamic>>().map(MessageDto.fromJson).toList();
  Future<MessageDto> send(String token,String recipientId,String body) async=>MessageDto.fromJson(await _request(token,'POST','/api/v1/community/messages',body:<String,Object?>{'recipientId':recipientId,'body':body}));
  Future<Map<String,dynamic>> _request(String token,String method,String path,{Map<String,Object?>? body}) async {final Object value=await _raw(token,method,path,body);if(value is Map<String,dynamic>)return value;return <String,dynamic>{};}
  Future<List<dynamic>> _requestList(String token,String method,String path) async {final Object value=await _raw(token,method,path,null);return value is List<dynamic>?value:<dynamic>[];}
  Future<Object> _raw(String token,String method,String path,Map<String,Object?>? body) async {try{final uri=Uri.parse('${AppConfig.apiBaseUrl}$path');final headers=<String,String>{'Authorization':'Bearer $token','Content-Type':'application/json'};final response=method=='POST'?await http.post(uri,headers:headers,body:jsonEncode(body)).timeout(const Duration(seconds:15)):method=='PUT'?await http.put(uri,headers:headers).timeout(const Duration(seconds:15)):await http.get(uri,headers:headers).timeout(const Duration(seconds:15));final Object decoded=response.body.isEmpty?<String,dynamic>{}:jsonDecode(response.body);if(response.statusCode<200||response.statusCode>=300){final e=decoded is Map<String,dynamic>?decoded:<String,dynamic>{};throw SocialException(e['message'] as String? ?? 'Community request failed.');}return decoded;}on SocialException{rethrow;}on TimeoutException{throw const SocialException('Community request timed out.');}catch(_){throw const SocialException('Cannot reach ChessVerseAI community services.');}}
}
