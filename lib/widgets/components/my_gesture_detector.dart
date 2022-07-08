import 'package:flutter/material.dart';
import 'package:phub/common/dto.dart';
import 'package:phub/common/global.dart';
import 'package:phub/videos/my_video_interface.dart';
import 'package:provider/provider.dart';

class MyGridGestureDetector extends StatelessWidget {
  const MyGridGestureDetector(
      {Key? key,
      required this.child,
      required this.record,
      required this.client,
      this.controller})
      : super(key: key);

  final Widget? child;
  final VideoSimple record;
  final MyVideo client;
  final dynamic controller;

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
          "client": client,
          "record": record,
        });
      },
      child: child,
    );
  }
}
