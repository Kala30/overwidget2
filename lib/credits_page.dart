import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_html/flutter_html.dart';

class CreditsPage extends StatefulWidget {
  @override
  createState() => new CreditsPageState();
}

class CreditsPageState extends State<CreditsPage> {

  String _htmlData = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Credits')),
        body: SingleChildScrollView(
            child: Html(data: _htmlData,
              onLinkTap: (url) {
                launch(url, option: CustomTabsOption(toolbarColor: Theme.of(context).primaryColor));
              }
            )
        )
    );
  }

  Future<void> _initData() async {
    _htmlData = await rootBundle.loadString('assets/credits.html');
    setState(() {});
  }

}