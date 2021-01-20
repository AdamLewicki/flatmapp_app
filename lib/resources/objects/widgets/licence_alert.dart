import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dnd/flutter_dnd.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:preferences/preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// show licence dialog at startup
showLicenceAgreement(BuildContext context) async {
  bool isLicenceAccepted = PrefService.getBool("licence_accepted");
  if (isLicenceAccepted == false) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text(LanguagesLoader.of(context).translate("Licence header")),
          content: Linkify(
            text:
            "${LanguagesLoader.of(context).translate("Licence text")}",
            onOpen: (link) async {
              if (await canLaunch(link.url)) {
                await launch(link.url);
              } else {
                // show message
                Fluttertoast.showToast(
                  msg:
                  '${LanguagesLoader.of(context).translate("Could not launch")} $link',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
//            style: bodyText(),
            linkStyle: TextStyle(color: Colors.green),
          ),//Text(LanguagesLoader.of(context).translate("Licence text")),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text(
                  LanguagesLoader.of(context).translate("Licence accept")),
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
                PrefService.setBool("licence_accepted", true);
                _check_dnd_permission();
                _check_location_permission();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                        title: Text(LanguagesLoader.of(context).translate("pop up title")),
                        content: Text(LanguagesLoader.of(context).translate("pop up content")),
                        actions: <Widget>[
                                    new FlatButton(
                                      child: new Text(LanguagesLoader.of(context).translate("Let's start")),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.pushNamed(context, '/map');
                                      },
                                    )]
                    );
                  }
                );
              },
            ),
            new FlatButton(
              child: new Text(
                  LanguagesLoader.of(context).translate("Licence dismiss")),
              onPressed: () {
                // Close the app
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }
}

_check_location_permission() async{
  if (!(await Permission.location.request().isGranted)) {
    // request access to location
    Permission.location.request();
  }
}

_check_dnd_permission() async{
  // check dnd permission
  if (await FlutterDnd.isNotificationPolicyAccessGranted) {
  } else {
    FlutterDnd.gotoPolicySettings();
  }
}