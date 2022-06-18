import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

late String _version;
late String _buildNumber;

Future initVersion() async {
  // 当前版本
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  _version = packageInfo.version;
  _buildNumber = packageInfo.buildNumber;
}

class MyVersionInfo extends StatefulWidget {
  const MyVersionInfo({Key? key}) : super(key: key);

  @override
  State<MyVersionInfo> createState() => _MyVersionInfoState();
}

class _MyVersionInfoState extends State<MyVersionInfo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '软件版本 : $_version + $_buildNumber',
          ),
          // Row(
          //   children: [
          //     const Text(
          //       "检查更新 : ",
          //       style: TextStyle(
          //         height: 1.3,
          //       ),
          //     ),
          //     "dirty" == _version
          //         ? _buildDirty()
          //         : _buildNewVersion(_latestVersion),
          //     Expanded(child: Container()),
          //   ],
          // ),
          // _buildNewVersionInfo(_latestVersionInfo),
        ],
      ),
    );
  }

  // Widget _buildNewVersion(String? latestVersion) {
  //   if (latestVersion != null) {
  //     return Text.rich(
  //       TextSpan(
  //         children: [
  //           WidgetSpan(
  //             child: Badged(
  //               child: Container(
  //                 padding: const EdgeInsets.only(right: 12),
  //                 child: Text(
  //                   latestVersion,
  //                   style: const TextStyle(height: 1.3),
  //                 ),
  //               ),
  //               badge: "1",
  //             ),
  //           ),
  //           const TextSpan(text: "  "),
  //           TextSpan(
  //             text: "去下载",
  //             style: TextStyle(
  //               height: 1.3,
  //               color: Theme.of(context).colorScheme.primary,
  //             ),
  //             recognizer: TapGestureRecognizer()
  //               ..onTap = () => openUrl(_releasesUrl),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  //   return Text.rich(
  //     TextSpan(
  //       children: [
  //         const TextSpan(text: "未检测到新版本", style: TextStyle(height: 1.3)),
  //         WidgetSpan(
  //           alignment: PlaceholderAlignment.middle,
  //           child: Container(
  //             padding: const EdgeInsets.all(4),
  //             margin: const EdgeInsets.only(left: 3, right: 3),
  //             decoration: const BoxDecoration(
  //               borderRadius: BorderRadius.all(Radius.circular(20)),
  //             ),
  //           ),
  //         ),
  //         TextSpan(
  //           text: "检查更新",
  //           style: TextStyle(
  //             height: 1.3,
  //             color: Theme.of(context).colorScheme.primary,
  //           ),
  //           recognizer: TapGestureRecognizer()
  //             ..onTap = () => manualCheckNewVersion(context),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildDirty() {
  //   return Text.rich(
  //     TextSpan(
  //       text: "下载RELEASE版",
  //       style: TextStyle(
  //         height: 1.3,
  //         color: Theme.of(context).colorScheme.primary,
  //       ),
  //       recognizer: TapGestureRecognizer()..onTap = () => openUrl(_releasesUrl),
  //     ),
  //   );
  // }

  // Widget _buildNewVersionInfo(String? latestVersionInfo) {
  //   if (latestVersionInfo != null) {
  //     return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Divider(),
  //         const Text("更新内容:"),
  //         Container(
  //           padding: EdgeInsets.all(15),
  //           child: Text(
  //             latestVersionInfo,
  //             style: TextStyle(),
  //           ),
  //         ),
  //       ],
  //     );
  //   }
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Divider(),
  //       Container(
  //         padding: EdgeInsets.all(15),
  //         child: Text.rich(
  //           TextSpan(
  //             text: "去RELEASE仓库",
  //             style: TextStyle(
  //               height: 1.3,
  //               color: Theme.of(context).colorScheme.primary,
  //             ),
  //             recognizer: TapGestureRecognizer()
  //               ..onTap = () => openUrl(_releasesUrl),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
