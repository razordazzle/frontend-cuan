import 'package:youtube_player_flutter/youtube_player_flutter.dart';

String? extractYoutubeId(String url) {
  return YoutubePlayer.convertUrlToId(url);
}