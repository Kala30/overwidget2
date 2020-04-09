import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;

import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';



class News {
  String title;
  String description;
  String url;
  String imgUrl;
  String date;
}

class NewsPage extends StatefulWidget {
  final Function setDarkTheme;
  NewsPage(this.setDarkTheme);
  @override
  createState() => new NewsPageState();
}

class NewsPageState extends State<NewsPage> {
  BuildContext scaffoldContext;
  List<News> _newsList = [];
  List<News> _featuredList = [];

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
      debugPrint('NewsPage: ' + e.toString());
    }

  }

  Future _refreshList() async {
    _newsList = [];
    _featuredList = [];
    _fetchData();
  }


  @override
  Widget build(BuildContext context) {
    return buildHome();
  }

  Widget buildHome() {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text('OverWidget', style: TextStyle(fontFamily: 'GoogleSans', color: Theme.of(context).accentColor) ),
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: (String result) {
                  switch (result) {
                    case 'darkTheme':
                      widget.setDarkTheme(!prefs.getBool('darkTheme'));
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem(
                      value: 'darkTheme',
                      child: IgnorePointer(child: SwitchListTile(
                          dense: true,
                          title: Text("Dark Theme"),
                          value: prefs.getBool('darkTheme'),
                          onChanged: (value) {},
                          activeColor: Theme.of(context).accentColor
                      ))
                  )
                ],
              )
         ]
        ),
        body: new Builder(builder: (BuildContext context) {
          scaffoldContext = context;
          if (_isLoading)
            return Center(child: new CircularProgressIndicator());
          if (_newsList.length <= 0 )
            return Center(child: Icon(Icons.error_outline, size: 48));
          return _buildList();
        })
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshList,
        child: ListView.builder(
            itemCount: _newsList.length + 2,
            itemBuilder: (context, index) {
              if (index == 0)
                return _buildFeaturedList();
              else if (index == 1)
                return Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text('News', style: Theme.of(context).textTheme.headline5)
                );
              else
                return _buildItem(_newsList[index-2]);
            }
        )
    );
  }

  Widget _buildFeaturedList() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
          key: PageStorageKey<String>('featuredList'),
          scrollDirection: Axis.horizontal,
          itemCount: _featuredList.length,
          itemBuilder: (context, index) {
            return _buildFeaturedItem(_featuredList[index]);
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
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                    child: Ink.image(image: NetworkImage(news.imgUrl), height: 180, fit: BoxFit.cover)
                ),
                ListTile(
                    title: Text(news.title/*, style: TextStyle(fontSize: 18)*/),
                    subtitle: Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget> [
                              Text(news.description/*, style: TextStyle(fontSize: 16)*/),
                              Padding(child: Text(news.date), padding: EdgeInsets.only(top: 8))
                            ]
                        )
                    )
                )
              ],
            )
        )
    );
  }

  Widget _buildFeaturedItem(News news) {
    return Container(width: 280, child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.all(12),
        child: InkWell(
            onTap: () => _launchURL(news.url),
            child: Column(
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Ink.image(image: NetworkImage(news.imgUrl), height: 160, fit: BoxFit.cover)
                ),
                ListTile(
                    title: Text(news.title, style: TextStyle(fontSize: 14))
                )
              ],
            )
        )
    ));
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

      // Featured
      List<dom.Element> featured = document.querySelectorAll(
          'section.NewsHeader-featured > a.CardLink');

      for (var blog in featured) {
        News news = new News()
          ..title = blog.querySelector('.Card-title').text
          ..url = 'https://playoverwatch.com' + blog.attributes['href']
          ..imgUrl = 'https:' + blog.querySelector('.Card-thumbnail').attributes['style'].replaceAll(RegExp(r'background-image: url\(|\)'), '')
          ..description = ''
          ..date = '';

        _featuredList.add(news);
      }

      // News
      List<dom.Element> blogs = document.querySelectorAll(
          'ul.NewsList-list > li.NewsItem');

      for (var blog in blogs) {
        News news = new News()
          ..title = blog.querySelector('a.NewsItem-title').text
          ..url = 'https://playoverwatch.com' + blog.querySelector('a.NewsItem-title').attributes['href']
          ..imgUrl = 'https:' + blog.querySelector('.Card-thumbnail').attributes['style'].replaceAll(RegExp(r'background-image: url\(|\)'), '')
          ..description = blog.querySelector('div.NewsItem-summary').text
          ..date = blog.querySelector('div.NewsItem-subtitle > span').text;

        _newsList.add(news);
      }

    } catch (e) {
      debugPrint(e.toString());
      Scaffold.of(scaffoldContext).showSnackBar(SnackBar(content: Text('Error fetching news')));
    }

    setState(() {
      _isLoading = false;
    });
  }


}