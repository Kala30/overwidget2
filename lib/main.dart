import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'localstorage.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocalStorage localStorage = new LocalStorage();

void main() async {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new PlayerListView();
  }
}

class PlayerListView extends StatefulWidget {
  @override
  createState() => new PlayerListViewState();
}

class PlayerListViewState extends State<PlayerListView> {
  BuildContext scaffoldContext;
  SharedPreferences prefs;
  List<Map> _playerList = [];
  List<dynamic> _dataList = [];

  bool _isDarkTheme = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _initList();
  }

  _initList() async {

    await SharedPreferences.getInstance().then((SharedPreferences sp) {
      prefs = sp;
      _isDarkTheme = prefs.getBool('darkTheme');
      if (_isDarkTheme == null) {
        print('Prefs not found');
        setDarkTheme(false);
      }
      setState(() {
        _isDarkTheme = prefs.getBool('darkTheme');
      });
    });

    try {
      //localStorage.clearFile();
      String contents = await localStorage.readFile();

      //String contents = '[{"battletag":"Kala30#1473"}]';
      _dataList = json.decode(contents);

      if (_dataList != null) {
        for (Map player in _dataList) {
          await _fetchData(player['battletag']);
        }
      }
    } catch (e) {
      print(e.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  void setDarkTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
    });
    prefs.setBool('darkTheme', value);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'OverWidget',
        theme: _isDarkTheme
            ? ThemeData(
                brightness: Brightness.dark,
                accentColor: Colors.red,
              )
            : ThemeData(
                primaryColor: Colors.white,
                primaryColorDark: Colors.grey[300],
                accentColor: Colors.orange,
                inputDecorationTheme: new InputDecorationTheme(
                    labelStyle: new TextStyle(color: Colors.orange),
                    border: new UnderlineInputBorder(
                        borderSide: new BorderSide(
                            color: Colors.orange, style: BorderStyle.solid)))),
        home: buildHome());
  }

  Widget buildHome() {
    return new Scaffold(
        appBar: new AppBar(title: new Text('OverWidget'), actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'darkTheme':
                  setDarkTheme(!_isDarkTheme);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  CheckedPopupMenuItem(
                    checked: _isDarkTheme,
                    value: 'darkTheme',
                    child: Text('Dark Theme'),
                  )
                ],
          )
        ]),
        body: _isLoading
            ? new Center(child: new CircularProgressIndicator())
            : new Builder(builder: (BuildContext context) {
                scaffoldContext = context;
                return _buildList();
              }),
        floatingActionButton: new FloatingActionButton(
            onPressed: _promptAddItem,
            tooltip: 'Add player',
            child: new Icon(Icons.add)));
  }

  Widget _buildList() {
    return new ListView.builder(itemBuilder: (context, index) {
      if (index < _playerList.length) {
        return _buildItem(_playerList[index], index);
      }
    });
  }

  Widget _buildItem(Map map, int index) {
    int level = map['prestige'] * 100 + map['level'];

    return new ListTile(
        title: new Text(map["name"]),
        leading: new Container(
            height: 64,
            width: 64,
            child: new Image.network(map["icon"], fit: BoxFit.contain)),
        subtitle: new Text('Level $level\n${map["gamesWon"]} games won'),
        trailing: new Column(children: <Widget>[
          Container(
              height: 48, width: 48, child: Image.network(map['ratingIcon'])),
          Text('${map['rating']} SR')
        ]),
        isThreeLine: true,
        onLongPress: () => _promptRemoveItem(index),
        onTap: () => _promptWeb(index));
  }

  void _addItem(String battletag) async {
    Scaffold.of(scaffoldContext).showSnackBar(SnackBar(
        content: Text('Adding $battletag...'),
        duration: new Duration(seconds: 1)));

    var map = await _fetchData(battletag);
    if (map != null && map['name'] != null) {
      var player = {'battletag': map['name'], 'platform': 'pc', 'region': 'us'};
      _dataList.add(player);
      print(_dataList);
      localStorage.writeFile(json.encode(_dataList));
    }
  }

  void _removeItem(int index) {
    setState(() => _playerList.removeAt(index));
    _dataList.removeAt(index);
    localStorage.writeFile(json.encode(_dataList));
  }

  void _promptRemoveItem(int index) {
    showDialog(
        context: scaffoldContext,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text('Remove ${_playerList[index]["name"]}?'),
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
    showDialog(
        context: scaffoldContext,
        builder: (BuildContext context) {
          TextEditingController inputController = new TextEditingController();

          return new AlertDialog(
              title: new Text('Add player'),
              content: new Theme(
                  data: new ThemeData(
                    brightness: Theme.of(context).brightness,
                    primaryColor: Theme.of(context).accentColor,
                    primaryColorDark: Theme.of(context).accentColor,
                    accentColor: Theme.of(context).accentColor
                  ),
                  child: new TextField(
                    autofocus: true,
                    controller: inputController,
                    onSubmitted: (val) {
                      _addItem(val);
                      Navigator.of(context).pop();
                    },
                    decoration: new InputDecoration(
                        labelText: 'Username', hintText: 'Battletag#1234'),
                  )),
              actions: <Widget>[
                new FlatButton(
                    child: new Text('CANCEL'),
                    onPressed: () => Navigator.of(context).pop()),
                new FlatButton(
                    child: new Text('ADD'),
                    onPressed: () {
                      _addItem(inputController.text);
                      Navigator.pop(context);
                    })
              ]);
        });
  }

  void _promptWeb(int index) {
    Map profile = _dataList[index];
    showDialog(
        context: scaffoldContext,
        builder: (BuildContext context) {
          return new SimpleDialog(
              title: new Text('Open in Browser'),
              children: <Widget>[
                new SimpleDialogOption(
                    onPressed: () {
                      _launchURL(
                          'https://playoverwatch.com/career/${profile['platform']}/${profile['battletag'].replaceAll('#', '-')}');
                      Navigator.pop(context);
                    },
                    child: new Text('PlayOverwatch')),
                new SimpleDialogOption(
                    onPressed: () {
                      _launchURL(
                          'https://overbuff.com/players/${profile['platform']}/${profile['battletag'].replaceAll('#', '-')}');
                      Navigator.pop(context);
                    },
                    child: new Text('Overbuff')),
                new SimpleDialogOption(
                    onPressed: () {
                      _launchURL(
                          'https://overwatchtracker.com/profile/${profile['platform']}/global/${profile['battletag'].replaceAll('#', '-')}');
                      Navigator.pop(context);
                    },
                    child: new Text('Tracker Network')),
                new SimpleDialogOption(
                    onPressed: () {
                      _launchURL(
                          'https://masteroverwatch.com/profile/${profile['platform']}/global/${profile['battletag'].replaceAll('#', '-')}');
                      Navigator.pop(context);
                    },
                    child: new Text('Master Overwatch')),
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

  Future _fetchData(String battletag) async {
    try {
      final url =
          "https://ow-api.com/v1/stats/pc/us/${battletag.replaceAll('#', '-')}/profile";
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var map = json.decode(response.body);
        if (map['name'] != null) {
          setState(() => _playerList.add(map));
          return map;
        } else {
          Scaffold.of(scaffoldContext)
              .showSnackBar(SnackBar(content: Text('Player not found')));
          return null;
        }
      }
    } catch (e) {
      Scaffold.of(scaffoldContext)
          .showSnackBar(SnackBar(content: Text('Network Error')));
    }
  }
}
