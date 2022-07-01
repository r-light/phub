import 'package:flutter/material.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/widgets/components/my_drawer.dart';
import 'package:phub/widgets/components/my_gesture_detector.dart';
import 'package:phub/widgets/components/my_video_card.dart';
import 'package:phub/widgets/my_porny91.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class MyVideoPage extends StatelessWidget {
  const MyVideoPage({Key? key}) : super(key: key);
  static const tabs = ["历史", "收藏"];

  @override
  Widget build(BuildContext context) {
    // tabs of this page
    return DefaultTabController(
      initialIndex: 1,
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            Global.appTitle,
          ),
          centerTitle: false,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          bottom: TabBar(
            isScrollable: false,
            tabs: tabs.map<Widget>((e) => Tab(text: e)).toList(),
          ),
        ),
        drawer: const MyDrawer(),
        body: TabBarView(
          children: tabs
              .asMap()
              .map((idx, name) =>
                  MapEntry(idx, MyVideoLayout(tabIndex: idx, name: name)))
              .values
              .toList(),
        ),
      ),
    );
  }
}

class MyVideoLayout extends StatefulWidget {
  const MyVideoLayout({Key? key, required this.tabIndex, required this.name})
      : super(key: key);
  final int tabIndex;
  final String name;

  @override
  State<MyVideoLayout> createState() => MyVideoLayoutState();
}

class MyVideoLayoutState extends State<MyVideoLayout>
    with AutomaticKeepAliveClientMixin {
  // final double padding = 5;
  // final int crossAxisCount = 3;
  // final double titleFontSize = 12;
  // final double sourceFontSize = 12;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    switch (widget.tabIndex) {
      case 0:
        {
          return getGridView(Provider.of<VideoLocal>(context, listen: true)
              .history
              .values
              .toList(growable: false)
              .reversed
              .toList(growable: false));
        }
      case 1:
        {
          return getGridView(Provider.of<VideoLocal>(context, listen: true)
              .favorite
              .values
              .toList(growable: false)
              .reversed
              .toList(growable: false));
        }
      default:
        {
          return Container();
        }
    }
  }

  Widget getGridView(List<VideoSimple> records) {
    return ReorderableGridView.builder(
      onReorder: (oldIndex, newIndex) {
        oldIndex = records.length - 1 - oldIndex;
        newIndex = records.length - 1 - newIndex;
        Provider.of<VideoLocal>(context, listen: false)
            .insertFavoriteIndex(oldIndex, newIndex);
      },
      padding: const EdgeInsets.all(5.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 5.0,
        mainAxisSpacing: 5.0,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        VideoSimple record = records[index];
        return MyGridGestureDetector(
          key: ValueKey(Global.videoSimpleKey(record)),
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
            source: record.sourceName ?? "unknown",
            isList: false,
            pageView: record.pageView,
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
