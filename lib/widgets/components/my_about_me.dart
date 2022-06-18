import 'package:flutter/material.dart';
import 'package:phub/widgets/components/my_drawer.dart';
import 'package:phub/widgets/components/my_version.dart';

class MyAboutMe extends StatelessWidget {
  const MyAboutMe({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("关于"),
          centerTitle: false,
        ),
        body: SafeArea(
            child: Column(
          children: [
            //  beauty
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              width: MediaQuery.of(context).size.width * 2 / 3,
              child: const MyBeauty(),
            ),
            const Divider(),
            // version
            const MyVersionInfo(),
            const Divider(),
            const MyProjectInfo(),
            const Divider(),
          ],
        )));
  }
}
