import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flatmapp/resources/objects/loaders/icons_loader.dart';

import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';


class CommunityIconsRoute extends StatelessWidget {

  final IconsLoader icons = IconsLoader();

  Widget _iconsListView(BuildContext context) {
    return ListView.builder(
      itemCount: icons.markerImageLocal.length,
      itemBuilder: (context, index) {
        String key = icons.markerImageLocal.keys.elementAt(index);
        return Card( //                           <-- Card widget
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(icons.markerImageLocal[key]),
            ),
            title: Text(
                key,
                style: bodyText()
            ),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              // set selected marker id for map screen
              PrefService.setString('community_icon', key);
              // Navigate back
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Choose icon for community'),
      body:
      // BODY
      _iconsListView(context),
      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}