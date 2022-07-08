import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/videos/my_missav.dart';
import 'package:phub/widgets/components/my_gesture_detector.dart';
import 'package:phub/widgets/components/my_keep_alive.dart';
import 'package:phub/widgets/components/my_setting_action.dart';
import 'package:phub/widgets/components/my_status.dart';
import 'package:phub/widgets/components/my_video_card.dart';
import 'package:provider/provider.dart';

class MyMissAv extends StatefulWidget {
  const MyMissAv({Key? key, this.content}) : super(key: key);
  final dynamic content;

  @override
  State<MyMissAv> createState() => _MyMissAvState();
}

class _MyMissAvState extends State<MyMissAv> {
  Future<List<MapEntry<String, String>>>? tabsUrlFuture;
  List<String> tabs = [];

  @override
  void initState() {
    super.initState();
    MissAVClient().parseFromDomainSite().then((value) {
      value
          ? Global.showSnackBar("当前域名为: ${MissAVClient().currentDomain}",
              const Duration(seconds: 1))
          : Global.showSnackBar("网络有可能存在问题");
      tabsUrlFuture = MissAVClient().parseFromCurrentDomain();
      setState(() {});
    });
  }

  Widget videoPage(BuildContext context, Widget body) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          centerTitle: false,
          title: const Text(MySources.missav),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.search,
              ),
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(MySources.searchPage, arguments: {
                  "client": MissAVClient(),
                  "source": MySources.missav,
                  "sourceName": MySources.sourceName[MySources.missav],
                });
              },
            ),
            context.select((Configs configs) => configs.listViewInMissAv)
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
    Provider.of<Configs>(context, listen: false).listViewInMissAv =
        !Provider.of<Configs>(context, listen: false).listViewInMissAv;
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
                              MyMissAvLayout(index, key, tabsUrl[index].value),
                            );
                          })
                          .values
                          .toList())));
        },
      );
    }
  }
}

class MyMissAvLayout extends StatefulWidget {
  final int index;
  final String tab;
  final String path;

  const MyMissAvLayout(
    this.index,
    this.tab,
    this.path, {
    Key? key,
  }) : super(key: key);

  @override
  State<MyMissAvLayout> createState() => _MyMissAvLayoutLayoutState();
}

class _MyMissAvLayoutLayoutState extends State<MyMissAvLayout> {
  static const double fontSize = 12;
  bool isLoading = true;
  bool hasMore = true;
  int maxPage = 1;
  int currentPage = 1;
  int totalNum = 0;
  late List<VideoSimple> videos = [];
  late List<Map> actresses = [];
  late Map<String, String> queryParams = {};

  final heights = [
    "选择身高",
    "131-135",
    "136-140",
    "141-145",
    "146-150",
    "151-155",
    "156-160",
    "161-165",
    "166-170",
    "171-175",
    "176-180",
    "181-185",
    "186-190"
  ];
  final ages = [
    "选择年龄",
    "0-20",
    "20-30",
    "30-40",
    "40-50",
    "50-60",
    "60-99",
  ];
  final sizes = ["选择罩杯"] +
      List<String>.generate(
          17, (index) => String.fromCharCode('A'.codeUnitAt(0) + index));
  late String height = heights[0];
  late String size = sizes[0];
  late String age = ages[0];

  @override
  void initState() {
    super.initState();
    isLoading = true;
    hasMore = true;
    loadCurrentPage();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index < 3) {
      return Column(
        children: [
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "已加载${videos.length}/$totalNum项",
                  maxLines: 1,
                ),
              ]),
          Expanded(
            child: getVideoCard(context),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "已加载${actresses.length}/$totalNum项",
                  maxLines: 1,
                ),
              ]),
          widget.index == 3 ? selectBox() : Container(),
          Expanded(
            child: getActressCard(context),
          ),
        ],
      );
    }
  }

  Widget selectBox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        DropdownButton<String>(
            underline: const SizedBox(),
            value: height,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: heights
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              if (value == heights[0]) {
                queryParams.remove("height");
              } else {
                queryParams["height"] = value;
              }
              setState(() {
                height = value;
                reset();
                loadCurrentPage();
              });
            }),
        DropdownButton<String>(
            underline: const SizedBox(),
            value: size,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: sizes
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              if (value == sizes[0]) {
                queryParams.remove("cup");
              } else {
                queryParams["cup"] = value;
              }
              setState(() {
                size = value;
                reset();
                loadCurrentPage();
              });
            }),
        DropdownButton<String>(
            underline: const SizedBox(),
            value: age,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: ages
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              if (value == ages[0]) {
                queryParams.remove("age");
              } else {
                queryParams["age"] = value;
              }
              setState(() {
                age = value;
                reset();
                loadCurrentPage();
              });
            }),
      ],
    );
  }

  void loadCurrentPage() async {
    if (widget.index < 3) {
      isLoading = true;
      MissAVClient()
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
    } else if (widget.index == 3) {
      isLoading = true;
      var tmp = await MissAVClient()
          .parseActress(widget.path, index: currentPage, params: queryParams);
      setState(() {
        if (tmp.isNotEmpty) maxPage = max(tmp[0]["maxPage"], maxPage);
        actresses.addAll(tmp);
        totalNum = max(totalNum, tmp.length * maxPage);
        currentPage++;
        isLoading = false;
        if (currentPage > maxPage) {
          hasMore = false;
          totalNum = actresses.length;
        }
      });
    } else if (widget.index == 4) {
      isLoading = true;
      hasMore = false;
      actresses = await MissAVClient().parseActress(widget.path);
      setState(() {
        totalNum = actresses.length;
        isLoading = false;
      });
    }
  }

  Widget getVideoCard(BuildContext context) {
    if (videos.isEmpty) {
      return const MyWaiting();
    }
    if (context.select((Configs configs) => configs.listViewInMissAv)) {
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
            client: MissAVClient(),
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
                  tags: record.tags,
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
          childAspectRatio: 3 / 2,
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
            client: MissAVClient(),
            child: VideoSimpleItem(
              thumb: record.thumb,
              title: record.title,
              source: record.sourceName!,
              isList: false,
              tags: record.tags,
            ),
          );
        },
      );
    }
  }

  Widget getActressCard(BuildContext context) {
    if (actresses.isEmpty) {
      return const MyWaiting();
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        // mainAxisExtent: 150,
        crossAxisSpacing: 5.0,
        mainAxisSpacing: 5.0,
      ),
      padding: const EdgeInsets.all(5.0),
      itemCount: hasMore ? actresses.length + 1 : actresses.length,
      itemBuilder: (context, index) {
        if (index >= actresses.length) {
          if (!isLoading) {
            loadCurrentPage();
          }
          return const MyWaiting();
        }
        Map actress = actresses[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, MySources.missAvActress, arguments: {
              "url": actress["url"]!,
              "name": actress["name"],
            });
          },
          child: GridTile(
            footer: Container(
              color: Colors.white54,
              child: Column(children: [
                Text(
                  actress["name"]!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  // overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            child: CachedNetworkImage(
              imageUrl: actress["image"]!,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              errorWidget: (BuildContext context, String url, dynamic error) {
                return CachedNetworkImage(imageUrl: MyDio().beautyUrl);
              },
            ),
          ),
        );
      },
    );
  }

  void reset() {
    actresses.clear();
    hasMore = true;
    maxPage = 1;
    currentPage = 1;
    totalNum = 0;
  }
}

class MyMissAvActress extends StatefulWidget {
  const MyMissAvActress({Key? key, this.content}) : super(key: key);
  final dynamic content;

  @override
  State<StatefulWidget> createState() => MyMissAvActressState();
}

class MyMissAvActressState extends State<MyMissAvActress> {
  late String name = widget.content["name"]!;
  late String url = widget.content["url"]!;

  bool isLoading = true;
  bool hasMore = true;
  int maxPage = 1;
  int currentPage = 1;
  int totalNum = 0;
  late List<VideoSimple> videos = [];

  @override
  void initState() {
    super.initState();
    isLoading = true;
    hasMore = true;
    loadCurrentPage();
  }

  void loadCurrentPage() async {
    isLoading = true;
    MissAVClient().parseFromAuthor(url, index: currentPage).then((entry) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0.0,
          centerTitle: false,
          title: Text(name),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.search,
              ),
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(MySources.searchPage, arguments: {
                  "client": MissAVClient(),
                  "source": MySources.missav,
                  "sourceName": MySources.sourceName[MySources.missav],
                });
              },
            ),
            context.select((Configs configs) => configs.listViewInMissAv)
                ? IconButton(
                    onPressed: () => changeView(context),
                    icon: const Icon(Icons.grid_view),
                  )
                : IconButton(
                    onPressed: () => changeView(context),
                    icon: const Icon(Icons.list),
                  ),
            ...alwaysInActions(),
          ]),
      body: Column(
        children: [
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "已加载${videos.length}/$totalNum项",
                  maxLines: 1,
                ),
              ]),
          Expanded(
            child: getVideoCard(context),
          ),
        ],
      ),
    );
  }

  void changeView(BuildContext context) {
    Provider.of<Configs>(context, listen: false).listViewInMissAv =
        !Provider.of<Configs>(context, listen: false).listViewInMissAv;
  }

  Widget getVideoCard(BuildContext context) {
    if (videos.isEmpty) {
      return const MyWaiting();
    }
    if (context.select((Configs configs) => configs.listViewInMissAv)) {
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
            client: MissAVClient(),
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
                  tags: record.tags,
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
          childAspectRatio: 3 / 2,
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
            client: MissAVClient(),
            child: VideoSimpleItem(
              thumb: record.thumb,
              title: record.title,
              source: record.sourceName!,
              isList: false,
              tags: record.tags,
            ),
          );
        },
      );
    }
  }
}
