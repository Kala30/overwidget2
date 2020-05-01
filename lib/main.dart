import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ads/ads.dart';

import 'player_page.dart';
import 'news_page.dart';
import 'patch_page.dart';

void main() {
    runApp(MainApp());
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


class HomeState extends State<Home> with WidgetsBindingObserver {

  bool isDarkTheme = false;
  SharedPreferences prefs;
  int _currentIndex = 0;
  List<Widget> _children = [];
  BuildContext scaffoldContext;
  Ads _ads;

  @override
  void initState() {
    _initTheme();

    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _ads = Ads('ca-app-pub-2622368960038346~7194445923', testing: true);
    _ads.showBannerAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _ads.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed){
      setNavigationTheme();
    }
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
              primaryColor: Color(0xFF1F1F1F),
              accentColor: Colors.redAccent,
              scaffoldBackgroundColor: Color(0xFF121212),
              cardColor: Color(0xFF1D1D1D),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.grey[100]
              ), navigationRailTheme: NavigationRailThemeData(backgroundColor: Color(0xFF1F1F1F))
            )
            : ThemeData(
              primaryColor: Colors.white,
              primaryColorDark: Colors.grey[300],
              accentColor: Colors.orangeAccent,
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.grey[900]
              ),
        ),
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
        return Padding(
          padding: EdgeInsets.only(bottom: 60),
            child: BottomNavigationBar(
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
          backgroundColor: Theme.of(context).cardColor,
        )
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
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.grey[200],
          systemNavigationBarColor: Colors.grey[200],
          systemNavigationBarIconBrightness: Brightness.dark));
    }
  }

}


