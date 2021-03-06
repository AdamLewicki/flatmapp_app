import 'package:flatmapp/resources/objects/loaders/actions_loader.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_action.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

// Putting language dictionaries seams done
// ignore: must_be_immutable
class ActionsRoute extends StatefulWidget {
  // data loader
  MarkerLoader _markerLoader = MarkerLoader();

  ActionsRoute(this._markerLoader, {Key key}) : super(key: key);

  @override
  _ActionsRouteState createState() => _ActionsRouteState();
}

class _ActionsRouteState extends State<ActionsRoute> {
  ActionsLoader _actionsLoader = ActionsLoader();

  Widget _actionsListView(BuildContext context) {
    return ListView.builder(
      itemCount: _actionsLoader.actionsMap.length,
      itemBuilder: (context, index) {
        String key = _actionsLoader.actionsMap.keys.elementAt(index);
        return Card(
          //                           <-- Card widget
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(_actionsLoader.actionsMap[key]),
            ),
            title: Text(LanguagesLoader.of(context).translate(key),
                style: bodyText()),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              // add action to the selected marker id
              widget._markerLoader.addMarkerAction(
                  id: PrefService.get('selected_marker').toString(),
                  action: FlatMappAction(key, key, -420, {
                    'param1': '',
                    'param2': '',
                    'param3': '',
                    'param4': '',
                    'param5': '',
                    'param6': '',
                  }));
              // TODO Navigate to parameters after adding action
              Navigator.of(context).popAndPushNamed("/action_parameters");
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          appBar(title: LanguagesLoader.of(context).translate("Choose action")),
      body:
          // BODY
          _actionsListView(context),
      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}
