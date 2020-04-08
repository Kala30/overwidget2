import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

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
  final Player player;

  PlayerDetailState({Key key, @required this.player}) : super();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          body: new CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                  floating: false,
                  pinned: true,
                  expandedHeight: 200,
                  flexibleSpace: FlexibleSpaceBar(
                      title: Text(player.name,
                          style: TextStyle(fontFamily: 'GoogleSans')),
                      collapseMode: CollapseMode.pin,
                      background: new Padding(
                          padding: EdgeInsets.all(84),
                          child: Container(
                              height: 64,
                              width: 64,
                              child: new FadeInImage.memoryNetwork(
                                  placeholder: kTransparentImage,
                                  image: player.icon,
                                  fadeInDuration: Duration(milliseconds: 100),
                                  fit: BoxFit.contain)))
                  )
              ),
              SliverFillRemaining(
                child: _buildContent()
              )
            ],
          ),
        );
  }

  Widget _buildContent() {
    return Padding(
        padding: EdgeInsets.all(16),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
          _buildSR(player.tankRating, player.tankRatingIcon),
          _buildSR(player.dpsRating, player.dpsRatingIcon),
          _buildSR(player.supportRating, player.supportRatingIcon)
        ]));
  }

  Widget _buildSR(int rating, String iconUrl) {
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
      Text(rating != null && rating > 0 ? rating.toString() : '',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
    ]);
  }
}
