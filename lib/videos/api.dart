import 'package:phub/common/global.dart';
import 'package:phub/videos/my_missav.dart';
import 'package:phub/videos/my_porny91.dart';
import 'package:phub/videos/my_video_interface.dart';

final Map<String, MyVideo> videoMethod = {
  MySources.porny91: PornyClient(),
  MySources.missav: MissAVClient(),
};
