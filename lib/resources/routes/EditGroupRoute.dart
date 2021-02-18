import 'package:flatmapp/resources/objects/loaders/group_loader.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_group.dart';
import 'package:flatmapp/resources/objects/widgets/actions_list.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:preferences/preference_service.dart';


// ignore: must_be_immutable
class EditGroupRoute extends StatefulWidget{
  GroupLoader _groupLoader = GroupLoader();
  MarkerLoader _markerLoader = MarkerLoader();
  EditGroupRoute(this._markerLoader, this._groupLoader, {Key key}) : super(key: key);

  @override
  _EditGroupRouteState createState() => _EditGroupRouteState();

}

class _EditGroupRouteState extends State<EditGroupRoute> {
  // ===========================================================================
  // -------------------- INIT VARIABLES SECTION -------------------------------

  void initState() {
    super.initState();

    // update form
    updateFormData();
  }

  // Form variables
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formMarkerData = {
    'id': "temporary",
    'title': "temporary marker",
    'name': 'group name',
    'description': "",
    'range': 100,
    'actions': [],
    'queue': PrefService.getInt('number_of_markers'),
  };


  TextEditingController _formTitleController = new TextEditingController();
  TextEditingController _formRangeController = new TextEditingController();

  // ===========================================================================
  // -------------------- FORM WIDGET SECTION ----------------------------------

  void updateFormData() {
    FlatMappGroup _group = widget._groupLoader.getGroup(
        PrefService.getString('selected_group'));

    if(_group != null) {
      _formMarkerData['name'] = _group.name;
      _formMarkerData['range'] = _group.range.toInt();

      // update controllers
      _formTitleController.text = _formMarkerData['name'].toString();
      _formRangeController.text = _formMarkerData['range'].toString();
    }
  }

  Widget _iconChangeButton() {
    return Expanded(
      child: SizedBox(
        height: 60.0,
        // icon change button
        child: Container(
            decoration: buttonFieldStyle(),
            child: ConstrainedBox(
                constraints: BoxConstraints.expand(),
                child: FlatButton(
                    onPressed: () {
                      // Navigate to the icons screen using a named route.
                      Navigator.pushNamed(context, '/icons');
                    },
                    padding: EdgeInsets.all(0.0),
                    child: Image.asset(widget._markerLoader.iconsLoader
                        .markerImageLocal[PrefService.get('selected_icon')])))),
      ),
    );
  }

  Widget _buildGroupRangeField() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Tooltip(
          message:
          LanguagesLoader.of(context).translate("marker range in meters"),
          child: new Text(
            LanguagesLoader.of(context).translate("Range:"),
            style: bodyText(),
          ),
        ),
        SizedBox(height: 20),
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {
            if (_formMarkerData['range'] is String)
              _formMarkerData['range'] = int.parse(_formMarkerData['range']);
            if (_formMarkerData['range'] > 1) {
              setState(() {
                _formKey.currentState.save();
                _formMarkerData['range'] -= 1;
                _formRangeController.text = _formMarkerData['range'].toString();
              });
            }
          },
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            controller: _formRangeController,
            onSaved: (String input) {
              _formMarkerData['range'] = int.parse(input);
            },
            onFieldSubmitted: (String value) {
              _formMarkerData['range'] = value;
              FocusScope.of(context).requestFocus(FocusNode());
            },
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              // labelText: state.value.toString(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              WhitelistingTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
          ),
        ),
        Text(
          " m",
          style: bodyText(),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            setState(() {
              _formKey.currentState.save();
              if (_formMarkerData['range'] is String)
                _formMarkerData['range'] = int.parse(_formMarkerData['range']);
              _formMarkerData['range'] += 1;
              _formRangeController.text = _formMarkerData['range'].toString();
            });
          },
        ),
      ],
    );
  }

  Widget _buildGroupNameField(context) {
    return TextFormField(
      controller: _formTitleController,
      style: bodyText(),
      decoration: textFieldStyle(
          labelTextStr: LanguagesLoader.of(context).translate("Group name"),
          hintTextStr:
          LanguagesLoader.of(context).translate("Group name goes here")),
      onSaved: (String value) {
        _formMarkerData['name'] = value;
        print("onsaved");
      },
      textInputAction: TextInputAction.next,
      validator: (text) {
        if (text == null || text.isEmpty) {
          return LanguagesLoader.of(context)
              .translate("This field can not be empty");
        }
        return null;
      },
      onFieldSubmitted: (String value) {
        print("onFieldSubmitted");
        _formMarkerData['name'] = value;
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }

  void _saveGroup() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      // bug on older api (25) - validation does not save form state.
      // To prevent this behaviour, additional if is present.
      if (_formMarkerData['name'] == "") {
        Fluttertoast.showToast(
          msg: LanguagesLoader.of(context)
              .translate("Please submit title and description and press enter"),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        // get id of edited group
        String _selectedId = PrefService.get('selected_group');

        //
        widget._groupLoader.setGroupName(_selectedId, _formMarkerData['name']);
        widget._groupLoader.setGroupRange(_selectedId, _formMarkerData['range']
            .toDouble());

        widget._groupLoader.setGroupIcon(_selectedId, PrefService.getString(
            'selected_icon'));

        widget._groupLoader.setGroupActions(_selectedId,
            widget._markerLoader.getMarkerDescription('temporary').actions);

        widget._groupLoader.updateMarkers(_selectedId);

        widget._groupLoader.saveGroups();

        // close form
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pushNamed(context, '/groups');

        // reset icon which shows at default
        PrefService.setString('selected_icon', 'default');

        // reset temporary marker
        widget._markerLoader.addTemporaryMarkerAtSamePosition();

        // show message
        Fluttertoast.showToast(
          msg: LanguagesLoader.of(context).translate("Edited group"),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  Future<bool> _onBackPressed(){
    PrefService.setString('selected_icon', 'default');
    widget._markerLoader.addTemporaryMarkerAtSamePosition();
    Navigator.pop(context);
    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    ActionsList _actionsList = ActionsList(widget._markerLoader, widget._groupLoader);
    return WillPopScope(
      onWillPop: _onBackPressed,
      child:
      GestureDetector(
        onTap: (){
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: Scaffold(
          appBar: appBar(),
          body:
          Container(
            margin: EdgeInsets.all(20.0),
            child:
            Form(
                key: _formKey,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 10),
                      Row(
                          children: <Widget>[
                            Expanded(
                              child: new Container(
                                decoration: buttonFieldStyle(),
                                child: ListTile(
                                    title: Text(LanguagesLoader.of(context)
                                        .translate("Save marker"),
                                        style: bodyText(),
                                        textAlign: TextAlign.center),
                                    onTap: () {
                                      // submit form
                                      _saveGroup();
                                    }),
                              ),
                            ),
                          ]),
                      SizedBox(height: 10),
                      _buildGroupNameField(context),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          // icon change button
                          _iconChangeButton(),
                          SizedBox(width: 10),
                          // range counter
                          _buildGroupRangeField(),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Expanded(
                              child: new Container(
                                  margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                                  child: Divider())),],
                      ),
                      _actionsList.buildActionsList(
                          context, 'temporary'),
                    ]
                )
            ),
          ),
        ),
      ),
    );
  }
}
