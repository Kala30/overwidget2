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
  final PopupMenuButton popupMenu;
  NewsPage(this.popupMenu);
  @override
  createState() => new NewsPageState();
}

class NewsPageState extends State<NewsPage> {

  static const String NEWS_URL = 'https://playoverwatch.com/news';
  static const String PATCH_URL = 'https://playoverwatch.com/news/patch-notes/live';

  BuildContext scaffoldContext;
  List<News> _newsList = [];
  List<News> _featuredList = [];
  News _featuredPatch;

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
    await _fetchData();
  }


  @override
  Widget build(BuildContext context) {
    return buildHome();
  }

  Widget buildHome() {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text('OverWidget', style: TextStyle(fontFamily: 'GoogleSans', color: Theme.of(context).accentColor) ),
            actions: <Widget>[widget.popupMenu]
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
                /*return Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text('News', style: Theme.of(context).textTheme.headline5)
                );*/
                return _buildPatchItem(_featuredPatch);
              else
                return _buildItem(_newsList[index-2]);
            }
        )
    );
  }

  Widget _buildFeaturedList() {
    return SizedBox(
      height: 260,
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
    return ListTile(
      onTap: () => _launchURL(news.url),
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(news.imgUrl, height: 54, fit: BoxFit.cover)
      ),
      title: Text(news.title),
      subtitle: Text(news.date)
    );
  }

  Widget _buildFeaturedItem(News news) {
    return Container(width: 280, child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.all(12),
        child: InkWell(
            onTap: () => _launchURL(news.url),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                    child: Ink.image(image: NetworkImage(news.imgUrl), fit: BoxFit.cover)
                ),
                ListTile(
                  title: Text(news.title, style: TextStyle(fontSize: 14)),
                  subtitle: Text(news.date),
                )
              ],
            )
        )
    ));
  }

  Widget _buildPatchItem(News news) {
    return Card(
      margin: EdgeInsets.all(12),
      child: InkWell(
        onTap: () => _launchURL(news.url),
        child: ListTile(
          title: Text(news.title),
          subtitle: Text(news.date),
          leading: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.new_releases)]
          ),
          trailing: Icon(Icons.arrow_forward),
        ),
      ),
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
      Response response = await client.get(NEWS_URL);

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
          ..date = blog.querySelector('.Card-date').text;

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

      // Patch Notes
      Response patchResponse = await client.get(PATCH_URL);
      var patchDoc = parse(patchResponse.body);
      dom.Element body = patchDoc.querySelector('.PatchNotes-body');

      _featuredPatch = new News()
        ..title = patchDoc.querySelector('.PatchNotesTooltip-title').text
        ..description = body.querySelector('.PatchNotes-patchTitle').text
        ..url = patchResponse.request.url.toString()
        ..date = body.querySelector('.PatchNotes-date').text;

    } catch (e) {
      debugPrint(e.toString());
      Scaffold.of(scaffoldContext).showSnackBar(SnackBar(content: Text('Error fetching news')));
    }

    setState(() {
      _isLoading = false;
    });
  }


}