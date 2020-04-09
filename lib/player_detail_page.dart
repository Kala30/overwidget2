import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:overwidget/player_detail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

import 'player.dart';

class PlayerDetailPage extends StatefulWidget {
  final Player player;

  PlayerDetailPage({Key key, @required this.player}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PlayerDetailState(player: player);
  }
}

class PlayerDetailState extends State<PlayerDetailPage> {
  PlayerDetailState({Key key, @required this.player}) : super();

  bool _isLoading = true;
  bool _profIsPrivate = false;

  BuildContext _scaffoldContext;
  final Player player;
  PlayerDetail _playerDetail;

  @override
  void initState() {
    _fetchData(player);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
              floating: false,
              pinned: true,
              expandedHeight: 200,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                  title: Text(player.name,
                      style: TextStyle(fontFamily: 'GoogleSans')),
                  centerTitle: true,
                  collapseMode: CollapseMode.pin,
                  background: Container(
                      alignment: Alignment.center,
                      child: Container(
                          width: 84,
                          height: 84,
                          child: CircleAvatar(backgroundImage: NetworkImage(player.icon)))))
              ),
          SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(TabBar(
                labelColor: Theme.of(context).accentColor,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelColor: Theme.of(context).hintColor,
                tabs: <Widget>[
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'QUICK PLAY'),
                  Tab(text: 'COMPETITIVE')
                ],
              ))),
          SliverFillRemaining(
              child: new Builder(builder: (BuildContext context) {
            if (_isLoading)
              return new Center(child: new CircularProgressIndicator());
            else if (_profIsPrivate)
              return new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.lock,
                      size: 48,
                    ),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Private Profile',
                          style: TextStyle(color: Theme.of(context).hintColor))
                    )
                  ]);
            else
              return _buildContent();
          }))
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      children: <Widget>[
        _overviewTab(),
        _buildHeroList(_playerDetail.qpHeroes),
        _buildHeroList(_playerDetail.compHeroes)
    ]);
  }

  Widget _overviewTab() {
    return Padding(
        padding: EdgeInsets.only(top: 24, bottom: 24),
        child: Column(children: <Widget>[
          _buildSrRow(),
          Card(
              margin: EdgeInsets.only(left: 12, right: 12, top: 32, bottom: 12),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(padding:EdgeInsets.only(top: 12, left: 12),child: Text('Quick Play')),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildItem(_playerDetail.qpGamesPlayed.toString(), 'Games Played'),
                          _buildItem(_playerDetail.qpGamesWon.toString(), 'Games Won'),
                          _buildItem(_playerDetail.qpTimePlayed.toString(), 'Time Played')
                    ]),

                    Padding(padding:EdgeInsets.only(top: 12, left: 12),child: Text('Competitive')),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildItem(_playerDetail.compGamesPlayed.toString(), 'Games Played'),
                          _buildItem(_playerDetail.compGamesWon.toString(), 'Games Won'),
                          _buildItem(_playerDetail.compTimePlayed.toString(), 'Time Played')
                    ]
                )
              ]))
        ]));
  }

  Widget _buildHeroList(List<OwHero> heroList) {
    /*List<Widget> widgets = [];
    for (OwHero hero in heroList) {
      widgets.add(_buildHeroCard(hero));
    }
    return Column(children: widgets);*/
    return ListView.builder(
        itemBuilder: (context, index) {
          return _buildHeroCard(heroList[index]);
        }
    );
  }

  Widget _buildHeroCard(OwHero hero) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(hero.name)
      )
    );
  }

  Widget _buildItem(String title, String subtitle) {
    return Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          Padding(
              padding: EdgeInsets.only(left: 12, right: 12, top: 12),
              child: Text(title, style: Theme.of(context).textTheme.headline6, textScaleFactor: 0.9,)),
          Padding(
              padding: EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
              child: Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor)))
        ]));
  }

  Widget _buildSrRow() {
    List<Widget> ratings = [];

    if (player.tankRating != null && player.tankRating > 0)
      ratings.add(_buildSR(player.tankRating, player.tankRatingIcon, 'TANK'));
    if (player.dpsRating != null && player.dpsRating > 0)
      ratings.add(_buildSR(player.dpsRating, player.dpsRatingIcon, 'DAMAGE'));
    if (player.supportRating != null && player.supportRating > 0)
      ratings.add(
          _buildSR(player.supportRating, player.supportRatingIcon, 'SUPPORT'));

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ratings);
  }

  Widget _buildSR(int rating, String iconUrl, String role) {
    return new Column(children: <Widget>[
      Container(
          height: 58,
          width: 58,
          child: iconUrl != '' && iconUrl != null
              ? FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: iconUrl,
                  fadeInDuration: Duration(milliseconds: 100))
              : Image.memory(kTransparentImage)),
      Text(role,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
      Text(rating != null && rating > 0 ? rating.toString() : '',
          style: Theme.of(context).textTheme.headline5),
    ]);
  }

  Future<void> _fetchData(Player player) async {
    String battletag = player.name;
    String platform = player.platform;
    String region = player.region;

    setState(() {
      _isLoading = true;
    });

    try {
      String url;
      url = "https://ow-api.com/v2/stats/$platform/${battletag.replaceAll('#', '-')}/complete";

      var fetchedFile = await CustomCacheManager().getSingleFile(url);

      if (fetchedFile != null) {
        var map = json.decode(await fetchedFile.readAsString());

        if (map['private'] != null && map['private'] == true) {
          // Private Profile
          setState(() {
            _isLoading = false;
            _profIsPrivate = true;
          });
          return;
        } else if (map['name'] != null) {
          // Public Profile

          _playerDetail = new PlayerDetail()
            ..compGamesPlayed = map['competitiveStats']['games']['played']
            ..compGamesWon = map['competitiveStats']['games']['won']
            ..compTimePlayed = map['competitiveStats']['careerStats']['allHeroes']['game']['timePlayed']
            ..qpGamesPlayed = map['quickPlayStats']['games']['played']
            ..qpGamesWon = map['quickPlayStats']['games']['won']
            ..qpTimePlayed = map['quickPlayStats']['careerStats']['allHeroes']['game']['timePlayed'];

          if (map['quickPlayStats']['topHeroes'] != null) {
            map['quickPlayStats']['topHeroes'].forEach((key, value) {
              OwHero hero = OwHero.fromMap(value);
              hero.name = key;
              _playerDetail.qpHeroes.add(hero);
            });
          }

          if (map['competitiveStats']['topHeroes'] != null) {
            map['competitiveStats']['topHeroes'].forEach((key, value) {
              OwHero hero = OwHero.fromMap(value);
              hero.name = key;
              _playerDetail.compHeroes.add(hero);
            });
          }

          setState(() {
            _isLoading = false;
            _profIsPrivate = false;
          });

          return;
        } else {
          Scaffold.of(context).showSnackBar(
              SnackBar(content: Text('Unable to find $battletag')));
        }
      } else {
        // Other status code
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text('Player not found')));
      }
    } catch (e) {
      debugPrint(e.toString());
      if (context != null)
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Network Error')));
    }

    if (context != null) {
      setState(() {
        _isLoading = false;
        _profIsPrivate = true;
      });
    }

  }
}

// Delegate for custom TabBar Sliver
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(
      child: AppBar(flexibleSpace: _tabBar, automaticallyImplyLeading: false)
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class CustomCacheManager extends BaseCacheManager {

  static const key = "playerDetailCache";

  static CustomCacheManager _instance;

  factory CustomCacheManager() {
    if (_instance == null) {
      _instance = new CustomCacheManager._();
    }
    return _instance;
  }

  CustomCacheManager._() : super(key,
      maxAgeCacheObject: Duration(minutes: 10),
      maxNrOfCacheObjects: 20);

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return path.join(directory.path, key);
  }

}
