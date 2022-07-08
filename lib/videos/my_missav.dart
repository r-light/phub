import 'dart:math';

import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/videos/my_video_interface.dart';

class MissAVClient implements MyVideo {
  static MissAVClient? _instance;

  MissAVClient._internal() {
    _instance = this;
  }

  factory MissAVClient() => _instance ?? MissAVClient._internal();

  final permanentDomain = "https://missav.com/cn";
  late String currentDomain = permanentDomain;

  @override
  Future parseFromDomainSite() async {
    // content is <status code, content>
    var content = await MyDio().getHtml(currentDomain);
    if (content.key == 200) {
      return true;
    }
    return false;
  }

  @override
  Future<List<MapEntry<String, String>>> parseFromCurrentDomain() async {
    var resp = await MyDio().dio.get(currentDomain);
    var content = resp.data.toString();
    var doc = parse(content);
    List<MapEntry<String, String>> tabsUrl = [];
    // parse tabs and urls from domain
    var tabs = doc.querySelectorAll("div.relative>div>div>nav>div.relative");
    if (tabs.isNotEmpty) {
      var tab = tabs[0];
      var children = tab.querySelectorAll("div>div>div>a");
      for (var child in children) {
        if (child.attributes["href"]?.contains("search") == true ||
            child.attributes["href"]?.contains("genres") == true ||
            child.attributes["href"]?.contains("makers") == true) {
          continue;
        }
        tabsUrl.add(MapEntry(child.text, child.attributes["href"] ?? ""));
      }
    }
    return tabsUrl;
  }

  @override
  Future<MapEntry<int, List<VideoSimple>>> parseFromDomainTab(
      String tab, String path,
      {int index = 1}) async {
    var resp = await MyDio().dio.fetch(RequestOptions(
        method: "GET",
        baseUrl: currentDomain,
        path: path,
        queryParameters: {"page": index}));
    var content = resp.data.toString();
    var doc = parse(content);
    int maxPage = 1;
    // parse videos
    List<VideoSimple> videos = parseVideoHelper(doc);
    // parse maxPage
    doc
        .querySelectorAll("span.relative.z-0.inline-flex.shadow-sm>a")
        .forEach((element) {
      maxPage = max(maxPage, int.tryParse(element.text.trim()) ?? 1);
    });
    return MapEntry(maxPage, videos);
  }

  List<VideoSimple> parseVideoHelper(var doc) {
    List<VideoSimple> videos = [];
    // parse videos
    doc.querySelectorAll("div.grid.grid-cols-2.gap-5>div").forEach((element) {
      var title = Global.trimAllLF(element.querySelectorAll("a").last.text);

      var videoUrl =
          element.querySelectorAll("a").last.attributes["href"] ?? "";
      RegExp reg = RegExp(r"cn/([\s\S]*)");
      var match = reg.firstMatch(videoUrl);
      var id = videoUrl;
      if (match != null) {
        id = match.group(1)!;
      }

      var thumb = element.querySelector("img")?.attributes["data-src"] ?? "";
      var author = "";
      var view = "";
      var time = "";

      List<String> tags = [];
      var a = element.querySelectorAll("a");
      for (int i = 1; i < a.length - 1; i++) {
        tags.add(a[i].text.trim());
      }
      var video = VideoSimple(id, title, videoUrl, thumb, author, time, view);
      video.source = MySources.missav;
      video.sourceName = MySources.sourceName[MySources.missav];
      video.tags = tags;
      videos.add(video);
    });
    return videos;
  }

  @override
  Future<MapEntry<int, List<VideoSimple>>> parseFromAuthor(String author,
      {int index = 1}) async {
    var resp = await MyDio().dio.fetch(RequestOptions(
        method: "GET",
        baseUrl: currentDomain,
        path: author,
        queryParameters: {"page": index}));
    var content = resp.data.toString();
    var doc = parse(content);
    int maxPage = 1;
    // parse videos
    List<VideoSimple> videos = parseVideoHelper(doc);
    // parse maxPage
    doc
        .querySelectorAll("span.relative.z-0.inline-flex.shadow-sm>a")
        .forEach((element) {
      maxPage = max(maxPage, int.tryParse(element.text.trim()) ?? 1);
    });
    return MapEntry(maxPage, videos);
  }

  @override
  Future<MapEntry<int, List<VideoSimple>>> parseFromSearch(String keywords,
      {int index = 0, int page = 1}) async {
    var url = "$currentDomain/search/$keywords";
    Map<String, dynamic> params = {};
    params["page"] = page;

    var resp = await MyDio().dio.fetch(RequestOptions(
        method: "GET",
        baseUrl: currentDomain,
        path: url,
        queryParameters: params));
    var content = resp.data.toString();
    var doc = parse(content);
    int maxPage = 1;
    // parse videos
    List<VideoSimple> videos = parseVideoHelper(doc);
    // parse maxPage
    doc
        .querySelectorAll("span.relative.z-0.inline-flex.shadow-sm>a")
        .forEach((element) {
      maxPage = max(maxPage, int.tryParse(element.text.trim()) ?? 1);
    });
    return MapEntry(maxPage, videos);
  }

  String m3u8(String p, int a, int c, List<String> k) {
    var d = {};
    while (c-- > 0) {
      if (k.length > c) {
        d[c.toRadixString(a)] = k[c];
      } else {
        d[c.toRadixString(a)] = c.toRadixString(a);
      }
    }
    String url = "";
    for (var i = 0; i < p.length; i++) {
      var char = p[i];
      url += d[char] ?? char;
    }
    var reg = RegExp(r"http[\s\S]*");
    url = reg.firstMatch(url)?[0] ?? "";
    if (url.endsWith("'")) url = url.substring(0, url.length - 1);
    return url;
  }

  @override
  Future<Map<String, dynamic>> parseFromVideoUrl(String url) async {
    var map = <String, dynamic>{};
    var resp = await MyDio().dio.get(url);
    var content = resp.data.toString();
    var reg = RegExp(r'}\(([\s\S]*)\)\)');
    var match = reg.firstMatch(content);
    var res = "";
    if (match != null) {
      var args = match.group(1)!.split(",");
      var ss = args[3].split(".")[0];
      var arg3 = ss.substring(1, ss.length - 1).split("|");
      res = m3u8(
          args[0].substring(1, args[0].length - 1).replaceAll("\\'", "'"),
          int.tryParse(args[1]) ?? 0,
          int.tryParse(args[2]) ?? 0,
          arg3);
    }
    map["videoUrl"] = res;
    var doc = parse(content);
    map["related"] = parseVideoHelper(doc);
    doc.querySelectorAll(".space-y-2>div.text-secondary").forEach((element) {
      if (element.text.contains("番号")) {
        map.putIfAbsent("id", () => element.children.last.text);
      }
      if (element.text.contains("女优")) {
        List<String> authors = [];
        List<String> authorsUrl = [];
        element.querySelectorAll("a").forEach((element) {
          authors.add(element.text);
          authorsUrl.add(element.attributes["href"] ?? "");
        });
        map.putIfAbsent("author", () => authors);
        map.putIfAbsent("authorUrl", () => authorsUrl);
      }
    });
    return map;
  }

  Future<List<Map<String, dynamic>>> parseActress(String path,
      {int index = 1, Map<String, String>? params}) async {
    List<Map<String, dynamic>> res = [];
    if (path.endsWith("actresses")) {
      var queryParameters = <String, dynamic>{"page": index};
      if (params != null && params.isNotEmpty) {
        queryParameters.addAll(params);
      }
      var resp = await MyDio().dio.fetch(RequestOptions(
          method: "GET",
          baseUrl: currentDomain,
          path: path,
          queryParameters: queryParameters));
      var content = resp.data.toString();
      var doc = parse(content);
      int maxPage = 1;
      doc
          .querySelectorAll("span.relative.z-0.inline-flex.shadow-sm>a")
          .forEach((element) {
        maxPage = max(maxPage, int.tryParse(element.text.trim()) ?? 1);
      });
      doc
          .querySelectorAll(
              "div.max-w-full.p-8.text-nord4.bg-nord1.rounded-lg>ul>li")
          .forEach((li) {
        var name = li.querySelectorAll("h4").last.text.trim();
        var image = li.querySelector("img")?.attributes["data-src"] ??
            li.querySelector("img")?.attributes["src"] ??
            "";
        var url = li.querySelector("a")?.attributes["href"] ?? "";
        var count = li.querySelectorAll("p").last.text.split(" ").first;
        res.add({
          "name": name,
          "image": image,
          "url": url,
          "count": count,
          "maxPage": maxPage
        });
      });
    } else {
      var resp = await MyDio().dio.fetch(RequestOptions(
            method: "GET",
            baseUrl: currentDomain,
            path: path,
          ));
      var content = resp.data.toString();
      var doc = parse(content);
      doc
          .querySelectorAll(
              "div.max-w-full.p-8.text-nord4.bg-nord1.rounded-lg>ul>li")
          .forEach((li) {
        var name = li.querySelectorAll("h4").last.text.trim();
        var image = li.querySelector("img")?.attributes["data-src"] ??
            li.querySelector("img")?.attributes["src"] ??
            "";
        var url = li.querySelector("a")?.attributes["href"] ?? "";
        res.add({"name": name, "image": image, "url": url});
      });
    }
    return res;
  }
}
