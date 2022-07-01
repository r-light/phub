import 'dart:math';
import 'package:html/parser.dart';
import 'package:flutter/material.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/widgets/components/my_gesture_detector.dart';
import 'package:phub/widgets/components/my_keep_alive.dart';
import 'package:phub/widgets/components/my_setting_action.dart';
import 'package:phub/widgets/components/my_status.dart';
import 'package:phub/widgets/components/my_video_card.dart';
import 'package:phub/widgets/components/my_video_interface.dart';
import 'package:provider/provider.dart';

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
    content = await MyDio().getHtml(domainSites);
    var doc = parse(content.value);
    var url = doc.querySelectorAll("script").last.attributes["src"] ?? "";
    if (url.isEmpty) return;

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
        content = await MyDio().getHtml(realUrl);
        if (content.key == 200) {
          currentDomain = realUrl;
          return true;
        }
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

  Future<String> parseVideo(String url) async {
    var resp = await MyDio().dio.get(url);
    var content = resp.data.toString();
    var doc = parse(content);
    var videoUrl = doc
            .querySelector(".videoPlayContainer")
            ?.querySelector("video")
            ?.attributes["data-src"] ??
        "";
    return videoUrl;
  }

  Future<List<VideoSimple>> parseRelated(String url) async {
    var resp = await MyDio().dio.get(url);
    var content = resp.data.toString();
    var doc = parse(content);
    List<VideoSimple> videos = parseVideoHelper(doc);
    return videos;
  }

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
}

class MyPorny91 extends StatefulWidget {
  const MyPorny91({Key? key, this.content}) : super(key: key);
  final dynamic content;

  @override
  State<MyPorny91> createState() => _MyPorny91State();
}

class _MyPorny91State extends State<MyPorny91> {
  Future<List<MapEntry<String, String>>>? tabsUrlFuture;
  List<String> tabs = [];

  Widget videoPage(BuildContext context, Widget body) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          centerTitle: false,
          title: const Text(MySources.porny91),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.search,
              ),
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(MySources.searchPage, arguments: {
                  "base": PornyClient().currentDomain,
                  "searchFunc": PornyClient().parseFromSearch,
                  "sourceName": MySources.sourceName[MySources.porny91],
                  "videoFunc": PornyClient().parseVideo,
                  "relatedFunc": PornyClient().parseRelated,
                  "authorFunc": PornyClient().parseFromAuthor,
                });
              },
            ),
            context.select((Configs configs) => configs.listViewInPorny91)
                ? IconButton(
                    onPressed: () => changeView(context),
                    icon: const Icon(Icons.grid_view),
                  )
                : IconButton(
                    onPressed: () => changeView(context),
                    icon: const Icon(Icons.list),
                  ),
            ...alwaysInActions(),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs.map<Widget>((name) => Tab(text: name)).toList(),
          ),
        ),
        body: body,
      ),
    );
  }

  void changeView(BuildContext context) {
    Provider.of<Configs>(context, listen: false).listViewInPorny91 =
        !Provider.of<Configs>(context, listen: false).listViewInPorny91;
  }

  @override
  void initState() {
    super.initState();
    PornyClient().parseFromDomainSite().then((value) {
      value
          ? Global.showSnackBar(
              context,
              "当前域名为: ${PornyClient().currentDomain}",
              const Duration(seconds: 1))
          : Global.showSnackBar(context, "网络有可能存在问题");
      tabsUrlFuture = PornyClient().parseFromCurrentDomain();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tabsUrlFuture == null) {
      return videoPage(context, const MyWaiting());
    } else {
      return FutureBuilder<List<MapEntry<String, String>>>(
        future: tabsUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return videoPage(
                context,
                const Center(
                  child: Text("失败了呜呜呜..."),
                ));
          }
          if (!snapshot.hasData) {
            return videoPage(context, const MyWaiting());
          }
          var tabsUrl = snapshot.requireData;
          if (tabs.isEmpty) {
            for (var e in tabsUrl) {
              tabs.add(e.key);
            }
          }
          return KeepAliveWrapper(
              child: videoPage(
                  context,
                  TabBarView(
                      children: tabs
                          .asMap()
                          .map((index, key) {
                            return MapEntry(
                              index,
                              My91PornyLayout(index, key, tabsUrl[index].value),
                            );
                          })
                          .values
                          .toList())));
        },
      );
    }
  }
}

class My91PornyLayout extends StatefulWidget {
  final int index;
  final String tab;
  final String path;

  const My91PornyLayout(
    this.index,
    this.tab,
    this.path, {
    Key? key,
  }) : super(key: key);

  @override
  State<My91PornyLayout> createState() => _My91PornyLayoutState();
}

class _My91PornyLayoutState extends State<My91PornyLayout> {
  bool isLoading = true;
  bool hasMore = true;
  int maxPage = 1;
  int currentPage = 1;
  int totalNum = 0;
  List<VideoSimple> videos = [];

  @override
  void initState() {
    super.initState();
    isLoading = true;
    hasMore = true;
    loadCurrentPage();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration:
              BoxDecoration(color: Theme.of(context).colorScheme.primary),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "已加载${videos.length}/$totalNum项",
                  // style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1,
                ),
              ]),
        ),
        Expanded(
          child: getVideoCard(context),
        ),
      ],
    );
  }

  void loadCurrentPage() async {
    isLoading = true;
    PornyClient()
        .parseFromDomainTab(widget.tab, widget.path, index: currentPage)
        .then((entry) {
      setState(() {
        maxPage = max(entry.key, maxPage);
        videos.addAll(entry.value);
        totalNum = max(totalNum, entry.value.length * maxPage);
        currentPage++;
        isLoading = false;
        if (currentPage > maxPage) {
          hasMore = false;
          totalNum = videos.length;
        }
      });
    });
  }

  Widget getVideoCard(BuildContext context) {
    if (videos.isEmpty) {
      return const MyWaiting();
    }
    if (context.select((Configs configs) => configs.listViewInPorny91)) {
      var height =
          context.select((Configs configs) => configs.listViewItemHeight);
      return ListView.separated(
        padding: const EdgeInsets.all(5.0),
        itemBuilder: (context, index) {
          if (index >= videos.length) {
            if (!isLoading) {
              loadCurrentPage();
            }
            return const MyWaiting();
          }
          var record = videos[index];
          return MyGridGestureDetector(
            record: record,
            videoFunc: PornyClient().parseVideo,
            relatedFunc: PornyClient().parseRelated,
            authorFunc: PornyClient().parseFromAuthor,
            searchFunc: PornyClient().parseFromSearch,
            child: SizedBox(
                height: height,
                child: VideoSimpleItem(
                  thumb: record.thumb,
                  title: record.title,
                  author: record.author,
                  updateTime: record.updateDate,
                  source: record.sourceName!,
                  isList: true,
                  pageView: record.pageView,
                )),
          );
        },
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey.shade100,
          thickness: 4,
        ),
        itemCount: hasMore ? videos.length + 1 : videos.length,
      );
    } else {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 5.0,
          childAspectRatio: 1.0,
        ),
        padding: const EdgeInsets.all(5.0),
        itemCount: hasMore ? videos.length + 1 : videos.length,
        itemBuilder: (context, index) {
          if (index >= videos.length) {
            if (!isLoading) {
              loadCurrentPage();
            }
            return const MyWaiting();
          }
          VideoSimple record = videos[index];
          return MyGridGestureDetector(
            record: record,
            videoFunc: PornyClient().parseVideo,
            relatedFunc: PornyClient().parseRelated,
            authorFunc: PornyClient().parseFromAuthor,
            searchFunc: PornyClient().parseFromSearch,
            child: VideoSimpleItem(
              thumb: record.thumb,
              title: record.title,
              author: record.author,
              updateTime: record.updateDate,
              source: record.sourceName!,
              isList: false,
              pageView: record.pageView,
            ),
          );
        },
      );
    }
  }
}
