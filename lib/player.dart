import 'localstorage.dart';
import 'dart:convert';

class Player {

  Player();

  String name;
  String platform;
  String region;

  int rating;
  String ratingIcon;
  int level;

  String icon;
  int gamesWon;
  int endorsement;

}

String toJson(List<Player> players) {

  List maps = [];
  for (Player player in players) {
    Map<String, dynamic> map = {
      'name': player.name,
      'platform': player.platform,
      'region': player.region,

      'icon': player.icon,
      'level': player.level,
      'endorsement': player.endorsement,

      'gamesWon': player.gamesWon,
      'rating': player.rating,
      'ratingIcon': player.ratingIcon,
    };
    maps.add(map);
  }

  return json.encode(maps);
}

List<Player> fromJson(String body) {
  List maps = json.decode(body);
  List<Player> players = [];

  for(Map map in maps) {
    Player player = new Player()
      ..name = map['name']
      ..platform = map['platform']
      ..region = map['region']

      ..rating = map['rating']
      ..ratingIcon = map['ratingIcon']
      ..endorsement = map['endorsement']

      ..icon = map['icon']
      ..level = map['level']
      ..gamesWon = map['gamesWon'];

    players.add(player);
  }

  return players;
}