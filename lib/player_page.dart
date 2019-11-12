import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'localstorage.dart';
import 'player.dart';

import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';


LocalStorage localStorage = new LocalStorage();


class PlayerPage extends StatefulWidget {
  Function setDarkTheme;
  PlayerPage(this.setDarkTheme);
  @override
  createState() => new PlayerPageState();
}

class PlayerPageState extends State<PlayerPage> {
  BuildContext scaffoldContext;
  SharedPreferences prefs;
  List<Player> _playerList = [];

  bool _isBusy;
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
      if (contents != null) _playerList = fromJson(contents);
      //String contents = '[{"battletag":"Kala30#1473"}]';

      setState(() {});

      //await _refreshList();
      _refreshIndicatorKey.currentState.show();

    } catch (e) {
      debugPrint('_initList(): ' + e.toString());
    }
  }

  Future<void> _refreshList() async {

    _isBusy = true;

    /*var dataList = List.from(_playerList);
    _playerList = [];

    if (dataList == null || dataList.length == 0) {
      setState(() {
        _isLoading = false;
      });
      return;
    }*/

    for (int i = 0; i < _playerList.length; i++) {
      await _fetchData(_playerList[i], alwaysAdd: true, index: i);
    }

    _isBusy = false;

    /*Player testPlayer = new Player("B.O.B.", "pc", "us")
      ..level = 100
      ..icon = "https://d15f34w2p8l1cc.cloudfront.net/overwatch/efb3fa31f0c7a141928da914bc566753aaeb80c07067c10ee8d9a52ed28e4176.png"
      ..endorsement = 4
      ..gamesWon = 2
      ..rating = 4000
      ..ratingIcon = "https://d1u1mce87gyfbn.cloudfront.net/game/rank-icons/rank-PlatinumTier.png";


    _fetchData(testPlayer, alwaysAdd: true);*/
  }


  @override
  Widget build(BuildContext context) {
    return buildHome();
  }

  Widget buildHome() {
    return new Scaffold(
        appBar: new AppBar(title: new Text('OverWidget', style: TextStyle(fontFamily: 'GoogleSans', color: Theme.of(context).accentColor) ), actions: <Widget>[
          IconButton(icon: Icon(Icons.sort), onPressed: _promptSortBy),
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'darkTheme':
                  widget.setDarkTheme(prefs.getBool('darkTheme'));
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                  value: 'darkTheme',
                  child: IgnorePointer(child: SwitchListTile(
                      dense: true,
                      title: Text("Dark Theme"),
                      value: prefs.getBool('darkTheme'),
                      onChanged: (value) {},
                      activeColor: Theme.of(context).accentColor
                  ))
              )
            ],
          )
        ]),
        body: new Builder(builder: (BuildContext context) {
          scaffoldContext = context;
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
            itemCount: _playerList.length,
            itemBuilder: (context, index) {
              return _buildItem(_playerList[index], index);
        })
    );
  }

  Widget _buildItem(Player player, int index) {
    return Dismissible(
        background: Container(
          color: Colors.red,
        ),
        key: Key(_playerList[index].name),
        onDismissed: (direction) {
          List<Player> playerList = new List.from(_playerList);
          Scaffold.of(scaffoldContext).showSnackBar(SnackBar(
            content: Text("Removed ${player.name}"),
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

          _removeItem(index);
        },
        child: new ListTile(
            title: new Text(player.name),
            leading: new Container(
                height: 64,
                width: 64,
                child: new FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: player.icon,
                    fadeInDuration: Duration(milliseconds: 100),
                    fit: BoxFit.contain)),
            subtitle: new Text('Level ${player.level}\n' +
                (player.gamesWon > 0 ? '${player.gamesWon} games won' : '')),
            trailing: new Column(children: <Widget>[
              Container(
                  height: 40,
                  width: 40,
                  child: player.ratingIcon != '' ? FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: player.ratingIcon,
                      fadeInDuration: Duration(milliseconds: 100))
                      : Image.memory(kTransparentImage)
              ),
              Text(player.rating > 0 ? '${player.rating}' : '')
            ]),
            isThreeLine: true,
            onLongPress: () => _promptRemoveItem(index),
            onTap: () => _promptWeb(index)));
  }

  void _addItem(String battletag, String platform, String region) async {
    Scaffold.of(scaffoldContext).showSnackBar(SnackBar(
        content: Text('Adding $battletag...'),
        duration: new Duration(seconds: 1)));

    _fetchData(new Player(battletag, platform, region));
  }

  void _removeItem(int index) {
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
                    child: new Text('CANCEL'),
                    onPressed: () => Navigator.of(context).pop()),
                new FlatButton(
                    child: new Text('REMOVE'),
                    onPressed: () {
                      _removeItem(index);
                      Navigator.of(context).pop();
                    })
              ]);
        });
  }

  void _promptAddItem() {
    String platform = "pc";
    String battletag;
    if (!_isBusy) {
      showDialog(
          context: scaffoldContext,
          builder: (BuildContext context) {
            TextEditingController inputController = new TextEditingController();

            return new AlertDialog(
                title: new Text('Add player'),
                content: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child: Theme(
                          data: new ThemeData(
                              brightness: Theme
                                  .of(context)
                                  .brightness,
                              primaryColor: Theme
                                  .of(context)
                                  .accentColor,
                              primaryColorDark: Theme
                                  .of(context)
                                  .accentColor,
                              accentColor: Theme
                                  .of(context)
                                  .accentColor),
                          child: new TextField(
                            autofocus: true,
                            //controller: inputController,
                            onChanged: (String value) {
                              battletag = value;
                            },
                            keyboardAppearance:
                            prefs.getBool('darkTheme') ? Brightness.dark : Brightness.light,
                            decoration: new InputDecoration(
                                labelText: 'Username',
                                hintText: 'Battletag#1234'),
                          ))),
                      DropdownButtonHideUnderline(child: DropdownButton(
                        items: [
                          DropdownMenuItem(value: "pc", child: Text("PC")),
                          DropdownMenuItem(value: "psn", child: Text("PSN")),
                          DropdownMenuItem(value: "xbl", child: Text("XBL")),
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
                      child: new Text('CANCEL'),
                      onPressed: () => Navigator.of(context).pop()),
                  new FlatButton(
                      child: new Text('ADD'),
                      onPressed: () {
                        _addItem(battletag, platform, "us");
                        Navigator.pop(context);
                      })
                ]);
          });
    }
  }

  void _promptWeb(int index) {
    Player player = _playerList[index];
    showDialog(
        context: scaffoldContext,
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
                    textTheme: ButtonTextTheme.accent,
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
            toolbarColor: Theme.of(scaffoldContext).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
          ));
    } catch (e) {
      debugPrint(e.toString());
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
                    textTheme: ButtonTextTheme.accent,
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

  Future<void> _fetchData(Player player, {bool alwaysAdd: false, int index: -1}) async {
    String battletag = player.name;
    String platform = player.platform;
    String region = player.region;

    try {
      String url;
      if (platform == "xbl" || platform == "psn") {
        url =
        "https://ow-api.com/v1/stats/$platform/${battletag.replaceAll('#', '-')}/profile";
      } else {
        url =
        "https://ow-api.com/v1/stats/$platform/$region/${battletag.replaceAll('#', '-')}/profile";
      }
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var map = json.decode(response.body);
        if (map['name'] != null) {
          Player player = new Player(map['name'], platform, region)
            ..level = map['prestige'] * 100 + map['level']
            ..icon = map['icon']
            ..endorsement = map['endorsement']
            ..gamesWon = map['gamesWon']
            ..rating = map['rating']
            ..ratingIcon = map['ratingIcon'];

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
      debugPrint(e.toString());
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