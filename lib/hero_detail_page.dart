import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overwidget/player_detail.dart';
import 'package:overwidget/player_detail_page.dart';

class HeroDetailPage extends StatefulWidget {
  final OwHero hero;
  final String battletag;
  final String platform;

  HeroDetailPage(
      {Key key,
      @required this.hero,
      @required this.battletag,
      @required this.platform})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HeroDetailState(
        hero: hero, battletag: battletag, platform: platform);
  }
}

class HeroDetailState extends State<HeroDetailPage> {
  final OwHero hero;
  final String battletag;
  final String platform;

  BuildContext _scaffoldContext;

  //Map<String, dynamic> _statList = {};
  Map<String, dynamic> _heroStats = {};

  HeroDetailState(
      {Key key,
      @required this.hero,
      @required this.battletag,
      @required this.platform})
      : super();

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: new Text(hero.fixName(),
                style: TextStyle(fontFamily: 'GoogleSans'))),
        body: new Builder(builder: (BuildContext context) {
          return ListView.builder(
              itemCount: _heroStats.length,
              itemBuilder: (context, index) {
                return _buildCategory(_heroStats.keys.elementAt(index),
                    _heroStats.values.elementAt(index));
              });
        }));
  }

  Widget _buildItem(String key, String value) {
    return ListTile(
      title: Text(key),
      subtitle: Text(value),
    );
  }

  Widget _buildCategory(String title, Map<String, dynamic> map) {
    return ExpansionTile(
      key: PageStorageKey<String>(title),
      title: Text(title),
      children: _buildItemList(map)
    );
  }

  List<Widget> _buildItemList(Map<String, dynamic> map) {
    List<Widget> list = [];
    if (map != null) {
      map.forEach((key, value) {
        if (value != null)
          list.add(_buildItem(key, value.toString()));
      });
    }
    return list;
  }

  Future _fetchData() async {
    try {
      String url =
          "https://ow-api.com/v2/stats/$platform/${battletag.replaceAll('#', '-')}/complete";
      File fetchedFile = await CustomCacheManager().getSingleFile(url);

      if (fetchedFile != null) {
        var map = json.decode(await fetchedFile.readAsString());

        //Map<String, dynamic> heroStats;

        if (hero.isComp) {
          _heroStats = map['competitiveStats']['careerStats'][hero.name];
        } else {
          _heroStats = map['quickPlayStats']['careerStats'][hero.name];
        }

        /*heroStats.forEach((key, value) {
          if (value != null) _statList.addAll(value);
        });*/
      } else {
        if (context != null)
          Scaffold.of(_scaffoldContext)
              .showSnackBar(SnackBar(content: Text('Stats not found')));
      }
    } catch (e) {
      debugPrint(e.toString());
      if (context != null)
        Scaffold.of(_scaffoldContext)
            .showSnackBar(SnackBar(content: Text('Network Error')));
    }

    setState(() {});
  }
}
