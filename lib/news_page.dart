import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;

import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:transparent_image/transparent_image.dart';



class News {
  String title;
  String url;
  String imgUrl;
  String date;
}

class NewsPage extends StatefulWidget {
  bool _isDarkTheme;
  Function setDarkTheme;
  NewsPage(this._isDarkTheme, this.setDarkTheme);
  @override
  createState() => new NewsPageState();
}

class NewsPageState extends State<NewsPage> {
  BuildContext scaffoldContext;
  List<News> _newsList = [];

  bool _isDarkTheme;
  bool _isLoading = true;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  new GlobalKey<RefreshIndicatorState>();


  @override
  void initState() {
    super.initState();

    _isDarkTheme = widget._isDarkTheme;

    _initList();
  }

  _initList() async {
    try {
      await _fetchData();
    } catch (e) {
      debugPrint('NewsPage: ' + e.toString());
    }
  }

  Future _refreshList() async {
    _newsList = [];
    _fetchData();
  }


  @override
  Widget build(BuildContext context) {
    return buildHome();
  }

  Widget buildHome() {
    return new Scaffold(
        appBar: new AppBar(title: new Text('OverWidget', style: TextStyle(fontFamily: 'GoogleSans', color: Theme.of(context).accentColor) ), actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'darkTheme':
                  widget.setDarkTheme(!_isDarkTheme);
                  _isDarkTheme = !_isDarkTheme;
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                  value: 'darkTheme',
                  child: IgnorePointer(child: SwitchListTile(
                      dense: true,
                      title: Text("Dark Theme"),
                      value: _isDarkTheme,
                      onChanged: (value) {},
                      activeColor: Theme.of(context).accentColor
                  ))
              )
            ],
          )
        ]),
        body: new Builder(builder: (BuildContext context) {
          scaffoldContext = context;
          return _isLoading ? new Center(child: new CircularProgressIndicator())
              : _buildList();
        })
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshList,
        child: ListView.builder(
            itemCount: _newsList.length,
            itemBuilder: (context, index) {
              return _buildItem(_newsList[index]);
            }
        )
    );
  }

  Widget _buildItem(News news) {
    return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.all(12),
        child: InkWell(
            onTap: () => _launchURL(news.url),
            child: Column(
              children: <Widget>[
                Ink.image(image: NetworkImage(news.imgUrl), height: 200, fit: BoxFit.cover),
                ListTile(
                    title: Text(news.title, style: TextStyle(fontSize: 18)),
                    subtitle: Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text(news.date, style: TextStyle(fontSize: 16))
                    )
                )
              ],
            )
        )
    );
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
      Response response = await client.get('https://playoverwatch.com/news');

      var document = parse(response.body);
      List<dom.Element> blogs = document.querySelectorAll(
          'ul.blog-list > li.blog-info');

      for (var blog in blogs) {
        News news = new News()
          ..title = blog.querySelector('a.link-title').text
          ..url = 'https://playoverwatch.com' + blog.querySelector('a.link-title').attributes['href']
          ..imgUrl = 'https:' + blog.querySelector('img').attributes['src']
          ..date = blog.querySelectorAll('div.sub-title > span')[1].text;

        _newsList.add(news);
      }

    } catch (e) {
      Scaffold.of(scaffoldContext).showSnackBar(SnackBar(content: Text('Error fetching news')));
    }

    setState(() {
      _isLoading = false;
    });
  }


}