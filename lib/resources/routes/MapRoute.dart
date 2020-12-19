import 'package:flatmapp/resources/extensions.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_marker.dart';
import 'package:flatmapp/resources/objects/widgets/actions_list.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flutter/services.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:preferences/preferences.dart';

import 'dart:async';

// Putting language dictionaries seams done

// ignore: must_be_immutable
class MapRoute extends StatefulWidget {

  // data loader
  MarkerLoader _markerLoader = MarkerLoader();
  MapRoute(this._markerLoader, {Key key}): super(key: key);

  @override
  _MapRouteState createState() => _MapRouteState();
}

class _MapRouteState extends State<MapRoute> {
  // ===========================================================================
  // -------------------- INIT VARIABLES SECTION -------------------------------

  // google map controller
  final Completer<GoogleMapController> _mapController = Completer();

  // sliding form controller
  PanelController _slidingFormController = new PanelController();

  // form controllers:
  TextEditingController _formTitleController = new TextEditingController();
  TextEditingController _formDescriptionController = new TextEditingController();
  TextEditingController _formRangeController = new TextEditingController();

  // map style preset
  final String _preset = PrefService.getString('ui_theme');

  // map zoom
  double _currentZoom = 18;

  // Map loading flag
  bool _isMapLoading = true;
  // Markers loading flag
  bool _areMarkersLoading = true;

  // Form variables
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formMarkerData = {
    'id': "temporary",
    'title': "temporary marker",
    'description': "marker presenting chosen position",
    'range': 12,
    'actions': [],
  };

  @override
  void initState() {
    super.initState();

    // update form
    updateFormData();

    // update camera position
    updateCameraPosition();
  }

  // ===========================================================================
  // -------------------- GOOGLE MAPS WIDGET SECTION ---------------------------
  // set custom map style
  void _setStyle(GoogleMapController controller) async {
    String value = await DefaultAssetBundle.of(context)
        .loadString('assets/map_style_$_preset.json');
    controller.setMapStyle(value);
  }

  // Called when the Google Map widget is created.
  // Updates the map loading state and initializes markers.
  void _onMapCreated(GoogleMapController controller) {

    // set custom map style
    _setStyle(controller);

    // crete map controller
    _mapController.complete(controller);

    // notify about finished map loading
    setState(() {
      _isMapLoading = false;
    });

    // notify about finished markers loading
    setState(() {
      _areMarkersLoading = false;
    });
  }

  // add marker in the place where user touched the map
  Future _mapTap(LatLng position) async {
    // if the form is opened, close it. In other case, move marker
    if(_slidingFormController.isPanelOpen){
      // close panel
      _slidingFormController.close();
    } else {
      setState(() {
        // change temporary position
        widget._markerLoader.addTemporaryMarker(position);

        // change selected marker in prefs
        PrefService.setString('selected_marker', 'temporary');

        // save markers state to file
        widget._markerLoader.saveMarkers();
      });
    }
  }

  // open marker form if user pressed the map
  Future _mapLongPress(LatLng position) async {

    // reload icon in form - requires setState update on preferences
    setState(() { });

    // update form
    updateFormData();
    // open sliding form
    _slidingFormController.open();
  }

  // update camera position basing on selected marker
  CameraPosition updateCameraPosition(){
    try{
      return CameraPosition(
        target: widget._markerLoader.getGoogleMarker(
          id: PrefService.getString('selected_marker')
        ).position,
        zoom: _currentZoom,
      );
    } on NoSuchMethodError {
      // try to repair the phantom marker bug by selecting temporary marker
      PrefService.setString('selected_marker', 'temporary');
      return CameraPosition(
        target: widget._markerLoader.getGoogleMarker(
            id: PrefService.getString('selected_marker')
        ).position,
        zoom: _currentZoom,
      );
    }
  }

  Widget _googleMapWidget(){
    return GoogleMap(
      myLocationEnabled: true,
      mapToolbarEnabled: true,
      initialCameraPosition: updateCameraPosition(),
      markers: Set<Marker>.of(widget._markerLoader.googleMarkers.values),
      circles: Set<Circle>.of(widget._markerLoader.zones.values),
      onMapCreated: (controller) => _onMapCreated(controller),

      // call this function when tapped on the map
      onTap: (position){
        _mapTap(position);
      },
      // call this function when long pressed on the map
      onLongPress: (position) {
        _mapLongPress(position);
      },
    );
  }

  // ===========================================================================
  // -------------------- MARKER FORM WIDGET SECTION ---------------------------
  Future<void> raiseAlertDialogRemoveMarker(String id) async {

    FlatMappMarker _marker = widget._markerLoader.getMarkerDescription(id);

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(
                LanguagesLoader.of(context).translate("Remove marker?")
            ),
            content: Text(
              LanguagesLoader.of(context).translate("You are about to remove marker") +
              "\n"
              "${_marker.title}\n"
              "${_marker.description}."
            ),
            actions: [
              // set up the buttons
              FlatButton(
                child: Text(
                  LanguagesLoader.of(context).translate("No")
                ),
                onPressed:  () {
                  // dismiss alert
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text(
                  LanguagesLoader.of(context).translate("Yes")
                ),
                onPressed:  () {
                  // remove marker
                  widget._markerLoader.removeMarker(id: id);
                  // save markers state to file
                  widget._markerLoader.saveMarkers();
                  // dismiss alert
                  Navigator.of(context).pop();
                  // close form
                  _slidingFormController.close();
                },
              ),
            ]
        );
      },
    );
  }

  void updateFormData(){
    FlatMappMarker temp = widget._markerLoader.getMarkerDescription(
      PrefService.getString('selected_marker')
    );
    // set marker data to temporary marker
    if (temp != null){
      _formMarkerData['title'] = temp.title;
      _formMarkerData['description'] = temp.description;
      _formMarkerData['range'] = temp.range.toInt();
    }

    // update controllers
    _formTitleController.text = _formMarkerData['title'].toString();
    _formDescriptionController.text = _formMarkerData['description'].toString();
    _formRangeController.text = _formMarkerData['range'].toString();
  }

  Widget _iconChangeButton(){
    return Expanded(
      child: SizedBox(
        height: 60.0,
        // icon change button
        child: Container(
          decoration: buttonFieldStyle(),
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(),
            child: FlatButton(
              onPressed: (){
                // Navigate to the icons screen using a named route.
                Navigator.pushNamed(context, '/icons');
              },
              padding: EdgeInsets.all(0.0),
              child: Image.asset(
                widget._markerLoader.iconsLoader.markerImageLocal[
                  PrefService.get('selected_icon')
                ]
              )
            )
          )
        ),
      ),
    );
  }

  Widget _buildMarkerNameField(context) {
    return TextFormField(
      controller: _formTitleController,
      style: bodyText(),
      decoration: textFieldStyle(
          labelTextStr: LanguagesLoader.of(context).translate("Marker title"),
          hintTextStr: LanguagesLoader.of(context).translate("Marker title goes here")
      ),
      onSaved: (String value) {
        _formMarkerData['title'] = value;
      },
      textInputAction: TextInputAction.next,
      validator: (text) {
        if (text == null || text.isEmpty) {
          return LanguagesLoader.of(context).translate("This field can not be empty");
        }
        return null;
      },
      onFieldSubmitted: (String value) {
        _formMarkerData['title'] = value;
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }

  Widget _buildMarkerDescriptionField(context) {
    return TextFormField(
      controller: _formDescriptionController,
      style: bodyText(),
      decoration: textFieldStyle(
          labelTextStr: LanguagesLoader.of(context).translate("Marker description"),
          hintTextStr: LanguagesLoader.of(context).translate("Marker description goes here")
      ),
      onSaved: (String value) {
        _formMarkerData['description'] = value;
      },
      textInputAction: TextInputAction.next,
      validator: (text) {
        if (text == null || text.isEmpty) {
          return LanguagesLoader.of(context).translate("This field can not be empty");
        }
        return null;
      },
      onFieldSubmitted: (String value) {
        _formMarkerData['description'] = value;
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }

  Widget _buildMarkerRangeField() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Tooltip(
          message: LanguagesLoader.of(context).translate("marker range in meters"),
          child: new Text(
            LanguagesLoader.of(context).translate("Range:"),
            style: bodyText(),
          ),
        ),
        SizedBox(height: 20),
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {
            if (_formMarkerData['range'] > 1) {
              setState(() {
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
              _formMarkerData['range'] = toDouble(input, 12);
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
              _formMarkerData['range'] += 1;
              _formRangeController.text = _formMarkerData['range'].toString();
            });
          },
        ),
      ],
    );
  }

  void _saveMarker(){
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      // bug on older api (25) - validation does not save form state.
      // To prevent this behaviour, additional if is present.
      if(_formMarkerData['title'] == "" || _formMarkerData['description'] == ""){
        Fluttertoast.showToast(
          msg: LanguagesLoader.of(context).translate("Please submit title and description and press enter"),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        String _selectedMarkerId = PrefService.get('selected_marker');

        setState(() {
          // adding a new marker to map
          widget._markerLoader.addMarker(
            id: _selectedMarkerId == 'temporary' ?
            widget._markerLoader.generateId() : _selectedMarkerId,
            position: widget._markerLoader.getGoogleMarker(
                id: _selectedMarkerId
            ).position,
            icon: PrefService.getString('selected_icon'),
            title: _formMarkerData['title'].toString(),
            description: _formMarkerData['description'].toString(),
            range: _formMarkerData['range'].toDouble(),
            actions: widget._markerLoader.getMarkerActions(id: _selectedMarkerId),
          );
        });

        // close form panel
        _closePanel(context);

        // reset data form
        PrefService.setString('selected_marker', 'temporary');
        PrefService.setString('selected_icon', 'default');
        updateFormData();

        // show message
        Fluttertoast.showToast(
          msg: LanguagesLoader.of(context).translate("Added marker"),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  void _closePanel(context){
    setState(() {
      // close keyboard
      FocusScope.of(context).requestFocus(FocusNode());
      // close panel
      _slidingFormController.close();
    });
  }

  Widget _markerAddForm(context){
    String _id = PrefService.getString('selected_marker');
//    Marker tempMarker = widget._markerLoader.getGoogleMarker(
//        id: _id
//    );
    ActionsList _actionsList = ActionsList(widget._markerLoader);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                child: Opacity(
                  opacity: 0.2,
                  child: IconButton(
                    icon: Icon(Icons.keyboard_arrow_down, size: 40),
                    color: (PrefService.get('ui_theme') == 'dark') ? Colors.white : Colors.black,
                    tooltip: 'Close form',
                    onPressed: (){
                      setState(() {
                        _closePanel(context);
                      });
                    },
                  ),
                ),
                alignment: Alignment(0.0, 0.0),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildMarkerNameField(context),
          SizedBox(height: 10),
          _buildMarkerDescriptionField(context),
          SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // icon change button
              _iconChangeButton(),
              SizedBox(width: 10),
              // range counter
              _buildMarkerRangeField(),
            ],
          ),
          SizedBox(height: 10),

          Row(children: <Widget>[
            Expanded(
              child: new Container(
                  margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                  child: Divider(
                    // color: Colors.black,
                    // height: 36,
                  )),
            ),
            Text(
                LanguagesLoader.of(context).translate("Actions List"),
                style: bodyText()
            ),
            Expanded(
              child: new Container(
                  margin: const EdgeInsets.only(left: 20.0, right: 10.0),
                  child: Divider(
//                    color: Colors.black,
//                    height: 36,
                  )),
            ),
          ]),

          _actionsList.buildActionsList(
            context,
            PrefService.getString("selected_marker")
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: new Container(
                    margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                    child: Divider(
                      // color: Colors.black,
                      // height: 36,
                    )),
              ),
            ],
          ),
          Row(
              children: <Widget>[
                Expanded(
                  child: new Container(
                    margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                    child: ListTile(
                        title: PrefService.getString("selected_marker") == 'temporary' ?
                        Text(
                          LanguagesLoader.of(context).translate("Add marker"),
                          style: bodyText()
                        ) :
                        Text(
                            LanguagesLoader.of(context).translate("Save marker"),
                            style: bodyText()
                        ),
                        leading: Icon(Icons.bookmark_border),
                        onTap: (){
                          // submit form and add marker to dictionary
                          _saveMarker();
                        }
                    ),
                  ),
                ),
                PrefService.getString("selected_marker") == 'temporary' ?
                SizedBox.shrink() :
                Expanded(
                  child: new Container(
                    margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                    child: ListTile(
                        title: Text(
                          LanguagesLoader.of(context).translate("Delete marker"),
                          style: bodyText()
                        ),
                        trailing: Icon(Icons.delete_forever),
                        onTap: (){
                          // set up the AlertDialog
                          raiseAlertDialogRemoveMarker(_id);
                        }
                    ),
                  ),
                ),
              ]
          ),
        ],
      )
    );
  }

  // ===========================================================================
  // -------------------- MAIN MAP WIDGET SECTION ------------------------------
  @override
  Widget build(BuildContext context) {

    // add form radius
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );

    return Scaffold(
      appBar: appBar(),
      body:

      // GOOGLE MAPS
      PrefService.get('map_enabled') != true
        ? textInfo(LanguagesLoader.of(context).translate("Map is disabled") ?? '')
        : Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Map loading indicator
          Opacity(
            opacity: _isMapLoading ? 1 : 0,
            child: Center(
                child: CircularProgressIndicator()
            ),
          ),

          // Map markers loading indicator
          if (_areMarkersLoading)
            textInfo(LanguagesLoader.of(context).translate("Loading markers")),

          SlidingUpPanel(
            color: _preset == 'dark' ? Colors.black : Colors.white,
            minHeight: 30,
            maxHeight: 590,
            padding: EdgeInsets.only(left: 30, right: 30,),
            borderRadius: radius,
            isDraggable: false,
            defaultPanelState: PanelState.CLOSED,
            controller: _slidingFormController,
            panel: _markerAddForm(context),
            body: Opacity(
              opacity: _isMapLoading ? 0 : 1,
              // Google Map widget
              child: Container(
                child: _googleMapWidget(),
              ),
            ),
            collapsed: InkWell(
              onTap: () { _mapLongPress(LatLng(0, 0)); },
              child: Container(
                decoration: BoxDecoration(
                  color: _preset == 'dark' ? Colors.black : Colors.white,
                  // color: Colors.green,
                  borderRadius: radius,
                ),
                child: Center(
                  child: Text(
                    // PrefService.getString('selected_marker') == 'temporary' ? "Tap here to add marker" : "Tap here to modify marker",
                    LanguagesLoader.of(context).translate("Tap here to create or modify markers"),
                    style: bodyText(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // // floating button to open form
      // floatingActionButton: new Visibility(
      //   visible: _slidingFormController.isPanelClosed,
      //   child: new FloatingActionButton(
      //     onPressed: () {
      //       _mapLongPress(LatLng(0, 0));
      //     },
      //     tooltip: 'Add or modify markers',
      //     child: new Icon(Icons.add),
      //     elevation: 8.0,
      //   ),
      // ),

      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}
