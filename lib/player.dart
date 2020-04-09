import 'dart:convert';

class Player {

  Player(this.name, this.platform, this.region);

  String name;
  String platform;
  String region;

  int rating;
  String ratingIcon;
  int tankRating;
  String tankRatingIcon;
  int dpsRating;
  String dpsRatingIcon;
  int supportRating;
  String supportRatingIcon;

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
      'tankRating': player.tankRating,
      'tankRatingIcon': player.tankRatingIcon,
      'dpsRating': player.dpsRating,
      'dpsRatingIcon': player.dpsRatingIcon,
      'supportRating': player.supportRating,
      'supportRatingIcon': player.supportRatingIcon,
    };
    maps.add(map);
  }

  return json.encode(maps);
}

List<Player> fromJson(String body) {
  List maps = json.decode(body);
  List<Player> players = [];

  for(Map map in maps) {
    Player player = new Player(map['name'], map['platform'], map['region'])
      ..endorsement = map['endorsement']
      ..icon = map['icon']
      ..level = map['level']
      ..gamesWon = map['gamesWon']

      ..rating = map['rating']
      ..ratingIcon = map['ratingIcon']

      ..tankRating = map['tankRating']
      ..tankRatingIcon = map['tankRatingIcon']
      ..dpsRating = map['dpsRating']
      ..dpsRatingIcon = map['dpsRatingIcon']
      ..supportRating = map['supportRating']
      ..supportRatingIcon = map['supportRatingIcon'];

    players.add(player);
  }

  return players;
}