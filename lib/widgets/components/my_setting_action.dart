import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:phub/common/global.dart';
import 'package:phub/videos/my_porny91.dart';
import 'package:provider/provider.dart';

List<Widget> alwaysInActions() {
  return [
    const MySettingsAction(),
  ];
}

class MySettingsAction extends StatefulWidget {
  const MySettingsAction({Key? key}) : super(key: key);

  @override
  State<MySettingsAction> createState() => _SettingsActionState();
}

class _SettingsActionState extends State<MySettingsAction> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).pushNamed(MySources.settings);
      },
      icon: const Icon(Icons.settings),
    );
  }
}

class MySetting extends StatelessWidget {
  const MySetting({Key? key}) : super(key: key);

  static List<String> tabs = ["通用", MySources.sourceName[MySources.porny91]!];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("设置"),
          centerTitle: false,
          bottom: TabBar(
            isScrollable: false,
            tabs: tabs.map<Widget>((e) => Tab(text: e)).toList(),
          ),
        ),
        body: const TabBarView(
            children: [MyGeneralSetting(), My91PornySetting()]),
      ),
    );
  }
}

class MyGeneralSetting extends StatefulWidget {
  const MyGeneralSetting({Key? key}) : super(key: key);

  @override
  State<MyGeneralSetting> createState() => _MyGeneralSettingState();
}

class _MyGeneralSettingState extends State<MyGeneralSetting> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(5.0),
      children: <Widget>[
        ListTile(
          title: const Text('删除缓存'),
          onTap: () async {
            Global.showSnackBar("正在清除");
            await DefaultCacheManager().emptyCache();
            if (!mounted) return;
            Global.showSnackBar("清除成功");
          },
        ),
        ListTile(
          title: const Text('删除历史记录'),
          onTap: () async {
            Global.showSnackBar("正在清除");
            await Provider.of<VideoLocal>(context, listen: false)
                .removeAllHistory();
            if (!mounted) return;
            Global.showSnackBar("清除成功");
          },
        ),
        ListTile(
          title: const Text('清除收藏'),
          onTap: () async {
            bool? delete = await showDeleteConfirmDialog(context, "是否删除收藏");
            if (delete == null) return;
            if (!mounted) return;
            Global.showSnackBar("正在清除");
            await Provider.of<VideoLocal>(context, listen: false)
                .removeAllFavorite();
            if (!mounted) return;
            Global.showSnackBar("清除成功");
          },
        ),
        ListTile(
          title: const Text('限制历史数目'),
          subtitle: Text(
              "当前最大历史数目: ${context.select((VideoLocal videoLocal) => videoLocal.historyLimit)}"),
          onTap: () async {
            int? count = await showListDialog(context, "保留的历史数目");
            if (count == null) return;
            if (!mounted) return;
            Provider.of<VideoLocal>(context, listen: false).historyLimit =
                count;
            if (!mounted) return;
            Global.showSnackBar("设置成功");
          },
        ),
        ListTile(
          minVerticalPadding: 4,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text("网格模式显示标题"), showFooter()],
          ),
        ),
      ],
    );
  }

  // 弹出对话框
  Future<bool?> showDeleteConfirmDialog(BuildContext context, String text) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("提示"),
          content: Text(text),
          actions: <Widget>[
            TextButton(
              child: const Text("取消"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("确认"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<int?> showListDialog(BuildContext context, String text) async {
    return await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ListView.builder(
            itemCount: 21,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              int number = index * 5;
              return ListTile(
                title: Text("$number"),
                onTap: () => Navigator.of(context).pop(number),
              );
            },
          ),
        );
      },
    );
  }

  Widget showFooter() {
    return DropdownButton<bool>(
      underline: const SizedBox(),
      // Initial Value
      value: context.select((Configs config) => config.showFooterInGridView),
      // Down Arrow Icon
      icon: const Icon(Icons.keyboard_arrow_down),
      // Array list of items
      items: const [
        DropdownMenuItem(
          value: true,
          child: Text("是"),
        ),
        DropdownMenuItem(
          value: false,
          child: Text("否"),
        )
      ],
      // After selecting the desired option,it will
      // change button value to selected value
      onChanged: (bool? value) {
        if (value != null) {
          Provider.of<Configs>(context, listen: false).showFooterInGridView =
              value;
        }
      },
    );
  }
}

class My91PornySetting extends StatefulWidget {
  const My91PornySetting({Key? key}) : super(key: key);

  @override
  State<My91PornySetting> createState() => _My91PornySettingState();
}

class _My91PornySettingState extends State<My91PornySetting> {
  Future<List<String>> urls = PornyClient().parseCandidateDomain();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(5.0),
      children: <Widget>[
        ListTile(
          title: const Text('设置域名'),
          subtitle: Text("当前域名: ${PornyClient().currentDomain}"),
          onTap: () async {
            String? url = await showListDialog(context, "设置域名");
            if (url == null) return;
            if (!mounted) return;
            setState(() {
              PornyClient().currentDomain = url;
              MyDio().getHtml(url).then((res) {
                if (res.key == 200) {
                  Global.showSnackBar("$url 测试成功");
                } else {
                  Global.showSnackBar("$url 测试失败");
                }
              });
            });
          },
        ),
      ],
    );
  }

  // 弹出对话框
  Future<bool?> showDeleteConfirmDialog(BuildContext context, String text) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("提示"),
          content: Text(text),
          actions: <Widget>[
            TextButton(
              child: const Text("取消"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("确认"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<String?> showListDialog(BuildContext context, String text) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        var child = FutureBuilder<List<String>>(
          future: urls,
          builder: ((context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return Container();
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.requireData.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(snapshot.requireData[index]),
                  onTap: () =>
                      Navigator.of(context).pop(snapshot.requireData[index]),
                );
              },
            );
          }),
        );
        return Dialog(child: child);
      },
    );
  }
}
