import 'package:phub/common/dto.dart';

abstract class MyVideo {
  Future parseFromDomainSite();
  Future<List<MapEntry<String, String>>> parseFromCurrentDomain();
  Future<MapEntry<int, List<VideoSimple>>> parseFromDomainTab(
      String tab, String path,
      {int index = 1});
  Future<MapEntry<int, List<VideoSimple>>> parseFromSearch(String keywords,
      {int index = 0, int page = 1});
  Future<Map<String, dynamic>> parseFromVideoUrl(
    String url,
  );
  Future<MapEntry<int, List<VideoSimple>>> parseFromAuthor(String author,
      {int index = 1});
}
