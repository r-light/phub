import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phub/common/global.dart';
import 'package:provider/provider.dart';

class VideoSimpleItem extends StatelessWidget {
  const VideoSimpleItem({
    Key? key,
    required this.thumb,
    required this.title,
    this.author,
    required this.source,
    this.updateTime,
    required this.isList,
    this.pageView,
    this.tags,
  }) : super(key: key);

  static final Color lightColor = Colors.grey.shade700;
  final String thumb;
  final String title;
  final String? author;
  final String source;
  final String? updateTime;
  final bool isList;
  final String? pageView;
  final List<String>? tags;
  static const double fontSize = 12;

  Widget listItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 6,
          child: Container(
            alignment: Alignment.center,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
              ),
            ),
          ),
        ),
        Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: fontSize,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    author ?? "",
                    style: TextStyle(fontSize: fontSize, color: lightColor),
                    maxLines: 1,
                  ),
                  Text(
                    pageView ?? "",
                    style: TextStyle(fontSize: fontSize, color: lightColor),
                    maxLines: 1,
                  ),
                  (tags != null && tags!.isNotEmpty)
                      ? Text(
                          tags?.join(" ") ?? "",
                          style:
                              TextStyle(fontSize: fontSize, color: lightColor),
                          maxLines: 1,
                        )
                      : Container(),
                ],
              ),
            )),
        Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  source,
                  style: TextStyle(
                    color: lightColor,
                    fontSize: fontSize,
                  ),
                ),
                Text(
                  updateTime ?? "",
                  style: TextStyle(
                    color: lightColor,
                    fontSize: fontSize,
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget gridItem(BuildContext context) {
    return GridTile(
      footer: context.select((Configs config) => config.showFooterInGridView)
          ? Container(
              color: Colors.white70,
              child: Column(children: [
                Text(
                  title,
                  style:
                      const TextStyle(color: Colors.black, fontSize: fontSize),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  // overflow: TextOverflow.ellipsis,
                ),
                author != null
                    ? Text(
                        author!,
                        style: TextStyle(
                            color: Colors.grey[800], fontSize: fontSize),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      )
                    : Container(),
                (updateTime != null && pageView != null)
                    ? Text(
                        "$updateTime | $pageView",
                        style: TextStyle(
                            color: Colors.grey[800], fontSize: fontSize),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      )
                    : Container(),
                (tags != null && tags!.isNotEmpty)
                    ? Text(
                        tags!.join(" "),
                        style: TextStyle(
                            fontSize: fontSize, color: Colors.grey[800]),
                        maxLines: 1,
                      )
                    : Container(),
              ]),
            )
          : Container(),
      child: CachedNetworkImage(
        imageUrl: thumb,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isList ? listItem() : gridItem(context);
  }
}
