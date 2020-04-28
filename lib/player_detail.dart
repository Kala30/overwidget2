import 'package:flutter/material.dart';


class PlayerDetail {

  int compGamesPlayed;
  int compGamesWon;
  int compWinRate;
  String compTimePlayed;

  int qpGamesPlayed;
  int qpGamesWon;
  String qpTimePlayed;

  List<OwHero> compHeroes = [];
  List<OwHero> qpHeroes = [];

  PlayerDetail({Key key,
    @required this.compGamesPlayed,
    @required this.compGamesWon,
    this.compWinRate,
    this.compTimePlayed,
    this.qpGamesPlayed,
    this.qpGamesWon,
    this.qpTimePlayed}) {

    compWinRate = (compGamesWon / compGamesPlayed * 100).round();
  }
}

class OwHero {

  String name;

  String timePlayed;
  Duration durationPlayed;
  int gamesWon;
  int winPercentage;
  int weaponAccuracy;
  double eliminationsPerLife;
  int multiKillBest;
  int objectiveKills;
  Color color;
  bool isComp; // competitive

  Duration getDuration() {
    var times = timePlayed.split(':');
    int hours = 0, minutes = 0, seconds = 0;
    if (times.length==2) {
      minutes = int.parse(times[0]);
      seconds = int.parse(times[1]);
    } else {
      hours = int.parse(times[0]);
      minutes = int.parse(times[1]);
      seconds = int.parse(times[2]);
    }
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  int compareTo(OwHero other) {
    return this.getDuration().compareTo(other.getDuration());
  }

  static OwHero fromMap(Map<String, dynamic> map) {
    return new OwHero()
      ..timePlayed = map['timePlayed']
      ..gamesWon = map['gamesWon']
      ..winPercentage = map['winPercentage']
      ..weaponAccuracy = map['weaponAccuracy']
      ..eliminationsPerLife = map['eliminationsPerLife'].toDouble()
      ..multiKillBest = map['multiKillBest']
      ..objectiveKills = map['objectiveKills'];
  }

  String fixName() {
    switch (name) {
      case 'soldier76':
        return 'Soldier: 76';
      case 'dVa':
        return 'D.Va';
      case 'mccree':
        return 'McCree';
      case 'wreckingBall':
        return 'Wrecking Ball';
      default:
        return '${this.name[0].toUpperCase()}${this.name.substring(1)}';
  }

  }

  String fixTime() {
    String fixed = timePlayed.replaceAll(RegExp("^0+"), "");
    if (fixed.length > 3)
      return fixed;
    // Add 0 in front if only seconds
    return '0' + fixed;
  }


  void setColor(String css) {
    try {
      String name = this.name.toLowerCase();
      if (this.name=='soldier76')
        name = 'soldier-76';
      else if (this.name=='wreckingBall')
        name = 'wrecking-ball';

      RegExpMatch match = RegExp("\\.ow-$name-color{background-color:(.*?)}", multiLine: false).firstMatch(css);

      color =  hexToColor(match.group(1));

    } catch (e) {
      debugPrint(e.toString());
      debugPrint(name);
      color = Colors.grey;
    }

  }

  String getIconUrl() {
    String name = this.name.toLowerCase();
    if (this.name=='soldier76')
      name = 'soldier-76';
    else if (this.name=='wreckingBall')
      name = 'wrecking-ball';

    return 'https://d1u1mce87gyfbn.cloudfront.net/hero/$name/icon-portrait.png';
  }

  Color hexToColor(String hexString, {String alphaChannel = 'FF'}) {
    if(hexString.length==4)
      hexString = '#${hexString[1]}${hexString[1]}${hexString[2]}${hexString[2]}${hexString[3]}${hexString[3]}';
    return Color(int.parse(hexString.replaceFirst('#', '0x$alphaChannel')));
  }
}
