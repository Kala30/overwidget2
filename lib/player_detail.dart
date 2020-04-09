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
  int gamesWon;
  int winPercentage;
  int weaponAccuracy;
  double eliminationsPerLife;
  int multiKillBest;
  int objectiveKills;

  int compareTo(OwHero other) {
    int time = int.parse(this.timePlayed.replaceAll(RegExp('\\D+'), ""));
    int otherTime = int.parse(other.timePlayed.replaceAll(RegExp('\\D+'), ""));
    return time.compareTo(otherTime);
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
      default:
        return '${this.name[0].toUpperCase()}${this.name.substring(1)}';
  }

  }

  String fixTime() {
    return timePlayed.replaceAll(RegExp("^0+"), "");
  }
}
