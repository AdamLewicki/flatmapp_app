import 'dart:async';

import 'package:flatmapp/resources/objects/loaders/icons_loader.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/map_helper.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_marker.dart';
import 'package:flatmapp/resources/objects/widgets/MapMarker.dart';
import 'package:flatmapp/resources/objects/widgets/actions_list.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/licence_alert.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:preferences/preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:provider/provider.dart';

import 'UpdateMarkerLocation.dart';

// Putting language dictionaries seams done

// ignore: must_be_immutable
class MapRoute extends StatefulWidget {
  // data loader
  MarkerLoader _markerLoader = MarkerLoader();

  MapRoute(this._markerLoader, {Key key}) : super(key: key);

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
  TextEditingController _formDescriptionController =
      new TextEditingController();
  TextEditingController _formRangeController = new TextEditingController();

  // map style preset
  final String _preset = PrefService.getString('ui_theme');
  /// Set of displayed markers and cluster markers on the map

  final Set<Marker> _markers = Set();

  /// Minimum zoom at which the markers will cluster
  final int _minClusterZoom = 0;

  /// Maximum zoom at which the markers will cluster
  final int _maxClusterZoom = 19;

  /// [Fluster] instance used to manage the clusters
  Fluster<MapMarker> _clusterManager;

  /// Current map zoom. Initial zoom will be 15, street level
  double _currentZoom = 15;


  /// Url image used on normal markers
  final String _markerImageUrl =
      'https://img.icons8.com/office/80/000000/marker.png';

  /// Color of the cluster circle
  final Color _clusterColor = Colors.blue;

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;

  // Map loading flag
  bool _isMapLoading = true;

  // Markers loading flag
  bool _areMarkersLoading = true;

  LatLng updatedPosition;

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

    Future.delayed(Duration.zero, () => showLicenceAgreement(context));
    widget._markerLoader.mySlowMethod(() {

      setState(() {});
      //print("ok long press");
      // update form
      updateFormData();
      // open sliding form
      _slidingFormController.open();

    });
widget._markerLoader.updateStateMethod((){
  setState(() {

  });
});

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


    _initMarkers();
  }
  /// Inits [Fluster] and all the markers with network images and updates the loading state.
  void _initMarkers() async {
    final List<MapMarker> markers = [];
    widget._markerLoader.googleMarkers.values.forEach((element)  {
      markers.add(
        MapMarker(
          id: element.markerId.value,
          position: element.position,
        ),
      );
    });

    _clusterManager = await MapHelper.initClusterManager(
      markers,
      _minClusterZoom,
      _maxClusterZoom,
    );

    await _updateMarkers();
  }
  // add marker in the place where user touched the map
  Future _mapTap(LatLng position) async {
    // if the form is opened, close it. In other case, move marker
    if (_slidingFormController.isPanelOpen) {
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
    if (_slidingFormController.isPanelOpen) {
      return;
    }
    setState(() {});

    // update form
    updateFormData();
    // open sliding form
    _slidingFormController.open();

  }

  // update camera position basing on selected marker
  CameraPosition updateCameraPosition() {
    try {
      return CameraPosition(
        target: widget._markerLoader
            .getGoogleMarker(id: PrefService.getString('selected_marker'))
            .position,
        zoom: _currentZoom,
      );
    } on NoSuchMethodError {
      // try to repair the phantom marker bug by selecting temporary marker
      PrefService.setString('selected_marker', 'temporary');
      return CameraPosition(
        target: widget._markerLoader
            .getGoogleMarker(id: PrefService.getString('selected_marker'))
            .position,
        zoom: _currentZoom,
      );
    }
  }

  Widget _googleMapWidget() {
    return GoogleMap(
      myLocationEnabled: true,
      mapToolbarEnabled: true,
      initialCameraPosition: updateCameraPosition(),
      // markers: widget._markerLoader.googleMarkers.values.toSet(),
      markers:Set<Marker>.of(widget._markerLoader.googleMarkers.values)	,
      circles: Set<Circle>.of(widget._markerLoader.zones.values),
      onMapCreated: (controller) => _onMapCreated(controller),
      onCameraMove: (position) => _updateMarkers(position.zoom),
      // call this function when tapped on the map
      onTap: (position) {
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
                  // close form
                  _slidingFormController.close();
                },
              ),
            ]);
      },
    );
  }

  void updateFormData() {
    FlatMappMarker temp = widget._markerLoader
        .getMarkerDescription(PrefService.getString('selected_marker'));
    // set marker data to temporary marker
    if (temp != null) {
      _formMarkerData['title'] = temp.title;
      _formMarkerData['description'] = temp.description;
      _formMarkerData['range'] = temp.range.toInt();
    }

    // update controllers
    _formTitleController.text = _formMarkerData['title'].toString();
    _formDescriptionController.text = _formMarkerData['description'].toString();
    _formRangeController.text = _formMarkerData['range'].toString();
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

  Widget _buildMarkerNameField(context) {
    return TextFormField(
      controller: _formTitleController,
      style: bodyText(),
      decoration: textFieldStyle(
          labelTextStr: LanguagesLoader.of(context).translate("Marker title"),
          hintTextStr:
              LanguagesLoader.of(context).translate("Marker title goes here")),
      onSaved: (String value) {
        _formMarkerData['title'] = value;
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
          labelTextStr:
              LanguagesLoader.of(context).translate("Marker description"),
          hintTextStr: LanguagesLoader.of(context)
              .translate("Marker description goes here")),
      onSaved: (String value) {
        _formMarkerData['description'] = value;
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

  void _saveMarker({LatLng p}) {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      // bug on older api (25) - validation does not save form state.
      // To prevent this behaviour, additional if is present.
      if (_formMarkerData['title'] == "" ||
          _formMarkerData['description'] == "") {
        Fluttertoast.showToast(
          msg: LanguagesLoader.of(context)
              .translate("Please submit title and description and press enter"),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        String _selectedMarkerId = PrefService.get('selected_marker');

        setState(() {
          // adding a new marker to map
          widget._markerLoader.addMarker(
            id: _selectedMarkerId == 'temporary'
                ? widget._markerLoader.generateId()
                : _selectedMarkerId,
            position: updatedPosition ?? widget._markerLoader
                .getGoogleMarker(id: _selectedMarkerId)
                .position,
            icon: PrefService.getString('selected_icon'),
            title: _formMarkerData['title'].toString(),
            description: _formMarkerData['description'].toString(),
            range: _formMarkerData['range'].toDouble(),
            actions:
                widget._markerLoader.getMarkerActions(id: _selectedMarkerId),
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

  void _closePanel(context) {
    setState(() {
      // close keyboard
      FocusScope.of(context).requestFocus(FocusNode());
      // close panel
      _slidingFormController.close();
    });
  }

  Widget _markerAddForm(context) {
    String _id = PrefService.getString('selected_marker');
//    Marker tempMarker = widget._markerLoader.getGoogleMarker(
//        id: _id
//    );
    ActionsList _actionsList = ActionsList(widget._markerLoader);
    return Form(key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 10),
              Container(
                child: Opacity(
                  opacity: 0.2,
                  child: IconButton(
                    icon: Icon(Icons.keyboard_arrow_down, size: 40,),
                    color: (PrefService.get('ui_theme') == 'dark')
                        ? Colors.white
                        : Colors.black,
                    tooltip: 'Close form',
                    onPressed: () {
//                  _saveMarker();
                      setState(() {
                        _closePanel(context);
                      });
                    },
                  ),
                ),
                alignment: Alignment(0.0, 0.0),
              ),
              Row(children: <Widget>[
                PrefService.getString("selected_marker") == 'temporary'
                    ? SizedBox.shrink()
                    : Expanded(
                  child: new Container(
                    decoration: buttonFieldStyle(),
                    margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: ListTile(
                        title: Text(
                            LanguagesLoader.of(context)
                                .translate("Delete marker"),
                            style: bodyText()),
//                        trailing: Icon(Icons.delete_forever),
                        onTap: () {
                          // set up the AlertDialog
                          raiseAlertDialogRemoveMarker(_id);
                        }),
                  ),
                ),
                PrefService.getString("selected_marker") == 'temporary'
                    ? SizedBox.shrink()
                    : Expanded(
                  child: new Container(
                    decoration: buttonFieldStyle(),
                    margin: const EdgeInsets.only(left: 0.0, right: 0.0),
                    child: ListTile(
                        title: Text(
                            LanguagesLoader.of(context)
                                .translate("Marker Position"),
                            style: bodyText()),
//                        trailing: Icon(Icons.delete_forever),
                        onTap: () {
                          String _selectedMarkerId = PrefService.get('selected_marker');
                          UpdateMarkerLocation asd = new UpdateMarkerLocation(widget._markerLoader
                              .getGoogleMarker(id: _selectedMarkerId)
                              .position, (p){
                            // Fluttertoast.showToast(msg: "ok"+p.longitude.toString(),toastLength: Toast.LENGTH_LONG,
                            //   gravity: ToastGravity.BOTTOM);
                            // _saveMarker(p: p);
                          updatedPosition = p;
                          });
                          // set up the AlertDialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => asd),
                          );
                        }),
                  ),
                ),

                      Expanded(
                  child: new Container(
                    decoration: buttonFieldStyle(),
                    margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: ListTile(
                        title: PrefService.getString("selected_marker") ==
                            'temporary'
                            ? Text(
                            LanguagesLoader.of(context)
                                .translate("Add marker"),
                            style: bodyText(),
                            textAlign: TextAlign.center)
                            : Text(
                            LanguagesLoader.of(context)
                                .translate("Save marker"),
                            style: bodyText()),
//                        leading: Icon(Icons.bookmark_border),
                        onTap: () {
                          // submit form and add marker to dictionary
                          _saveMarker();
                        }),
                  ),
                ),
              ]),
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
                Text(LanguagesLoader.of(context).translate("Actions List"),
                    style: bodyText()),
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
                  context, PrefService.getString("selected_marker")),
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
//          Row(
//              children: <Widget>[
//                Expanded(
//                  child: new Container(
//                    margin: const EdgeInsets.only(left: 10.0, right: 20.0),
//                    child: ListTile(
//                        title: PrefService.getString("selected_marker") == 'temporary' ?
//                        Text(
//                          LanguagesLoader.of(context).translate("Add marker"),
//                          style: bodyText()
//                        ) :
//                        Text(
//                            LanguagesLoader.of(context).translate("Save marker"),
//                            style: bodyText()
//                        ),
//                        leading: Icon(Icons.bookmark_border),
//                        onTap: (){
//                          // submit form and add marker to dictionary
//                          _saveMarker();
//                        }
//                    ),
//                  ),
//                ),
//                PrefService.getString("selected_marker") == 'temporary' ?
//                SizedBox.shrink() :
//                Expanded(
//                  child: new Container(
//                    margin: const EdgeInsets.only(left: 10.0, right: 20.0),
//                    child: ListTile(
//                        title: Text(
//                          LanguagesLoader.of(context).translate("Delete marker"),
//                          style: bodyText()
//                        ),
//                        trailing: Icon(Icons.delete_forever),
//                        onTap: (){
//                          // set up the AlertDialog
//                          raiseAlertDialogRemoveMarker(_id);
//                        }
//                    ),
//                  ),
//                ),
//              ]
//          ),
            ],
          ));


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

    // show licence agreement
    // Future.delayed(Duration.zero, () => showLicenceAgreement(context));

    return Scaffold(
      appBar: appBar(),
      body:GestureDetector(
        onTap: (){
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child:  // GOOGLE MAPS
      PrefService.get('map_enabled') != true
          ? textInfo(
          LanguagesLoader.of(context).translate("Map is disabled") ??
              '')
          : Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Map loading indicator
          Opacity(
            opacity: _isMapLoading ? 1 : 0,
            child: Center(child: CircularProgressIndicator()),
          ),

          // Map markers loading indicator
          if (_areMarkersLoading)
            textInfo(LanguagesLoader.of(context)
                .translate("Loading markers")),

          SlidingUpPanel(
            color: _preset == 'dark' ? Colors.black : Colors.white,
            minHeight: 30,
            maxHeight: 590,
            padding: EdgeInsets.only(
              left: 30,
              right: 30,
            ),
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
              onTap: () {
                print("ok ink");
                _mapLongPress(LatLng(0, 0));
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                  _preset == 'dark' ? Colors.black : Colors.white,
                  // color: Colors.green,
                  borderRadius: radius,
                ),
                child: Center(
                  child: Text(
                    // PrefService.getString('selected_marker') == 'temporary' ? "Tap here to add marker" : "Tap here to modify marker",
                    LanguagesLoader.of(context).translate(
                        "Tap here to create or modify markers"),
                    style: bodyText(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),),

      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    //   drawer: new Drawer(
    // child: new ListView(
    // padding: EdgeInsets.zero,
    //   children: <Widget>[
    //     DrawerHeader(
    //       child: Text('Drawer Header'),
    //       decoration: BoxDecoration(
    //         color: Colors.blue,
    //       ),
    //     ),
    //     ListTile(
    //       title: Text('Item 1'),
    //       onTap: () {
    //         //Do some stuff here
    //         //Closing programmatically - very less practical use
    //         scaffoldKey.currentState.openEndDrawer();
    //       },
    //     )
    //   ],
    // ),
    // ),
    );
  }


  /// Gets the markers and clusters to be displayed on the map for the current zoom level and
  /// updates state.
  Future<void> _updateMarkers([double updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;

    if (updatedZoom != null) {
      _currentZoom = updatedZoom;
    }

    setState(() {
      _areMarkersLoading = true;
    });

    final updatedMarkers = await MapHelper.getClusterMarkers(
      _clusterManager,
      _currentZoom,
      _clusterColor,
      _clusterTextColor,
      80,
    );

    _markers.clear();
    _markers.addAll(updatedMarkers);

    setState(() {
      _areMarkersLoading = false;
    });
  }
}
