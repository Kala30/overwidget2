import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Patch {
  String title;
  String url;
  String date;
  String description;
  bool isFeatured = false;
}

class PatchPage extends StatefulWidget {
  final PopupMenuButton popupMenu;
  PatchPage(this.popupMenu);
  @override
  createState() => new PatchPageState();
}

class PatchPageState extends State<PatchPage> {
  BuildContext scaffoldContext;
  List<Patch> _patchList = [];

  bool _isLoading = true;

  SharedPreferences prefs;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    _initList();

    super.initState();
  }

  _initList() async {
    prefs = await SharedPreferences.getInstance();
    try {
      await _fetchData();
    } catch (e) {
      debugPrint('PatchPage: ' + e.toString());
    }
  }

  Future _refreshList() async {
    _patchList = [];
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return buildHome();
  }

  Widget buildHome() {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text('OverWidget',
                style: TextStyle(
                    fontFamily: 'GoogleSans',
                    color: Theme.of(context).accentColor)),
            actions: <Widget>[widget.popupMenu]
        ),
        body: new Builder(builder: (BuildContext context) {
          scaffoldContext = context;
          return _isLoading
              ? new Center(child: new CircularProgressIndicator())
              : _buildList();
        }));
  }

  Widget _buildList() {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshList,
        child: _patchList.length > 0
            ? ListView.builder(
                itemCount: _patchList.length,
                itemBuilder: (context, index) {
                  return _patchList[index].isFeatured
                      ? _buildFeatured(_patchList[index])
                      : _buildItem(_patchList[index]);
                })
            : Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline, size: 48),
                FlatButton(child: Text('RETRY'), textTheme: ButtonTextTheme.accent,
                  onPressed: () => setState(() {
                    _isLoading = true;
                    _refreshList();
                  })
                )
              ])));
  }

  Widget _buildItem(Patch patch) {
    return ListTile(
        title: Text(patch.title),
        subtitle: Text(patch.date),
        onTap: () => _launchURL(patch.url));
  }

  Widget _buildFeatured(Patch patch) {
    return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.all(12),
        child: InkWell(
            onTap: () => _launchURL(patch.url),
            child: Column(
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                        child: Text(patch.title,
                            style: Theme.of(context)
                                .textTheme
                                .headline2
                                .apply(fontSizeFactor: 0.35)),
                        alignment: Alignment.centerLeft)),
                ListTile(
                    title: Text(patch.description),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: Text(patch.date)),
                          Align(
                              alignment: Alignment.centerRight,
                              child: FlatButton(
                                  child: new Text('MORE'),
                                  textTheme: ButtonTextTheme.accent,
                                  onPressed: () => _launchURL(patch.url)))
                        ]))
              ],
            )));
  }

  void _launchURL(final String url) async {
    try {
      await launch(url,
          option: new CustomTabsOption(
            toolbarColor: Theme.of(scaffoldContext).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
          ));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future _fetchData() async {
    try {
      var client = Client();

      List<Response> responses = [];
      responses.add(
          await client.get('https://playoverwatch.com/news/patch-notes/live'));
      responses.add(
          await client.get('https://playoverwatch.com/news/patch-notes/ptr'));
      responses.add(await client
          .get('https://playoverwatch.com/news/patch-notes/experimental'));

      for (var response in responses) {
        var document = parse(response.body);
        dom.Element body = document.querySelector('.PatchNotes-body');

        Patch patch = new Patch()
          ..title = document.querySelector('.PatchNotesTooltip-title').text
          ..description = body.querySelector('.PatchNotes-patchTitle').text
          ..url = response.request.url.toString()
          ..date = body.querySelector('.PatchNotes-date').text
          ..isFeatured = true;

        _patchList.add(patch);
      }
    } catch (e) {
      debugPrint(e.toString());
      Scaffold.of(scaffoldContext)
          .showSnackBar(SnackBar(content: Text('Error fetching news')));
    }

    setState(() {
      _isLoading = false;
    });
  }
}
