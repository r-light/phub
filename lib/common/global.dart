import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phub/common/dto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum Porny91Options { latest, hottest, author }

class Global {
  const Global._();
  static late final Directory app;
  static late final Directory cache;
  static late final String appPath;
  static late final String cachePath;
  static const appTitle = "Phub";
  static const versionUrl =
      "https://api.github.com/repos/r-light/phub/releases/latest";
  static const releaseUrl = "https://github.com/r-light/phub/releases/";

  static const Map<int, Color> pinkMap = {
    50: Color(0xFFFCE4EC),
    100: Color(0xFFF8BBD0),
    200: Color(0xFFF48FB1),
    300: Color(0xFFF06292),
    400: Color(0xFFEC407A),
    500: Color(0xFFE91E63),
    600: Color(0xFFD81B60),
    700: Color(0xFFC2185B),
    800: Color(0xFFAD1457),
    900: Color(0xFF880E4F),
  };

  static Future init() async {
    app = await getApplicationDocumentsDirectory();
    cache = await getTemporaryDirectory();
    appPath = app.path;
    cachePath = cache.path;
  }

  static String videoSimpleKey(VideoSimple item) {
    return item.id + (item.source ?? "unknown");
  }

  static void openUrl(String url) async {
    var uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $uri';
    }
  }

  static void showSnackBar(String text, [Duration? duration]) {
    EasyLoading.dismiss();
    duration == null
        ? EasyLoading.showToast(text,
            toastPosition: EasyLoadingToastPosition.bottom)
        : EasyLoading.showToast(text,
            toastPosition: EasyLoadingToastPosition.bottom, duration: duration);
  }

  static String trimAllLF(String s) {
    return s.replaceAll('\n', " ").trim();
  }
}

class MySources {
  static const Map<String, String> sourceName = {
    porny91: porny91,
    missav: missav,
  };

  static const porny91 = "91porny";
  static const missav = "MISSAV";

  static const settings = "setting";
  static const videoPlayer = "videoPlayer";
  static const searchPage = "MyVideoSearchPage";
  static const searchResult = "MyVideoSearchResult";
  static const aboutMe = "MyAboutMe";
  static const missAvActress = "missAvActress";
}

class VideoLocal with ChangeNotifier {
  static const defaultLimit = 100;
  final LinkedHashMap<String, VideoSimple> history =
      LinkedHashMap<String, VideoSimple>();
  final LinkedHashMap<String, VideoSimple> favorite =
      LinkedHashMap<String, VideoSimple>();
  late int _historyLimit;

  int get historyLimit => _historyLimit;

  set historyLimit(int limit) {
    _historyLimit = limit;
    while (history.length > limit) {
      String key = history.keys.first;
      history.remove(key);
    }
    notifyListeners();
    SharedPreferences.getInstance()
        .then((pref) => pref.setString("savedHistory", jsonEncode(history)));
  }

  Future init() async {
    var pref = await SharedPreferences.getInstance();
    // load history
    String savedHistory = pref.getString("savedHistory") ?? "";
    if (savedHistory.isNotEmpty) {
      Map map = jsonDecode(savedHistory);
      map.forEach((key, value) {
        history[key] = VideoSimple.fromJson(value);
      });
    }
    // load favorite
    String savedFavorite = pref.getString("savedFavorite") ?? "";
    if (savedFavorite.isNotEmpty) {
      Map map = jsonDecode(savedFavorite);
      map.forEach((key, value) {
        favorite[key] = VideoSimple.fromJson(value);
      });
    }
    // load limit
    _historyLimit = pref.getInt("historyLimit") ?? defaultLimit;
    return this;
  }

  Future<bool> saveHistory(VideoSimple item) async {
    final key = Global.videoSimpleKey(item);
    history.remove(key);
    history[key] = item;
    notifyListeners();
    var pref = await SharedPreferences.getInstance();
    return pref.setString("savedHistory", jsonEncode(history));
  }

  void removeHistory() {
    if (history.length <= historyLimit) return;
    while (history.length > historyLimit) {
      String key = history.keys.first;
      history.remove(key);
    }
    notifyListeners();
    SharedPreferences.getInstance()
        .then((pref) => pref.setString("savedHistory", jsonEncode(history)));
  }

  Future removeAllHistory() async {
    var pref = await SharedPreferences.getInstance();
    pref.remove("savedHistory");
    history.clear();
    notifyListeners();
  }

  bool isFavorite(VideoSimple item) {
    final key = Global.videoSimpleKey(item);
    return favorite.containsKey(key);
  }

  Future<bool> saveFavorite(VideoSimple item) async {
    final key = Global.videoSimpleKey(item);
    if (favorite.containsKey(key)) return true;
    favorite[key] = item;
    notifyListeners();
    var pref = await SharedPreferences.getInstance();
    return pref.setString("savedFavorite", jsonEncode(favorite));
  }

  Future removeFavorite(VideoSimple item) async {
    final key = Global.videoSimpleKey(item);
    if (favorite.containsKey(key)) {
      favorite.remove(key);
      notifyListeners();
      var pref = await SharedPreferences.getInstance();
      pref.setString("savedFavorite", jsonEncode(favorite));
    }
  }

  Future removeAllFavorite() async {
    if (favorite.isEmpty) return;
    favorite.clear();
    notifyListeners();
    var pref = await SharedPreferences.getInstance();
    pref.setString("savedFavorite", jsonEncode(favorite));
  }

  void insertFavoriteIndex(int index1, int index2) async {
    if (index1 == index2) return;
    List<MapEntry<String, VideoSimple>> entries = favorite.entries.toList();
    var removed = entries.removeAt(index1);
    entries.insert(index2, removed);

    favorite.clear();
    favorite.addEntries(entries);
    notifyListeners();
    var pref = await SharedPreferences.getInstance();
    pref.setString("savedFavorite", jsonEncode(favorite));
  }
}

class MyDio {
  static MyDio? _instance;
  late Dio dio;
  final _beautyUrl = "https://www.kanxiaojiejie.com";
  List<String> beautyList = [];
  int _idx = 0;

  MyDio._internal() {
    dio = Dio();
    dio.options.connectTimeout = 3000;
    dio.options.receiveTimeout = 5000;
    _instance = this;
  }

  factory MyDio() => _instance ?? MyDio._internal();

  Future<MapEntry<int, String>> getHtml(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      var resp = await MyDio().dio.get(url);
      return MapEntry(resp.statusCode ?? 0, resp.data.toString());
    } catch (e) {
      return const MapEntry(0, "");
    }
  }

  Future parseBeauty() async {
    try {
      var resp = await MyDio().dio.get(_beautyUrl);
      var content = resp.data.toString();
      var doc = parse(content);
      var imgs = doc.querySelector(".masonry")?.querySelectorAll("img");
      imgs?.forEach((element) {
        beautyList.add(element.attributes["src"] ?? "");
      });
      return;
    } catch (e) {
      return;
    }
  }

  String get beautyUrl {
    if (beautyList.isEmpty) return "";
    return beautyList[_idx];
  }

  void increaseIdx() {
    _idx++;
    _idx %= beautyList.length;
  }
}

class Configs with ChangeNotifier {
  late bool _listViewInPorny91;
  late bool _listViewInSearchResult;
  late bool _listViewInMissAv;
  late bool _showFooterInGridView;
  double _listViewItemHeight = 110;

  Future init() async {
    var pref = await SharedPreferences.getInstance();
    _listViewInPorny91 = pref.getBool("listViewInPorny91") ?? true;
    _listViewInSearchResult = pref.getBool("listViewInSearchResult") ?? true;
    _listViewInMissAv = pref.getBool("listViewInMissAv") ?? true;
    _showFooterInGridView = pref.getBool("showFooterInGridView") ?? true;
    return this;
  }

  bool get listViewInPorny91 => _listViewInPorny91;

  set listViewInPorny91(bool value) {
    _listViewInPorny91 = value;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((pref) => pref.setBool("listViewInPorny91", _listViewInPorny91));
  }

  bool get listViewInSearchResult => _listViewInSearchResult;

  set listViewInSearchResult(bool value) {
    _listViewInSearchResult = value;
    notifyListeners();
    SharedPreferences.getInstance().then((pref) =>
        pref.setBool("listViewInSearchResult", _listViewInSearchResult));
  }

  double get listViewItemHeight => _listViewItemHeight;

  set listViewItemHeight(double value) {
    _listViewItemHeight = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
        (pref) => pref.setDouble("listViewItemHeight", _listViewItemHeight));
  }

  bool get listViewInMissAv => _listViewInMissAv;

  set listViewInMissAv(bool value) {
    _listViewInMissAv = value;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((pref) => pref.setBool("listViewInMissAv", _listViewInMissAv));
  }

  bool get showFooterInGridView => _showFooterInGridView;

  set showFooterInGridView(bool value) {
    _showFooterInGridView = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
        (pref) => pref.setBool("showFooterInGridView", _showFooterInGridView));
  }
}
