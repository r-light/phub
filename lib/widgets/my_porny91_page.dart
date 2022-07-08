import 'dart:math';
import 'package:flutter/material.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/videos/my_porny91.dart';
import 'package:phub/widgets/components/my_gesture_detector.dart';
import 'package:phub/widgets/components/my_keep_alive.dart';
import 'package:phub/widgets/components/my_setting_action.dart';
import 'package:phub/widgets/components/my_status.dart';
import 'package:phub/widgets/components/my_video_card.dart';
import 'package:provider/provider.dart';

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
                  "client": PornyClient(),
                  "source": MySources.porny91,
                  "sourceName": MySources.sourceName[MySources.porny91],
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
          ? Global.showSnackBar("当前域名为: ${PornyClient().currentDomain}",
              const Duration(seconds: 1))
          : Global.showSnackBar("网络有可能存在问题");
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
        Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "已加载${videos.length}/$totalNum项",
                // style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 1,
              ),
            ]),
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
            client: PornyClient(),
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
            client: PornyClient(),
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
