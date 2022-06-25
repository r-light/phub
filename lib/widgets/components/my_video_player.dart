import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/widgets/components/my_gesture_detector.dart';
import 'package:phub/widgets/components/my_status.dart';
import 'package:phub/widgets/components/my_video_card.dart';
import 'package:provider/provider.dart';

class MyVideoPlayer extends StatefulWidget {
  final dynamic content;

  const MyVideoPlayer({Key? key, required this.content}) : super(key: key);

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late Future<String> videoUrl;
  late Future<List<VideoSimple>> videos;
  late Future<bool> supported = _controller!.isPictureInPictureSupported();
  bool focus = false;
  final GlobalKey _betterPlayerKey = GlobalKey();
  var betterPlayerConfiguration = const BetterPlayerConfiguration(
    autoPlay: false,
    looping: false,
    fullScreenByDefault: false,
    allowedScreenSleep: false,
    deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
    controlsConfiguration: BetterPlayerControlsConfiguration(
        enableSubtitles: false,
        enableQualities: false,
        enableAudioTracks: false,
        enablePip: true,
        controlBarColor: Colors.transparent),
  );
  BetterPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    videoUrl = widget.content["videoFunc"](widget.content["record"].videoUrl);
    videos = widget.content["relatedFunc"](widget.content["record"].videoUrl);
  }

  @override
  void dispose() {
    _controller?.clearCache();
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
                    color: Colors.white,
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
          )
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: getVideoWidget()),
          getVideoInfoWidget(),
          focus ? Container() : const Divider(),
          focus ? Container() : Expanded(flex: 2, child: getRelatedWidget())
        ]),
      ),
    );
  }

  Widget getVideoInfoWidget() {
    return ListTile(
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
                "keywords": widget.content["record"].author,
                "searchFunc": widget.content["searchFunc"],
                "videoFunc": widget.content["videoFunc"],
                "relatedFunc": widget.content["relatedFunc"],
                "authorFunc": widget.content["authorFunc"],
                "index": Porny91Options.author.index,
              });
            },
          ),
          Text(widget.content["record"].pageView +
              " | " +
              widget.content["record"].updateDate),
        ],
      ),
    );
  }

  Widget getVideoWidget() {
    return FutureBuilder<String>(
        future: videoUrl,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("失败了呜呜呜..."),
            );
          }
          if (!snapshot.hasData) {
            return const MyWaiting();
          }
          var m3u8 = snapshot.requireData;
          _controller ??= BetterPlayerController(
            betterPlayerConfiguration,
            betterPlayerDataSource: BetterPlayerDataSource(
              BetterPlayerDataSourceType.network,
              m3u8,
              cacheConfiguration: const BetterPlayerCacheConfiguration(
                useCache: true,
                preCacheSize: 10 * 1024 * 1024,
                maxCacheSize: 10 * 1024 * 1024,
                maxCacheFileSize: 10 * 1024 * 1024,
                key: "MyBetterPlayerCacheKey",
              ),
            ),
          );
          return FutureBuilder<bool>(
              future: supported,
              builder: ((context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return const MyWaiting();
                }
                var supported = snapshot.requireData;
                if (supported) {
                  _controller!.enablePictureInPicture(_betterPlayerKey);
                }

                return GestureDetector(
                  child: BetterPlayer(
                    controller: _controller!,
                    key: _betterPlayerKey,
                  ),
                  onLongPress: () => _controller!.setSpeed(1.5),
                  onLongPressUp: () => _controller!.setSpeed(1.0),
                );
              }));
        }));
  }

  Widget getRelatedWidget() {
    return FutureBuilder<List<VideoSimple>>(
        future: videos,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("失败了呜呜呜..."),
            );
          }
          if (!snapshot.hasData) {
            return const MyWaiting();
          }
          var records = snapshot.requireData;
          return GridView.builder(
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
                record: record,
                videoFunc: widget.content["videoFunc"],
                relatedFunc: widget.content["relatedFunc"],
                authorFunc: widget.content["authorFunc"],
                searchFunc: widget.content["searchFunc"],
                controller: _controller,
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
        }));
  }
}
