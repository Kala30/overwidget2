import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:overwidget/player_detail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:http/http.dart';

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

  final List<String> _tabs = ['OVERVIEW', 'QUICK PLAY', 'COMPETITIVE'];

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
      length: _tabs.length, // This is the number of tabs.
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          // These are the slivers that show up in the "outer" scroll view.
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                expandedHeight: 200.0,
                elevation: 0,
                actions: <Widget>[IconButton(icon: Icon(Icons.open_in_new), onPressed: _promptWeb)],
                //forceElevated: innerBoxIsScrolled, // elevated when scrolled
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(player.name,
                    style: TextStyle(fontFamily: 'GoogleSans')),
                  centerTitle: true,
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    alignment: Alignment.center,
                    child: Container(
                        height: 84,
                        width: 84,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: new FadeInImage.memoryNetwork(
                                placeholder: kTransparentImage,
                                image: player.icon,
                                fadeInDuration: Duration(milliseconds: 100),
                                fit: BoxFit.cover)
                        )
                    ),
                  )
                )
              ),
            ),
            SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(TabBar(
                  labelColor: Theme.of(context).accentColor,
                  labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  unselectedLabelColor: Theme.of(context).hintColor,
                  tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                ))),
          ];
        },
        body: TabBarView(
          children: _tabs.map((String name) {
            return SafeArea(
              top: false,
              bottom: false,
              child: Builder(
                builder: (BuildContext context) { // need Builder for context
                  return CustomScrollView(
                    // Remember scroll position when
                    // the tab view is not on the screen
                    key: PageStorageKey<String>(name),
                    slivers: <Widget>[
                      SliverOverlapInjector(
                        // This is the flip side of the SliverOverlapAbsorber above.
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(12),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(_buildContentList(name)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildContentList(String key) {
    // Loading
    if (_isLoading)
      return <Widget> [ Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: new CircularProgressIndicator())
      )];
    // Private
    else if (_profIsPrivate) {
      return <Widget>[ Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 32),
              child: Icon(Icons.lock, size: 48,)
            ),
            Padding(
                padding: EdgeInsets.all(8),
                child: Text('Private Profile',
                    style: TextStyle(color: Theme
                        .of(context)
                        .hintColor))
            )
          ])
      ];
    } else {
      if (key == _tabs[1])
        return _buildHeroList(_playerDetail.qpHeroes);
      else if (key == _tabs[2])
        return _buildHeroList(_playerDetail.compHeroes);
      else
        return _overviewList();
    }
  }

  List<Widget> _overviewList() {
    return  <Widget>[
          _buildSrRow(),
      Card(
          margin: EdgeInsets.all(12),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _buildItem(player.level.toString(), 'Level'),
                      _buildItem(player.gamesWon.toString(), 'Games Won'),
                      _buildItem(player.endorsement.toString(), 'Endorsement')
                    ]),
                
              ])),
          Card(
            margin: EdgeInsets.all(12),
              child: Column(
                  //mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    Padding(padding:EdgeInsets.only(top: 12, left: 12),child: Text('Quick Play')),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildItem(_playerDetail.qpGamesPlayed.toString(), 'Games Played'),
                          _buildItem(_playerDetail.qpGamesWon.toString(), 'Games Won'),
                          _buildItem(_playerDetail.qpTimePlayed.toString(), 'Time Played')
                    ]),

                    Padding(padding:EdgeInsets.only(top: 12, left: 12),child: Text('Competitive')),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _buildItem(_playerDetail.compWinRate.toString()+'%', 'Win Rate'),
                          _buildItem(_playerDetail.compGamesPlayed.toString(), 'Games Played'),
                          _buildItem(_playerDetail.compGamesWon.toString(), 'Games Won'),

                    ]),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _buildItem(_playerDetail.compTimePlayed.toString(), 'Time Played')
                        ]),

              ]))
        ];
  }

  List<Widget> _buildHeroList(List<OwHero> heroList) {
    List<Widget> widgets = [];
    heroList.sort((a, b) {
      return b.compareTo(a);
    });

    int maxHero = heroList[0].getDuration().inSeconds;
    for (OwHero hero in heroList) {
      widgets.add(_buildHeroCard(hero, hero.getDuration().inSeconds/maxHero));
    }
    return widgets;
  }

  /*Widget _buildHeroCard(OwHero hero) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              Padding(padding:EdgeInsets.only(top: 12, left: 12),child: Text(hero.fixName())),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildItem(hero.fixTime(), 'Time Played'),
                    _buildItem(hero.winPercentage.toString()+'%', 'Win Rate'),
                    _buildItem(hero.gamesWon.toString(), 'Games Won')
                  ]
              ),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildItem(hero.weaponAccuracy.toString()+'%', 'Weapon Acc'),
                    _buildItem(hero.eliminationsPerLife.toString(), 'Elims/Life'),
                    _buildItem(hero.objectiveKills.toString(), 'Obj Kills')
                  ]
              )

            ])
      )
    );
  }*/

  Widget _buildHeroCard(OwHero hero, double percent) {
    return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.all(6),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(hero.getIconUrl(), height: 64,),
              Expanded(child:
                Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 8, right: 8),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [Text(hero.fixName()), Text(hero.fixTime())]
                          )),
                      Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(hero.color),
                              backgroundColor: Theme.of(context).splashColor,
                              value: percent
                          )
                      )
                    ]
          ))
        ])
    );
  }

  Widget _buildItem(String title, String subtitle) {
    return Column(
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
        ]);
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

    return Padding(
        padding: EdgeInsets.only(top: 12, bottom: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ratings)
    );
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


  void _promptWeb() {

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new SimpleDialog(
              title: new Text('Open in Browser'),
              contentPadding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
              children: <Widget>[
                new SimpleDialogOption(
                    onPressed: () {
                      _launchURL(
                          'https://playoverwatch.com/career/${player.platform}/${player.name.replaceAll('#', '-')}');
                      Navigator.pop(context);
                    },
                    child: Row(children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.open_in_new)),
                      Text('PlayOverwatch')
                    ])),
                new SimpleDialogOption(
                    onPressed: () {
                      _launchURL(
                          'https://overbuff.com/players/${player.platform}/${player.name.replaceAll('#', '-')}');
                      Navigator.pop(context);
                    },
                    child: Row(children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.open_in_new)),
                      Text('Overbuff')
                    ])),
                new SimpleDialogOption(
                    onPressed: () {
                      _launchURL(
                          'https://overwatchtracker.com/profile/${player.platform}/global/${player.name.replaceAll('#', '-')}');
                      Navigator.pop(context);
                    },
                    child: Row(children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.open_in_new)),
                      Text('Tracker Network')
                    ])),
                new SimpleDialogOption(
                    onPressed: () {
                      _launchURL(
                          'https://masteroverwatch.com/profile/${player.platform}/global/${player.name.replaceAll('#', '-')}');
                      Navigator.pop(context);
                    },
                    child: Row(children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.open_in_new)),
                      Text('Master Overwatch')
                    ])),
                Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 4.0),
                  child: FlatButton(
                    textTheme: ButtonTextTheme.normal,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("CANCEL"),
                  ),
                )
              ]);
        });
  }

  void _launchURL(final String url) async {
    try {
      await launch(url,
          option: new CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
          ));
    } catch (e) {
      debugPrint(e.toString());
    }
  }


  Future<void> _fetchData(Player player) async {
    String battletag = player.name;
    String platform = player.platform;

    setState(() {
      _isLoading = true;
    });

    try {
      String url;
      url = "https://ow-api.com/v2/stats/$platform/${battletag.replaceAll('#', '-')}/complete";
      var fetchedFile = await CustomCacheManager().getSingleFile(url);

      // Get hero colors from CSS
      var client = Client();
      Response colorResponse = await client.get('https://static.playoverwatch.com/app-53478582a8.css');

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

          _playerDetail = new PlayerDetail(
            compGamesPlayed: map['competitiveStats']['games']['played'],
            compGamesWon: map['competitiveStats']['games']['won'],
            compTimePlayed: map['competitiveStats']['careerStats']['allHeroes']['game']['timePlayed'],
            qpGamesPlayed: map['quickPlayStats']['games']['played'],
            qpGamesWon: map['quickPlayStats']['games']['won'],
            qpTimePlayed: map['quickPlayStats']['careerStats']['allHeroes']['game']['timePlayed']
          );

          if (map['quickPlayStats']['topHeroes'] != null) {
            map['quickPlayStats']['topHeroes'].forEach((key, value) {
              OwHero hero = OwHero.fromMap(value);
              hero.name = key;
              hero.setColor(colorResponse.body);
              _playerDetail.qpHeroes.add(hero);
            });
          }

          if (map['competitiveStats']['topHeroes'] != null) {
            map['competitiveStats']['topHeroes'].forEach((key, value) {
              OwHero hero = OwHero.fromMap(value);
              hero.name = key;
              hero.setColor(colorResponse.body);
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
