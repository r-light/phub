import 'dart:math';

import 'package:html/parser.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/videos/my_video_interface.dart';

class PornyClient implements MyVideo {
  static PornyClient? _instance;

  PornyClient._internal() {
    _instance = this;
  }

  factory PornyClient() => _instance ?? PornyClient._internal();
  final permanentDomain = "https://91porny.com";
  String currentDomain = "https://91porny.com";
  String domainSites = "https://dizhi91.github.io";

  @override
  Future parseFromDomainSite() async {
    var content = await MyDio().getHtml(currentDomain);
    if (content.key == 200) {
      return true;
    }

    // content is <status code, content>
    content = await MyDio().getHtml(permanentDomain);
    if (content.key == 200) {
      currentDomain = permanentDomain;
      return true;
    }

    // parse from domainSites
    var urls = await parseCandidateDomain();
    for (var domain in urls) {
      content = await MyDio().getHtml(domain);
      if (content.key == 200) {
        currentDomain = domain;
        return true;
      }
    }

    return false;
  }

  @override
  Future<List<MapEntry<String, String>>> parseFromCurrentDomain() async {
    var resp = await MyDio().dio.get("${PornyClient().currentDomain}/video");
    var content = resp.data.toString();
    var doc = parse(content);
    List<MapEntry<String, String>> tabsUrl = [];
    // parse tabs and urls from domain
    doc
        .querySelector("#videoListPage")
        ?.querySelector("ul")
        ?.querySelectorAll("li")
        .forEach((element) {
      String key = element.text.toString().trim();
      String? value = element.attributes["data-href"];
      if (value != null) tabsUrl.add(MapEntry(key, value));
    });
    return tabsUrl;
  }

  @override
  Future<MapEntry<int, List<VideoSimple>>> parseFromDomainTab(
      String tab, String path,
      {int index = 1}) async {
    var resp = await MyDio().dio.get("$currentDomain$path/$index");
    var content = resp.data.toString();
    var doc = parse(content);
    int maxPage = 1;
    // parse videos
    List<VideoSimple> videos = parseVideoHelper(doc);
    // parse maxPage
    doc
        .querySelector(".pagination")
        ?.querySelectorAll(".page-item>a")
        .forEach((e) {
      maxPage = max(int.tryParse(e.text.trim()) ?? 1, maxPage);
    });
    return MapEntry(maxPage, videos);
  }

  List<VideoSimple> parseVideoHelper(var doc) {
    List<VideoSimple> videos = [];
    // parse videos
    doc.querySelectorAll(".colVideoList").forEach((element) {
      var title = element.querySelectorAll(".video-elem>a").last.text.trim();
      var videoUrl = currentDomain +
          (element.querySelectorAll(".video-elem>a").last.attributes["href"] ??
              "");
      var id = videoUrl.split("/").last;
      var thumb =
          element.querySelector(".video-elem>a>.img")?.attributes["style"] ??
              "";
      RegExp reg = RegExp(r"http.*?'");
      var match = reg.firstMatch(thumb);
      if (match != null) {
        thumb = match[0]!.substring(0, match[0]!.length - 1);
      } else {
        RegExp reg = RegExp(r"url\('([\s\S]*)'\)");
        match = reg.firstMatch(thumb);
        if (match != null) {
          var tmp = match.group(1)!;
          if (!tmp.startsWith("http")) {
            tmp = "https:$tmp";
          }
          thumb = tmp;
        }
      }
      var author = element
              .querySelector(".video-elem>small")
              ?.querySelector("a")
              ?.text ??
          "";
      var timeView = element
              .querySelector(".video-elem>small")
              ?.querySelectorAll("div")
              .last
              .text ??
          "";
      var splits = timeView.split("|");
      var time = "", view = "";
      if (splits.length > 1) {
        time = splits.first.trim();
        view = splits.last.trim();
      }
      var video = VideoSimple(id, title, videoUrl, thumb, author, time, view);
      video.source = MySources.porny91;
      video.sourceName = MySources.sourceName[MySources.porny91];
      videos.add(video);
    });
    return videos;
  }

  @override
  Future<MapEntry<int, List<VideoSimple>>> parseFromAuthor(String author,
      {int index = 1}) async {
    var resp = await MyDio().dio.get("$currentDomain/author/$author");
    var content = resp.data.toString();
    var doc = parse(content);
    int maxPage = 1;
    // parse videos
    List<VideoSimple> videos = parseVideoHelper(doc);
    // parse maxPage
    doc
        .querySelector(".pagination")
        ?.querySelectorAll(".page-item>a")
        .forEach((e) {
      maxPage = max(int.tryParse(e.text.trim()) ?? 1, maxPage);
    });
    return MapEntry(maxPage, videos);
  }

  @override
  Future<MapEntry<int, List<VideoSimple>>> parseFromSearch(String keywords,
      {int index = 0, int page = 1}) async {
    var url = "$currentDomain/search";
    Map<String, String> params = {};
    params["keywords"] = keywords;
    params["page"] = page.toString();
    switch (index) {
      case 1:
        {
          params["view"] = "desc";
          break;
        }
      case 2:
        {
          params["author"] = "true";
          break;
        }
    }
    var resp = await MyDio().dio.get(url, queryParameters: params);
    var content = resp.data.toString();
    var doc = parse(content);
    int maxPage = 1;
    // parse videos
    List<VideoSimple> videos = parseVideoHelper(doc);
    // parse maxPage
    doc
        .querySelector(".pagination")
        ?.querySelectorAll(".page-item>a")
        .forEach((e) {
      maxPage = max(int.tryParse(e.text.trim()) ?? 1, maxPage);
    });
    return MapEntry(maxPage, videos);
  }

  Future<List<String>> parseCandidateDomain() async {
    var content = await MyDio().getHtml(domainSites);
    var doc = parse(content.value);
    var url = doc.querySelectorAll("script").last.attributes["src"] ?? "";
    List<String> res = [permanentDomain];
    if (url.isEmpty) return res;

    content = await MyDio().getHtml(url);
    final RegExp reg = RegExp(r'newestUrls\s*=\s*\[([\s\S]*?)\]\s*;');
    final match = reg.firstMatch(content.value);
    if (match != null) {
      List<String> urls = match.group(1)!.split(",");
      urls = urls.map((e) => e.trim()).toList();
      for (var domain in urls) {
        var realUrl = domain.substring(1, domain.length - 1);
        if (realUrl.endsWith("/")) {
          realUrl = realUrl.substring(0, realUrl.length - 1);
        }
        res.add(realUrl);
      }
    }
    return res;
  }

  @override
  Future<Map<String, dynamic>> parseFromVideoUrl(String url) async {
    var map = <String, dynamic>{};
    var resp = await MyDio().dio.get(url);
    var content = resp.data.toString();
    var doc = parse(content);
    var videoUrl = doc
            .querySelector(".videoPlayContainer")
            ?.querySelector("video")
            ?.attributes["data-src"] ??
        "";
    map["videoUrl"] = videoUrl;
    map["related"] = parseVideoHelper(doc);
    return map;
  }
}
