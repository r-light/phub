import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:phub/common/global.dart';
import 'package:phub/widgets/components/my_about_me.dart';
import 'package:phub/widgets/components/my_search_page.dart';
import 'package:phub/widgets/components/my_search_result.dart';
import 'package:phub/widgets/components/my_setting_action.dart';
import 'package:phub/widgets/components/my_version.dart';
import 'package:phub/widgets/components/my_video_player.dart';
import 'package:phub/widgets/my_porny91.dart';
import 'package:phub/widgets/my_video_page.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initVersion();
  await Global.init();
  VideoLocal videoLocal = await VideoLocal().init();
  Configs configs = await Configs().init();
  await MyDio().parseBeauty();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: videoLocal),
      ChangeNotifierProvider.value(value: configs),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Global.appTitle,
      initialRoute: "/",
      locale: const Locale('zh'),
      onGenerateRoute: (RouteSettings settings) {
        var routes = <String, WidgetBuilder>{
          MySources.videoPlayer: (ctx) =>
              MyVideoPlayer(content: settings.arguments),
          MySources.searchPage: (ctx) =>
              MyVideoSearchPage(content: settings.arguments),
          MySources.searchResult: (ctx) =>
              MySearchResult(content: settings.arguments),
        };
        WidgetBuilder builder = routes[settings.name]!;
        return MaterialPageRoute(builder: (ctx) => builder(ctx));
      },
      routes: {
        MySources.porny91: (context) => const MyPorny91(),
        MySources.settings: (context) => const MySetting(),
        MySources.aboutMe: (context) => const MyAboutMe(),
      },
      theme: ThemeData(
        primarySwatch:
            MaterialColor(Colors.pink.shade200.value, Global.pinkMap),
        backgroundColor: Colors.white,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.system,
      home: const MyVideoPage(),
      builder: EasyLoading.init(),
    );
  }
}
