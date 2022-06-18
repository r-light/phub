import 'dart:math';
import 'package:flutter/material.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/widgets/components/my_gesture_detector.dart';
import 'package:phub/widgets/components/my_status.dart';
import 'package:phub/widgets/components/my_video_card.dart';
import 'package:provider/provider.dart';

/* 
"keywords": _searchContext,
"searchFunc": widget.content["searchFunc"],
"index": _pornyOp?.index ?? 0 
*/

class MySearchResult extends StatefulWidget {
  const MySearchResult({Key? key, this.content}) : super(key: key);
  final dynamic content;

  @override
  State<MySearchResult> createState() => _MySearchResultState();
}

class _MySearchResultState extends State<MySearchResult> {
  bool isLoading = true;
  bool hasMore = true;
  int maxPage = 1;
  int currentPage = 1;
  int totalNum = 0;
  List<VideoSimple> videos = [];

  void changeView(BuildContext context) {
    Provider.of<Configs>(context, listen: false).listViewInSearchResult =
        !Provider.of<Configs>(context, listen: false).listViewInSearchResult;
  }

  @override
  void initState() {
    super.initState();
    loadCurrentPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          centerTitle: false,
          title: Text(widget.content["keywords"] ?? ""),
          actions: [
            context.select((Configs configs) => configs.listViewInSearchResult)
                ? IconButton(
                    onPressed: () => changeView(context),
                    icon: const Icon(Icons.grid_view),
                  )
                : IconButton(
                    onPressed: () => changeView(context),
                    icon: const Icon(Icons.list),
                  )
          ],
        ),
        body: Column(children: [
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
          Expanded(child: getVideoCard(context)),
        ]));
  }

  void loadCurrentPage() async {
    isLoading = true;
    widget.content["searchFunc"](widget.content["keywords"],
            index: widget.content["index"]!, page: currentPage)
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
    if (context.select((Configs configs) => configs.listViewInSearchResult)) {
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
            videoFunc: widget.content["videoFunc"],
            relatedFunc: widget.content["relatedFunc"],
            authorFunc: widget.content["authorFunc"],
            searchFunc: widget.content["searchFunc"],
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
        separatorBuilder: (context, index) => const Divider(
          thickness: 2,
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
            videoFunc: widget.content["videoFunc"],
            relatedFunc: widget.content["relatedFunc"],
            authorFunc: widget.content["authorFunc"],
            searchFunc: widget.content["searchFunc"],
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
