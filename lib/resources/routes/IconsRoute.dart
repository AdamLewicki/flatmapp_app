import 'package:flatmapp/resources/objects/loaders/icons_loader.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

class IconsRoute extends StatelessWidget {
  final IconsLoader icons = IconsLoader();
  Widget _iconCard(context, key) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 60.0,
        // icon change button
        child: Container(
            decoration: buttonFieldStyle(),
            child: ConstrainedBox(
                constraints: BoxConstraints.expand(),
                child: FlatButton(
                  onPressed: () {
                    // set selected marker id for map screen
                    PrefService.setString('selected_icon', key);
                    // Navigate back
                    Navigator.pop(context);

                  },
                  padding: EdgeInsets.all(0.0),
                  child: Image.asset(icons.markerImageLocal[key]),
                ))),
      ),
    );
  }

  Widget _iconsGridView(BuildContext context) {
    return GridView.builder(
      gridDelegate:
          new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
      itemCount: icons.markerImageLocal.length,
      itemBuilder: (context, index) {
        return _iconCard(context, icons.markerImageLocal.keys.elementAt(index));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Choose icon for marker'),
      body:
          // BODY
          _iconsGridView(context),
      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}
