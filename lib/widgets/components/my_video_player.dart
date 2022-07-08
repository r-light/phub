import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/videos/my_video_interface.dart';
import 'package:phub/widgets/components/my_gesture_detector.dart';
import 'package:phub/widgets/components/my_status.dart';
import 'package:phub/widgets/components/my_video_card.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

/* 
 "client": client,
 "record": record,
 */
class MyVideoPlayer extends StatefulWidget {
  final dynamic content;

  const MyVideoPlayer({Key? key, required this.content}) : super(key: key);

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late Future<Map<String, dynamic>> videoInfo;
  late List<VideoSimple> videos;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _controller;
  Chewie? playerWidget;
  bool focus = false;
  int circuit = 0;
  late MyVideo client = widget.content["client"];

  @override
  void initState() {
    super.initState();
    videoInfo = client.parseFromVideoUrl(widget.content["record"].videoUrl);
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content["record"].title),
        elevation: 0.0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Provider.of<VideoLocal>(context, listen: true)
                    .isFavorite(widget.content["record"])
                ? const Icon(
                    Icons.favorite,
                    color: Colors.pink,
                  )
                : const Icon(
                    Icons.favorite_border,
                    color: Colors.black,
                  ),
            onPressed: () {
              Provider.of<VideoLocal>(context, listen: false)
                      .isFavorite(widget.content["record"])
                  ? Provider.of<VideoLocal>(context, listen: false)
                      .removeFavorite(widget.content["record"])
                  : Provider.of<VideoLocal>(context, listen: false)
                      .saveFavorite(widget.content["record"]);
            },
          ),
          IconButton(
            onPressed: () {
              setState(() {
                focus = !focus;
              });
            },
            icon: focus
                ? const Icon(
                    Icons.close_fullscreen,
                  )
                : const Icon(
                    Icons.open_in_full,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(
            height: 5,
          ),
          Expanded(child: getVideoWidget()),
          getVideoInfoWidget(context),
          focus ? Container() : const Divider(),
          focus ? Container() : Expanded(flex: 2, child: getRelatedWidget())
        ]),
      ),
    );
  }

  Widget getVideoInfoWidget(BuildContext context) {
    if (widget.content["record"].source == MySources.missav) {
      return FutureBuilder<Map<String, dynamic>>(
          future: videoInfo,
          builder: (context, snapshot) {
            List<String> authors = snapshot.hasData
                ? (snapshot.requireData["author"] ??
                    [snapshot.requireData["id"]])
                : [widget.content["record"].author];
            return Column(
              children: [
                ListTile(
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        widget.content["record"].title,
                        maxLines: 3,
                      ),
                    ),
                    subtitle: Wrap(
                      children: [
                        const Icon(Icons.person),
                        ...authors
                            .asMap()
                            .map((index, e) {
                              return MapEntry(
                                  index,
                                  GestureDetector(
                                    child: Text("$e "),
                                    onTap: () {
                                      if (!snapshot.hasData) return;
                                      var urls =
                                          snapshot.requireData["authorUrl"];
                                      if (urls == null || urls.isEmpty) {
                                        return;
                                      }
                                      _controller?.pause();
                                      Navigator.of(context).pushNamed(
                                          MySources.missAvActress,
                                          arguments: {
                                            "url": urls[index],
                                            "name": e,
                                          });
                                    },
                                  ));
                            })
                            .values
                            .toList(),
                      ],
                    ))
              ],
            );
          });
    } else {
      return Column(
        children: [
          getCircuit(context),
          ListTile(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(widget.content["record"].title),
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      Text(widget.content["record"].author)
                    ],
                  ),
                  onTap: () {
                    _controller?.pause();
                    Navigator.of(context)
                        .pushNamed(MySources.searchResult, arguments: {
                      "client": widget.content["client"],
                      "source": widget.content["source"],
                      "keywords": widget.content["record"].author,
                      "index": Porny91Options.author.index,
                    });
                  },
                ),
                Text(widget.content["record"].pageView +
                    " | " +
                    widget.content["record"].updateDate),
              ],
            ),
          )
        ],
      );
    }
  }

  Widget getVideoWidget() {
    return FutureBuilder<Map<String, dynamic>>(
        future: videoInfo,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("失败了呜呜呜..."),
            );
          }
          if (!snapshot.hasData) {
            return const MyWaiting();
          }
          var m3u8 = snapshot.requireData["videoUrl"] as String;
          VideoSimple record = widget.content["record"];
          if (_videoPlayerController == null) {
            if (record.source == MySources.missav) {
              _videoPlayerController = VideoPlayerController.network(m3u8,
                  httpHeaders: {"referer": "https://missav.com/"});
            } else {
              _videoPlayerController = VideoPlayerController.network(m3u8);
            }
            _videoPlayerController!.initialize().whenComplete(() {
              setState(() {
                _controller = ChewieController(
                    materialProgressColors:
                        ChewieProgressColors(backgroundColor: Colors.white),
                    videoPlayerController: _videoPlayerController!,
                    autoInitialize: true,
                    allowedScreenSleep: false,
                    optionsTranslation: OptionsTranslation(
                      playbackSpeedButtonText: '倍速',
                      subtitlesButtonText: '字幕',
                      cancelButtonText: '取消',
                    ),
                    deviceOrientationsAfterFullScreen: [
                      DeviceOrientation.portraitUp
                    ],
                    errorBuilder: (context, meg) {
                      return const Center(
                        child: Text("失败了呜呜呜...\n可能需要会员"),
                      );
                    });
                playerWidget = Chewie(
                  controller: _controller!,
                );
              });
            });
          }
          return playerWidget != null
              ? GestureDetector(
                  child: playerWidget,
                  onLongPress: () =>
                      _videoPlayerController?.setPlaybackSpeed(1.5),
                  onLongPressUp: () =>
                      _videoPlayerController?.setPlaybackSpeed(1.0),
                )
              : const MyWaiting();
        });
  }

  Widget getRelatedWidget() {
    return FutureBuilder<Map<String, dynamic>>(
        future: videoInfo,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("失败了呜呜呜..."),
            );
          }
          if (!snapshot.hasData) {
            return const MyWaiting();
          }
          List<VideoSimple> records = snapshot.requireData["related"];
          var childAspectRatio =
              (records.isNotEmpty && records.first.source == MySources.missav)
                  ? 3 / 2
                  : 1.0;
          return GridView.builder(
            padding: const EdgeInsets.all(5.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 5.0,
            ),
            itemCount: records.length,
            itemBuilder: (context, index) {
              VideoSimple record = records[index];
              return MyGridGestureDetector(
                record: record,
                client: widget.content["client"],
                controller: _controller,
                child: VideoSimpleItem(
                  thumb: record.thumb,
                  title: record.title,
                  author:
                      record.source == MySources.missav ? null : record.author,
                  updateTime: record.source == MySources.missav
                      ? null
                      : record.updateDate,
                  source: record.sourceName ?? "unknown",
                  isList: false,
                  pageView: record.source == MySources.missav
                      ? null
                      : record.pageView,
                  tags: record.tags,
                ),
              );
            },
          );
        }));
  }

  Widget getCircuit(BuildContext context) {
    if (widget.content["record"].source != MySources.porny91) {
      return Container();
    }
    return Wrap(
      spacing: 2.0,
      children: <Widget>[
        OutlinedButton(
          onPressed: () {
            if (circuit == 0) return;
            setState(() {
              circuit = 0;
              _videoPlayerController?.dispose();
              _controller?.dispose();
              _videoPlayerController = null;
              _controller = null;
              videoInfo =
                  client.parseFromVideoUrl(widget.content["record"].videoUrl);
            });
          },
          style: circuit == 0
              ? OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                )
              : null,
          child: const Text('默认'),
        ),
        OutlinedButton(
            onPressed: () {
              if (circuit == 1) return;
              setState(() {
                circuit = 1;
                _videoPlayerController?.dispose();
                _controller?.dispose();
                _videoPlayerController = null;
                _controller = null;
                videoInfo = client.parseFromVideoUrl(
                    widget.content["record"].videoUrl + "?server=line1");
              });
            },
            style: circuit == 1
                ? OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  )
                : null,
            child: const Text('线路1')),
        OutlinedButton(
            onPressed: () {
              if (circuit == 2) return;
              setState(() {
                circuit = 2;
                _videoPlayerController?.dispose();
                _controller?.dispose();
                _videoPlayerController = null;
                _controller = null;
                videoInfo = client.parseFromVideoUrl(
                    widget.content["record"].videoUrl + "?server=line2");
              });
            },
            style: circuit == 2
                ? OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  )
                : null,
            child: const Text('线路2')),
        OutlinedButton(
            onPressed: () {
              if (circuit == 3) return;
              setState(() {
                circuit = 3;
                _videoPlayerController?.dispose();
                _controller?.dispose();
                _videoPlayerController = null;
                _controller = null;
                videoInfo = client.parseFromVideoUrl(
                    widget.content["record"].videoUrl + "?server=line3");
              });
            },
            style: circuit == 3
                ? OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  )
                : null,
            child: const Text('线路3')),
      ],
    );
  }
}
