import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/loaders/net_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_marker.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

// Putting language dictionaries seams done
// ignore: must_be_immutable
class ProfileRoute extends StatefulWidget {
  // data loader
  MarkerLoader _markerLoader = MarkerLoader();

  ProfileRoute(this._markerLoader, {Key key}) : super(key: key);

  @override
  _ProfileRouteState createState() => _ProfileRouteState();
}

class _ProfileRouteState extends State<ProfileRoute> {
  NetLoader _netLoader = NetLoader();

  @override
  void initState() {
    super.initState();
  }

  Future<void> raiseAlertDialogRemoveMarker(String id) async {
    FlatMappMarker _marker = widget._markerLoader.getMarkerDescription(id);

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title:
                Text(LanguagesLoader.of(context).translate("Remove marker?")),
            content: Text(LanguagesLoader.of(context)
                    .translate("You are about to remove marker") +
                "\n"
                    "${_marker.title}\n"
                    "${_marker.description}."),
            actions: [
              // set up the buttons
              FlatButton(
                child: Text(LanguagesLoader.of(context).translate("No")),
                onPressed: () {
                  // dismiss alert
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text(LanguagesLoader.of(context).translate("Yes")),
                onPressed: () {
                  // remove marker
                  widget._markerLoader.removeMarker(id: id);
                  // save markers state to file
                  widget._markerLoader.saveMarkers();
                  // dismiss alert
                  Navigator.of(context).pop();
                  // refresh cards
                  setState(() {});
                },
              ),
            ]);
      },
    );
  }

  Widget _profileColumn() {
    return PrefService.get('token') == ''
        ? textInfo('You need to log in to use Profile' ?? '')
        :
//    Expanded(
//      child: ,
//    ),
        Column(
            children: <Widget>[
              ListTile(
                title: Text(LanguagesLoader.of(context).translate("Profile"),
                    style: header()),
                leading: Icon(Icons.account_circle),
              ),
              Tooltip(
                message:
                    LanguagesLoader.of(context).translate("Change username"),
                child: ListTile(
                  title: Text(
                    LanguagesLoader.of(context).translate("Username") +
                        ': ' +
                        PrefService.getString("login"),
                    style: bodyText(),
                  ),
                  leading: Icon(Icons.laptop),
                  onTap: () {
                    // TODO move to change form
                  },
                ),
              ),
              ListTile(
                title: Text(
                  LanguagesLoader.of(context)
                      .translate("Back up your markers to server"),
                  style: bodyText(),
                ),
                trailing: Icon(Icons.backup),
                onTap: () {
                  _netLoader.postBackup(context, widget._markerLoader);
                },
              ),
              ListTile(
                title: Text(
                  LanguagesLoader.of(context)
                      .translate("Get your markers from Backup"),
                  style: bodyText(),
                ),
                trailing: Icon(Icons.file_download),
                onTap: () {
                  _netLoader.getBackup(context, widget._markerLoader);
                },
              ),
              ExpansionTile(
                leading: Icon(Icons.laptop),
                title: Text(
                    LanguagesLoader.of(context).translate("Change user data"),
                    style: bodyText()),
                trailing: Icon(Icons.keyboard_arrow_down),
                children: <Widget>[
                  ListTile(
                    title: Text(
                      LanguagesLoader.of(context).translate("Change password"),
                      style: bodyText(),
                    ),
                    // leading: Icon(Icons.keyboard_arrow_right),
                    trailing: Icon(Icons.compare_arrows),
                    onTap: () {
                      // move to change form
                      Navigator.pushNamed(context, '/change_password');
                    },
                  ),
                  ListTile(
                    title: Text(
                      LanguagesLoader.of(context)
                          .translate("Erase account from system"),
                      style: bodyText(),
                    ),
                    trailing: Icon(Icons.remove_circle),
                    leading: Icon(Icons.remove_circle),
                    onTap: () {
                      // move to account removal form
                      Navigator.pushNamed(context, '/erase_account');
                    },
                  ),
                ],
              ),
              ListTile(
                title: Text(
                  LanguagesLoader.of(context).translate("flatmapp_footer"),
                  style: footer(),
                ),
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    // show licence agreement
//    Future.delayed(Duration.zero, () => showLicenceAgreement(context));
    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _profileColumn(),
      ),
      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}
