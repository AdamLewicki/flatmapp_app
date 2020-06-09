import 'package:flatmapp/resources/objects/loaders/actions_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_action.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/text_form_fields.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:preferences/preferences.dart';


// ignore: must_be_immutable
class ActionParametersRoute extends StatefulWidget {
  // data loader
  MarkerLoader _markerLoader = MarkerLoader();
  ActionParametersRoute(this._markerLoader, {Key key}): super(key: key);

  @override
  _ActionParametersRouteState createState() => _ActionParametersRouteState();
}

class _ActionParametersRouteState extends State<ActionParametersRoute> {

  ActionsLoader _actionsLoader = ActionsLoader();

  FlatMappAction _selected_action;

  // selected menu in navigator
  int _selectedIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'param1': '',
    'param2': '',
  };
  final focusParam1 = FocusNode();
  final focusParam2 = FocusNode();

  //----------------------- ACTION PARAMETERS WIDGETS --------------------------
  Widget _muteWidget(){
    return ListTile(
      title: Text(
        'Mute dummy widget',
        style: bodyText(),
      ),
      leading: Icon(Icons.error_outline)
    );
  }

  Widget _bluetoothWidget(){
    return ListTile(
      title: Text(
        'Bluetooth dummy widget',
        style: bodyText(),
      ),
      leading: Icon(Icons.error_outline)
    );
  }

  Widget _notificationWidget(BuildContext context){
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 20),
          TextFormField(
            style: bodyText(),
            decoration: textFieldStyle(
              labelTextStr: "Notification title"
            ),
            initialValue: _formData['param1'],
            onSaved: (String value) {
              _formData['param1'] = value;
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              _formData['param1'] = value;
              FocusScope.of(context).requestFocus(focusParam2);
            },
            focusNode: focusParam1,
          ),
          SizedBox(height: 20),
          TextFormField(
            style: bodyText(),
            decoration: textFieldStyle(
              labelTextStr: "Notification description"
            ),
            initialValue: _formData['param2'],
            onSaved: (String value) {
              _formData['param2'] = value;
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              _formData['param2'] = value;
            },
            focusNode: focusParam2,
          ),
        ]
      ),
    );
  }

  Widget _wifiWidget(){
    return ListTile(
      title: Text(
        'Wifi dummy widget',
        style: bodyText(),
      ),
      leading: Icon(Icons.error_outline)
    );
  }

  // ---------------------------------------------------------------------------
  Widget _actionSelectorWidget(BuildContext context, String selected_widget){
    // TODO this section has to match completely with actions_loader.actionsMap!
    switch(selected_widget){
      case "mute":
        return _muteWidget();
        break;
      case "bluetooth":
        return _bluetoothWidget();
        break;
      case "notification":
        return _notificationWidget(context);
        break;
      case "wi-fi":
        return _wifiWidget();
        break;
      default:
        return ListTile(
          title: Text(
            'Could not find widget for $selected_widget!',
            style: bodyText(),
          ),
          leading: Icon(Icons.error_outline)
        );
    }
  }

  Widget _parametersColumn(BuildContext context){

    _selected_action = widget._markerLoader.getMarkerActionSingle(
      marker_id: PrefService.getString('selected_marker'),
      action_position: PrefService.getInt('selected_action')
    );

    _formData['param1'] = _selected_action.parameters['param1'];
    _formData['param2'] = _selected_action.parameters['param2'];

    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
              _selected_action.name,
            style: header()
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: AssetImage(
              _actionsLoader.actionsMap[_selected_action.icon]
            ),
          ),
        ),
        _actionSelectorWidget(context, _selected_action.name),
      ],
    );
  }

  Future<void> _submitForm() async {
    // validate form
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      // save data from form to action
      widget._markerLoader.setMarkerActionSingle(
        marker_id: PrefService.getString('selected_marker'),
        action_position: PrefService.getInt('selected_action'),
        action_parameters: _formData
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Action parameters'),
      body:
      // BODY
      _parametersColumn(context),
      // SIDE PANEL MENU
      drawer: sideBarMenu(context),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            title: Text('Accept'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.keyboard_return),
            title: Text('Return'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: (int index) {
          switch(index){
            case 0:
              // save changes from form
              _submitForm();
              // return to previous screen
              Navigator.of(context).pop();
              // show message
              Fluttertoast.showToast(
                msg: "Action parameters saved",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
              break;
            case 1:
              Navigator.of(context).pop();
              break;
          }
        }
      ),
    );
  }
}
