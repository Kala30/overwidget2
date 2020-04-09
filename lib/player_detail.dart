class PlayerDetail {

  int compGamesPlayed;
  int compGamesWon;
  String compTimePlayed;

  int qpGamesPlayed;
  int qpGamesWon;
  String qpTimePlayed;

  List<OwHero> compHeroes = [];
  List<OwHero> qpHeroes = [];
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
}
