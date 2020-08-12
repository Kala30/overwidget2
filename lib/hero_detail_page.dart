import 'dart:convert';
import 'dart:io';
import 'dart:async';

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

  Map<String, dynamic> _heroStats = {};
  String _gamesLost;
  String _gamesWon;
  String _timePlayed;
  String _winPercentage;
  String _weaponAccuracy;
  String _damageDone;
  String _healingDone;

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
                if (index == 0)
                  return _buildCard();
                else
                  return _buildCategory(_heroStats.keys.elementAt(index-1),
                      _heroStats.values.elementAt(index-1));
              });
        }));
  }

  Widget _buildItem(String key, String value) {
    return ListTile(
      title: Text(_fixTitle(key)),
      subtitle: Text(value),
    );
  }

  Widget _buildCategory(String title, Map<String, dynamic> map) {
    return ExpansionTile(
      key: PageStorageKey<String>(title),
      title: Text(_fixTitle(title)),
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

  Widget _buildCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              Padding(padding:EdgeInsets.only(top: 12, left: 12),child: Text(hero.isComp ? 'Competitive' : 'Quick Play') ),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _buildStat(_timePlayed, 'Time Played'),
                    hero.isComp ? _buildStat(_winPercentage, 'Win Rate')
                        : _buildStat(_gamesWon, 'Games Won'),
                    hero.isComp ? _buildStat('$_gamesWon-$_gamesLost', 'Record')
                        : _buildStat(_heroStats['matchAwards']['medals'].toString(), 'Medals')
                  ]
              ),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildStat(_weaponAccuracy, 'Accuracy'),
                  ]
              ),

              Padding(padding:EdgeInsets.only(top: 12, left: 12),child: Text('Average Per 10 Min') ),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildStat(_heroStats['average']['eliminationsAvgPer10Min'].toString(), 'Eliminations'),
                    _buildStat(_heroStats['average']['objectiveKillsAvgPer10Min'].toString(), 'Obj Kills'),
                    _buildStat(_heroStats['average']['objectiveTimeAvgPer10Min'].toString(), 'Obj Time'),

                  ]
              ),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildStat(_damageDone, 'Damage'),
                    _buildStat(_heroStats['average']['deathsAvgPer10Min'].toString(), 'Deaths'),
                    _healingDone != 'null' ? _buildStat(_healingDone, 'Healing')
                        : _buildStat('', ''),
                  ]
              )

            ])
      )
    );
  }

  Widget _buildStat(String title, String subtitle) {
    return Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(left: 12, right: 12, top: 12),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headline6,
                textScaleFactor: 0.9,
              )),
          Padding(
              padding: EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
              child: Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor)))
        ]));
  }

  String _fixTitle(String title) {
    String fixed = title.replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return ' ${match.group(0)}';
    });
    fixed = fixed.replaceAllMapped(RegExp(r'([a-z])([0-9])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    });
    return '${fixed[0].toUpperCase()}${fixed.substring(1)}';
  }


  Future _fetchData() async {
    try {
      String url =
          "https://ow-api.com/v2/stats/$platform/${battletag.replaceAll('#', '-')}/complete";
      File fetchedFile = await CustomCacheManager().getSingleFile(url);

      if (fetchedFile != null) {
        var map = json.decode(await fetchedFile.readAsString());

        if (hero.isComp) {
          _heroStats = map['competitiveStats']['careerStats'][hero.name];
        } else {
          _heroStats = map['quickPlayStats']['careerStats'][hero.name];
        }

        _gamesLost = _heroStats['game']['gamesLost'].toString();
        if (_heroStats['game']['gamesWon'] != null)
          _gamesWon = _heroStats['game']['gamesWon'].toString();
        else
          _gamesWon = '0';
        _timePlayed = _heroStats['game']['timePlayed'].toString();
        if (_heroStats['game']['winPercentage'] != null)
          _winPercentage = _heroStats['game']['winPercentage'].toString();
        else
          _winPercentage = '0%';
        if (_heroStats['combat']['weaponAccuracy'] != null)
          _weaponAccuracy = _heroStats['combat']['weaponAccuracy'].toString();
        else
          _weaponAccuracy = 'N/A';
        _damageDone = _heroStats['average']['heroDamageDoneAvgPer10Min'].toString();
        _healingDone = _heroStats['average']['healingDoneAvgPer10Min'].toString();


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
