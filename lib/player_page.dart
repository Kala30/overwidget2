import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:convert';
import 'dart:async';
import 'package:overwidget/player_detail_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'localstorage.dart';
import 'player.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

LocalStorage localStorage = new LocalStorage();

class PlayerPage extends StatefulWidget {
  final PopupMenuButton popupMenu;
  PlayerPage(this.popupMenu);
  @override
  createState() => new PlayerPageState();
}

class PlayerPageState extends State<PlayerPage> {
  BuildContext scaffoldContext;
  SharedPreferences prefs;
  List<Player> _playerList = [];

  bool _isBusy = true;
  bool _initFetch = true;
  int _sortBy = 0;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((SharedPreferences sp) {
      prefs = sp;

      _sortBy = prefs.getInt('sortBy');
      if (_sortBy == null) {
        _sortBy = 0;
        prefs.setInt('sortBy', _sortBy);
      }
    });

    _initList();
  }

  _initList() async {
    try {
      //localStorage.clearFile();
      String contents = await localStorage.readFile();
      if (contents != null)
        _playerList = fromJson(contents);


      setState(() {});

      await _refreshIndicatorKey.currentState.show();
      setState(() {
        _isBusy = false;
      });
      _initFetch = false;

    } catch (e) {
      debugPrint('_initList(): ' + e.toString());
    }
  }

  Future _refreshList() async {

    setState(() {
      _isBusy = true;
    });

    for (int i = 0; i < _playerList.length; i++) {
      await _fetchData(_playerList[i], alwaysAdd: true, index: i);
    }

    setState(() {
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildHome();
  }

  Widget buildHome() {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text('OverWidget',
                style: TextStyle(
                    fontFamily: 'GoogleSans',
                    color: Theme.of(context).accentColor)),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.sort), onPressed: _promptSortBy),
              widget.popupMenu
            ]),
        body: new Builder(builder: (BuildContext context) {
          scaffoldContext = context;
          if (!_isBusy && _playerList.length==0) {
            return Center(child:Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, size: 48),
                  Padding(
                    child: Text("Tap '+' to add a player"),
                    padding: EdgeInsets.all(12),
                  )
                ]
            ));
          }
          return _buildList();
        }),
        floatingActionButton: new FloatingActionButton(
            onPressed: _promptAddItem,
            tooltip: 'Add player',
            child: new Icon(Icons.add)));
  }

  Widget _buildList() {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshList,
        child: ListView.builder(
            itemCount: _playerList.length + 1,
            itemBuilder: (context, index) {
              if (index >= _playerList.length)
                return Container(height: 64);
              return _buildItem(_playerList[index], index);
            }));
  }

  Widget _buildItem(Player player, int index) {
    return AbsorbPointer(
      absorbing: _isBusy,
        child: Dismissible(
            background: Container(
                color: Colors.red,
              alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(12),
                    child: Icon(Icons.delete, size: 36)
                )
              ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
                child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.delete, size: 36)
                )
            ),
            key: Key(_playerList[index].name),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              _removeItem(index);
              },
            child: _buildTile(player, index)
        )
    );
  }

  Widget _buildTile(Player player, int index) {
    return new ListTile(
        title: new Text(player.name,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        leading: Container(
            height: 54,
            width: 54,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: new FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: player.icon,
                    fadeInDuration: Duration(milliseconds: 100),
                    fit: BoxFit.cover)
            )
        ),
        subtitle: new Text(
            'Level ${player.level}\n' +
                (player.gamesWon > 0 ? '${player.gamesWon} games won' : ''),
            style: TextStyle(fontSize: 16)),
        trailing: _buildSR(player.rating, player.ratingIcon),
        isThreeLine: true,
        onLongPress: () => _promptRemoveItem(index),
        //onTap: () => _promptWeb(index)
        onTap: () {
          Navigator.push(
            context,
            new MaterialPageRoute(
                builder: (context) =>
                    Scaffold(body: PlayerDetailPage(player: player))),
          );
        });
  }

  Widget _buildSR(int rating, String iconUrl) {
    return new Column(children: <Widget>[
      Container(
          height: 35,
          width: 35,
          child: iconUrl != '' && iconUrl != null
              ? FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: iconUrl,
                  fadeInDuration: Duration(milliseconds: 100))
              : Image.memory(kTransparentImage)),
      Text(rating != null && rating > 0 ? '$rating' : '',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
    ]);
  }

  void _addItem(String battletag, String platform, String region) async {
    Scaffold.of(scaffoldContext).showSnackBar(SnackBar(
        content: Text('Adding $battletag...'),
        duration: new Duration(seconds: 1)));

    _fetchData(new Player(battletag, platform, region));
  }

  void _removeItem(int index) {
    List<Player> playerList = new List.from(_playerList);
    Scaffold.of(scaffoldContext).showSnackBar(SnackBar(
      content: Text("Removed ${_playerList[index].name}"),
      duration: new Duration(seconds: 5),
      action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _playerList = playerList;
            });
            localStorage.writeFile(toJson(_playerList));
          }),
    ));

    setState(() => _playerList.removeAt(index));
    localStorage.writeFile(toJson(_playerList));
  }

  void _sortList() {
    if (_sortBy == 1) {
      // 1 = LEVEL
      setState(() {
        _playerList.sort((a, b) {
          return b.level.compareTo(a.level);
        });
      });
    } else if (_sortBy == 2) {
      // 2 = SR
      setState(() {
        _playerList.sort((a, b) {
          return b.rating.compareTo(a.rating);
        });
      });
    } else {
      // 0 = NAME
      setState(() {
        _playerList.sort((a, b) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      });
    }
  }

  void _promptRemoveItem(int index) {
    showDialog(
        context: scaffoldContext,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text('Remove ${_playerList[index].name}?'),
              actions: <Widget>[
                new FlatButton(
                    textTheme: ButtonTextTheme.normal,
                    child: new Text('CANCEL'),
                    onPressed: () => Navigator.of(context).pop()),
                new FlatButton(
                    textTheme: ButtonTextTheme.accent,
                    child: new Text('REMOVE'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _removeItem(index);
                    })
              ]);
        });
  }

  void _promptAddItem() {
    String platform = 'pc';
    String battletag;

    if (!_isBusy) {
      showDialog(
          context: scaffoldContext,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return Theme(
                  data: new ThemeData(
                      brightness: Theme.of(context).brightness,
                      primaryColor: Theme.of(context).accentColor,
                      primaryColorDark: Theme.of(context).accentColor,
                      accentColor: Theme.of(context).accentColor),
                  child: new AlertDialog(
                      title: new Text('Add player'),
                      content: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                                child: new TextField(
                              autofocus: true,
                              //controller: inputController,
                              onChanged: (String value) {
                                battletag = value;
                              },
                              keyboardAppearance: prefs.getBool('darkTheme')
                                  ? Brightness.dark
                                  : Brightness.light,
                              decoration: new InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Battletag#1234'),
                            )),
                            DropdownButtonHideUnderline(
                                child: DropdownButton(
                              items: [
                                DropdownMenuItem(
                                    value: "pc", child: Text("PC")),
                                DropdownMenuItem(
                                    value: "psn", child: Text("PS4")),
                                DropdownMenuItem(
                                    value: "xbl", child: Text("Xbox")),
                                DropdownMenuItem(
                                    value: "nintendo-switch",
                                    child: Text("Switch"))
                              ],
                              value: platform,
                              onChanged: (var text) {
                                setState(() {
                                  platform = text;
                                });
                              },
                            ))
                          ]),
                      actions: <Widget>[
                        new FlatButton(
                            textTheme: ButtonTextTheme.normal,
                            child: new Text('CANCEL'),
                            onPressed: () => Navigator.of(context).pop()),
                        new FlatButton(
                            //textTheme: ButtonTextTheme.accent,
                            child: new Text('ADD'),
                            textTheme: ButtonTextTheme.accent,
                            onPressed: () {
                              _addItem(battletag, platform, "us");
                              Navigator.pop(context);
                            })
                      ]));
            });
          });
    }
  }

  void _promptSortBy() {
    showDialog(
        context: scaffoldContext,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: new Text('Sort by'),
              contentPadding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
              children: <Widget>[
                RadioListTile(
                    title: Text('Name'),
                    value: 0,
                    groupValue: _sortBy,
                    activeColor: Theme.of(scaffoldContext).accentColor,
                    onChanged: (a) {
                      setSortBy(a);
                      Navigator.pop(context);
                    }),
                RadioListTile(
                    title: Text('Level'),
                    value: 1,
                    groupValue: _sortBy,
                    activeColor: Theme.of(scaffoldContext).accentColor,
                    onChanged: (a) {
                      setSortBy(a);
                      Navigator.pop(context);
                    }),
                RadioListTile(
                    title: Text('SR'),
                    value: 2,
                    groupValue: _sortBy,
                    activeColor: Theme.of(scaffoldContext).accentColor,
                    onChanged: (a) {
                      setSortBy(a);
                      Navigator.pop(context);
                    }),
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

  setSortBy(int order) {
    _sortBy = order;
    prefs.setInt('sortBy', _sortBy);
    _sortList();
  }

  Future<void> _fetchData(Player player,
      {bool alwaysAdd: false, int index: -1}) async {
    String battletag = player.name;
    String platform = player.platform;
    String region = player.region;

    try {
      String url;
      url =
          "https://ow-api.com/v2/stats/$platform/${battletag.replaceAll('#', '-')}/profile";

      if (!_initFetch)
        CustomCacheManager().emptyCache();

      var fetchedFile = await CustomCacheManager().getSingleFile(url);

      if (fetchedFile != null) {
        var map = json.decode(await fetchedFile.readAsString());
        if (map['name'] != null) {
          Player player = new Player(map['name'], platform, region)
            ..level = map['prestige'] * 100 + map['level']
            ..icon = map['icon']
            ..endorsement = map['endorsement']
            ..gamesWon = map['gamesWon']
            ..rating = map['rating']
            ..ratingIcon = map['ratingIcon'];

          if (map['ratings'] != null) {
            for (var role in map['ratings']) {
              switch (role['role']) {
                case 'tank':
                  {
                    player.tankRating = role['level'];
                    player.tankRatingIcon = role['rankIcon'];
                  }
                  break;

                case 'damage':
                  {
                    player.dpsRating = role['level'];
                    player.dpsRatingIcon = role['rankIcon'];
                  }
                  break;
                case 'support':
                  {
                    player.supportRating = role['level'];
                    player.supportRatingIcon = role['rankIcon'];
                  }
              }
            }
          }

          if (index == -1) {
            _playerList.add(player);
          } else {
            _playerList[index] = player;
          }
          _sortList();
          localStorage.writeFile(toJson(_playerList));

          setState(() {});

          return;
        } else {
          Scaffold.of(scaffoldContext).showSnackBar(
              SnackBar(content: Text('Unable to find $battletag')));
        }
      } else {
        Scaffold.of(scaffoldContext)
            .showSnackBar(SnackBar(content: Text('Player not found')));
      }
    } catch (e) {
      debugPrint("PlayerPage: " + e.toString());
      Scaffold.of(scaffoldContext)
          .showSnackBar(SnackBar(content: Text('Network Error')));
    }

    // Add player even if error occurs
    if (alwaysAdd == true) {
      if (index == -1) {
        _playerList.add(player);
      } else {
        _playerList[index] = player;
      }
    }
    setState(() {});
  }
}

class CustomCacheManager extends BaseCacheManager {

  static const key = "playerCache";

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
