import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import 'localstorage.dart';
import 'player.dart';
import 'player_page.dart';
import 'news_page.dart';
import 'patch_page.dart';

void main() {
  //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  //.then((_) {
    runApp(MainApp());
  //});
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Home();
  }
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}


class HomeState extends State<Home> {

  bool isDarkTheme = false;
  SharedPreferences prefs;
  int _currentIndex = 0;
  List<Widget> _children = [];
  BuildContext scaffoldContext;

  @override
  void initState() {
    _initTheme();

    super.initState();
  }

  _initTheme() async {
    await SharedPreferences.getInstance().then((SharedPreferences sp) {
      prefs = sp;
      isDarkTheme = prefs.getBool('darkTheme');
      if (isDarkTheme == null) {
        debugPrint('Prefs not found');
        setDarkTheme(false);
      }

      setState(() {
        isDarkTheme = prefs.getBool('darkTheme');
      });

      setNavigationTheme();
    });

    _children.add(NewsPage(setDarkTheme));
    _children.add(PlayerPage(setDarkTheme));
    _children.add(PatchPage(setDarkTheme));

  }

  @override
  Widget build(BuildContext context) {

    return new MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OverWidget',
        theme: isDarkTheme
            ? ThemeData(
              brightness: Brightness.dark,
              accentColor: Colors.red,)
            : ThemeData(
              primaryColor: Colors.white,
              primaryColorDark: Colors.grey[300],
              accentColor: Colors.orange,
              inputDecorationTheme: new InputDecorationTheme(
                  labelStyle: new TextStyle(color: Colors.orange),
                  border: new UnderlineInputBorder(
                      borderSide: new BorderSide(
                          color: Colors.orange, style: BorderStyle.solid)))),
        home: buildScaffold()
    );
  }


  Widget buildScaffold() {

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar: new Builder(builder: (BuildContext context) {
        return BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(
              icon: new Icon(Icons.home),
              title: new Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.account_circle),
              title: new Text('Stats'),
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.new_releases),
                title: Text('Patch Notes')
            )
          ],
          selectedItemColor: Theme.of(context).accentColor,
        );
      }),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }


  void setDarkTheme(bool value) {
    setState(() {
      isDarkTheme = value;
    });
    prefs.setBool('darkTheme', value);

    setNavigationTheme();
  }

  void setNavigationTheme() {
    if (isDarkTheme) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark));
    }
  }

}


