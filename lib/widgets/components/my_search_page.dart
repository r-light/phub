import 'package:flutter/material.dart';
import 'package:phub/common/global.dart';

class MyVideoSearchPage extends StatefulWidget {
  const MyVideoSearchPage({Key? key, required this.content}) : super(key: key);

  final dynamic content;

  @override
  State<StatefulWidget> createState() => MyVideoSearchPageState();
}

class MyVideoSearchPageState extends State<MyVideoSearchPage> {
  String _searchContext = "";
  final _textEditingController = TextEditingController();
  final _searchContentFocusNode = FocusNode();
  final double height = 15;
  final double padding = 15;
  late Decoration? dec =
      MediaQuery.of(context).platformBrightness == Brightness.dark
          ? null
          : BoxDecoration(color: Theme.of(context).colorScheme.primary);
  Porny91Options? _pornyOp = Porny91Options.author;

  @override
  void initState() {
    super.initState();
    _textEditingController.text = _searchContext;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _searchContentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0.0,
          title: Text(widget.content["sourceName"], textAlign: TextAlign.left),
          centerTitle: false),
      body: Column(
        children: [
          Container(
            height: height,
            decoration: dec,
          ),
          Container(
            decoration: dec,
            padding: EdgeInsets.all(padding),
            child: TextField(
              // scrollPadding: EdgeInsets.all(padding),
              textAlignVertical: TextAlignVertical.bottom,
              toolbarOptions: const ToolbarOptions(
                  copy: true, cut: true, paste: true, selectAll: true),
              autofocus: true,
              textInputAction: TextInputAction.search,
              controller: _textEditingController,
              onChanged: (value) => _searchContext = value,
              focusNode: _searchContentFocusNode,
              decoration: const InputDecoration(
                // contentPadding: EdgeInsets.only(top: 0, bottom: 0),
                hintText: "请输入内容...",
                focusedBorder: UnderlineInputBorder(
                    // borderSide: BorderSide(color: Colors.black),
                    ),
              ),
              keyboardType: TextInputType.text,
              onSubmitted: (String value) {
                Navigator.of(context)
                    .pushNamed(MySources.searchResult, arguments: {
                  "keywords": _searchContext,
                  "searchFunc": widget.content["searchFunc"],
                  "index": _pornyOp?.index ?? 0,
                  "videoFunc": widget.content["videoFunc"],
                  "relatedFunc": widget.content["relatedFunc"],
                  "authorFunc": widget.content["authorFunc"],
                });
              },
            ),
            // IconButton(icon: Icon(Icons.search), onPressed: () {}),
          ),
          Container(
            decoration: dec,
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 5),
            alignment: Alignment.centerRight,
            child: CircleAvatar(
              radius: height + 10,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withGreen(120),
              child: IconButton(
                icon: const Icon(
                  Icons.search,
                  // color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(MySources.searchResult, arguments: {
                    "keywords": _searchContext,
                    "searchFunc": widget.content["searchFunc"],
                    "index": _pornyOp?.index ?? 0,
                    "videoFunc": widget.content["videoFunc"],
                    "relatedFunc": widget.content["relatedFunc"],
                    "authorFunc": widget.content["authorFunc"],
                  });
                },
              ),
            ),
          ),
          getDropDownWidget(),
        ],
      ),
    );
  }

  Widget getDropDownWidget() {
    if (widget.content["sourceName"] ==
        MySources.sourceName[MySources.porny91]!) {
      return Column(
        children: <Widget>[
          RadioListTile<Porny91Options>(
            title: const Text('最新'),
            value: Porny91Options.latest,
            groupValue: _pornyOp,
            onChanged: (Porny91Options? value) {
              setState(() {
                _pornyOp = value;
              });
            },
          ),
          RadioListTile<Porny91Options>(
            title: const Text('最热'),
            value: Porny91Options.hottest,
            groupValue: _pornyOp,
            onChanged: (Porny91Options? value) {
              setState(() {
                _pornyOp = value;
              });
            },
          ),
          RadioListTile<Porny91Options>(
            title: const Text('作者'),
            value: Porny91Options.author,
            groupValue: _pornyOp,
            onChanged: (Porny91Options? value) {
              setState(() {
                _pornyOp = value;
              });
            },
          ),
        ],
      );
    }
    return Container();
  }
}
