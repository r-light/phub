import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:provider/provider.dart';

class MyGridGestureDetector extends StatelessWidget {
  const MyGridGestureDetector(
      {Key? key,
      required this.child,
      required this.record,
      required this.relatedFunc,
      required this.videoFunc,
      required this.authorFunc,
      required this.searchFunc,
      this.controller})
      : super(key: key);

  final Widget? child;
  final VideoSimple record;
  final dynamic relatedFunc;
  final dynamic videoFunc;
  final dynamic authorFunc;
  final dynamic searchFunc;
  final ChewieController? controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller?.pause();
        Provider.of<VideoLocal>(context, listen: false)
            .saveHistory(record)
            .whenComplete(() => Provider.of<VideoLocal>(context, listen: false)
                .removeHistory());
        Navigator.pushNamed(context, MySources.videoPlayer, arguments: {
          "relatedFunc": relatedFunc,
          "videoFunc": videoFunc,
          "authorFunc": authorFunc,
          "record": record,
          "searchFunc": searchFunc,
        });
      },
      child: child,
    );
  }
}
