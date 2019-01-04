import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'localstorage.dart';

LocalStorage localStorage = new LocalStorage();

void main() => runApp(MainApp());

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        theme: ThemeData(
            primaryColor: Colors.white,
            primaryColorDark: Colors.grey[300],
            accentColor: Colors.orange,
            inputDecorationTheme: new InputDecorationTheme(
                labelStyle: new TextStyle(color: Colors.orange),
                border: new UnderlineInputBorder(
                    borderSide: new BorderSide(
                        color: Colors.orange, style: BorderStyle.solid)))),
        home: new PlayerListView());
  }
}

class PlayerListView extends StatefulWidget {
  @override
  createState() => new PlayerListViewState();
}

class PlayerListViewState extends State<PlayerListView> {
  BuildContext scaffoldContext;
  List<Map> _playerList = [];
  List<dynamic> _dataList = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _initList();
  }

  _initList() async {
    try {
      //localStorage.clearFile();
      String contents = await localStorage.readFile();

      //String contents = '[{"battletag":"Kala30#1473"}]';
      _dataList = json.decode(contents);

      if (_dataList != null) {
        for (Map player in _dataList) {
          _fetchData(player['battletag']);
        }
      }
    } catch (e) {
      print(e.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: new Text('OverWidget')),
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
        trailing: new Text('${map['rating']} SR'),
        isThreeLine: true,
        onTap: () => _promptRemoveItem(index));
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
        context: context,
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
        context: context,
        builder: (BuildContext context) {
          TextEditingController inputController = new TextEditingController();

          return new AlertDialog(
              title: new Text('Add player'),
              content: new Theme(
                  data: new ThemeData(
                    primaryColor: Colors.orange,
                    primaryColorDark: Colors.orange,
                  ),
                  child: new TextField(
                    //autofocus: true,

                    controller: inputController,
                    onSubmitted: (val) {
                      _addItem(val);
                      Navigator.of(context).pop();
                    },
                    decoration: new InputDecoration(
                      labelText: 'BattleTag',
                    ),
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
