import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:preferences/preference_service.dart';

import 'text_styles.dart';

ListTile sideBarMenuElement(context, String name, Icon icon, String route) {
  return ListTile(
    leading: icon,
    title: Text(
      LanguagesLoader.of(context).translate(name),
      style: sideBarMenuStyle(),
    ),
    onTap: () {
      // Then close the drawer
      Navigator.pop(context);
      // Navigate to the profile screen using a named route.
      Navigator.pushNamed(context, route);
    },
  );
}

ListTile sideBarMenuElementLogin(
    context, String name, Icon icon, String route) {
  return ListTile(
    leading: icon,
    title: Text(
      LanguagesLoader.of(context).translate(name),
      style: (PrefService.getString('token') == '')
          ? sideBarMenuStyleGrey()
          : sideBarMenuStyle(),
    ),
    onTap: () {
      if (PrefService.getString('token') == '') {
        // Then close the drawer
        Navigator.pop(context);
        // go to login page
        Navigator.pushNamed(context, '/login');
        // show message
        Fluttertoast.showToast(
          msg: "You need to log in to use " + name,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        // Then close the drawer
        Navigator.pop(context);
        // Navigate to the profile screen using a named route.
        Navigator.pushNamed(context, route);
      }
    },
  );
}

Drawer sideBarMenu(context) {
  return Drawer(
    // Add a ListView to the drawer. This ensures the user can scroll
    // through the options in the drawer if there isn't enough vertical
    // space to fit everything.
    child: ListView(
      // Important: Remove any padding from the ListView.
      padding: EdgeInsets.zero,
      children: <Widget>[
        Container(
          height: 80.0,
          child: DrawerHeader(
              child: Text('', style: TextStyle(color: Colors.white)),
              decoration: BoxDecoration(color: Colors.green),
              margin: EdgeInsets.all(0.0),
              padding: EdgeInsets.all(0.0)),
        ),
        sideBarMenuElement(context, 'Map', Icon(Icons.location_on), '/map'),
        sideBarMenuElement(
            context, 'Markers', Icon(Icons.bookmark_border), '/markers'),
        sideBarMenuElement(
            context, 'Groups', Icon(Icons.format_list_bulleted), '/groups'),
        sideBarMenuElementLogin(
            context, 'Profile', Icon(Icons.account_circle), '/profile'),
        sideBarMenuElementLogin(
            context, 'Community', Icon(Icons.language), '/community'),
        sideBarMenuElement(context, 'Settings',
            Icon(Icons.settings_applications), '/settings'),
        sideBarMenuElement(
            context, 'About', Icon(Icons.info_outline), '/about'),
        PrefService.getString('token') == ''
            ? sideBarMenuElement(context, 'Log In',
            Icon(Icons.subdirectory_arrow_right), '/login')
            : sideBarMenuElement(context, 'Log out',
            Icon(Icons.subdirectory_arrow_right), '/login'),
      ],
    ),
  );
}
