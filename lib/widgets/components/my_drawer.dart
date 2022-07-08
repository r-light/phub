import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phub/common/global.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({
    Key? key,
  }) : super(key: key);

  static const topPadding = 38.0;
  static const leftPadding = 10.0;

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: MediaQuery.removePadding(
            context: context,
            child: SafeArea(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const MyBeauty(),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      ...getVideoSource(context),
                      ListTile(
                        leading: const Icon(
                          Icons.settings,
                        ),
                        title: const Text("设置"),
                        onTap: () =>
                            Navigator.pushNamed(context, MySources.settings),
                      ),
                      ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                          ),
                          title: const Text("关于"),
                          onTap: () =>
                              Navigator.pushNamed(context, MySources.aboutMe)),
                    ],
                  ),
                ),
              ],
            ))));
  }

  List<Widget> getVideoSource(BuildContext context) {
    return MySources.sourceName.values
        .map(
          (String name) => ListTile(
            leading: const Icon(
              Icons.eighteen_up_rating,
            ),
            title: Text(name),
            onTap: () => Navigator.pushNamed(context, name),
          ),
        )
        .toList();
  }
}

class MyBeauty extends StatefulWidget {
  const MyBeauty({
    Key? key,
  }) : super(key: key);

  @override
  State<MyBeauty> createState() => _MyBeautyState();
}

class _MyBeautyState extends State<MyBeauty> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () => setState(() {
            MyDio().increaseIdx();
          }),
          child: CachedNetworkImage(
            imageUrl: MyDio().beautyUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: constraints.maxWidth,
          ),
        );
      },
    );
  }
}
