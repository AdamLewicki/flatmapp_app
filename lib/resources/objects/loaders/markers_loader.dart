import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flatmapp/resources/objects/loaders/geofence_loader.dart';
import 'package:flatmapp/resources/objects/loaders/icons_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_action.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_marker.dart';
import 'package:flatmapp/resources/routes/MapRoute.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preferences/preferences.dart';

class MarkerLoader {
  // ===========================================================================
  //-------------------------- VARIABLES ---------------------------------------

  // list of marker data in strings
  Map<String, FlatMappMarker> _markersDescriptions = <String, FlatMappMarker>{};

  // google maps markers set
  Map<String, Marker> googleMarkers = <String, Marker>{};
   VoidCallback called;
   VoidCallback updatestate;

  // zones set
  Map<String, Circle> zones = <String, Circle>{};

  // time of last modification
  DateTime _markersLastModification = DateTime.now();

  // icons loader
  final IconsLoader iconsLoader = IconsLoader();

  final _firstCoordinates = LatLng(52.466791, 16.926939);

  // ===========================================================================
  //-------------------------- LOADING METHODS ---------------------------------

  Future<String> getFilePath() async {
    // get file storage path
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/marker_storage.json';
    } on FileSystemException catch (e) {
      // file error
      print('File processing error: $e');
      return '';
    }
  }

  Future updateMarkersOnFileChange() async {
    String path = await getFilePath();
    try {
      // check if there was a change in markers
      if (File(path).lastModifiedSync().isAfter(_markersLastModification)) {
        _markersLastModification = File(path).lastModifiedSync();
        this.loadMarkers();
      }
    } on FileSystemException catch (e) {
      print(e);
    }
  }

  void _repairFile(String path) {
    // clear file
    File(path).writeAsString('');
    // add temporary marker
    addTemporaryMarker(_firstCoordinates);
  }

  // save markers to local storage
  void saveMarkers() async {
    // save markersDescription
    final path_ = await getFilePath();
    final file = new File(path_);
    String markerStorage = json.encode(_markersDescriptions);

    await file.writeAsString(markerStorage);

    print("markers saved!");
  }

  // load markers from local storage
  Future loadMarkers() async {
    String path = await getFilePath();

    // if marker storage does exist
    if (await File(path).exists()) {
      // get storage content
      final file = File(path);
      String markerStorage = await file.readAsString();

      try {
//        save it to map: throws
//        type '_InternalLinkedHashMap<String, dynamic>'
//        is not a subtype of type 'FlatMappMarker'.
//        Requires cast method override in FlatMappMarker from _InternalLinkedHashMap<String, dynamic>.
//        _markersDescriptions = Map<String, FlatMappMarker>.from(
//            json.decode(markerStorage)
//        );
        // clear markers storage
        // removeAllMarkers();

        Map<String, dynamic> jsonObj =
            Map<String, dynamic>.from(json.decode(markerStorage));

        if (jsonObj.isNotEmpty) {
          jsonObj.forEach((key, dynamic value) {
            _markersDescriptions[key] = FlatMappMarker.fromJson(value);
          });
        } else {
          print("could not parse file content");
          // add temporary marker
          addTemporaryMarker(_firstCoordinates);
          saveMarkers();
        }
      } on FormatException {
        print('local storage is empty...');
        // add temporary marker
        addTemporaryMarker(_firstCoordinates);
        saveMarkers();
      }
    } else {
      _repairFile(path);
      print('local storage did not exist, created new one...');
    }

    _descriptionsToObjects();
  }

  // translate descriptions to google map markers and zones
  void _descriptionsToObjects() {
    // for each marker description
    _markersDescriptions.forEach((String markerID, FlatMappMarker markerData) {
      String id = markerID;
      LatLng position = LatLng(markerData.position_x, markerData.position_y);

      // add marker
      addMarker(
        id: id,
        position: position,
        icon: markerData.icon,
        title: markerData.title,
        description: markerData.description,
        range: markerData.range,
        actions: markerData.actions,
      );
    });
  }

  // generate unique id for markers
  String generateId() {
    return UniqueKey().toString();
  }

  mySlowMethod(VoidCallback listener) async {
    // Here your uncertain task
    // In our case, for example, we call the listener every 2 seconds
    called = listener;

  }

  updateStateMethod(VoidCallback listener) async {
    // Here your uncertain task
    // In our case, for example, we call the listener every 2 seconds
    updatestate = listener;

  }
  // add or edit marker
  void addMarker(
      {String id,
      LatLng position,
      String icon,
      String title,
      String description,
      double range,
      List<FlatMappAction> actions}) {
    _markersDescriptions[id] = FlatMappMarker(position.latitude,
        position.longitude, range, -420, title, description, icon, actions);

    iconsLoader.getMarkerImage(icon).then((iconBitmap) {
      googleMarkers[id] = Marker(
          markerId: MarkerId(id),
          position: position,
          icon: iconBitmap,
          onTap: () {
            // set marker as selected on tap
            PrefService.setString('selected_marker', id);
            PrefService.setString('selected_icon', icon);
            print("ok on marker tap");
            if(called!=null)
              called(); //We can pass more then 1 parameter

          },
          draggable: true,
          onDragEnd: ((newPosition) {
            print("drag");
            print(newPosition.latitude);
            print(newPosition.longitude);
            if(updatestate=null){
              updatestate();
            }
          }),
          infoWindow: InfoWindow(
            title: title,
            snippet: description,
          ));
      // add zone
      zones[id] = Circle(
        circleId: CircleId(id),
        center: position,
        radius: range,
        fillColor: Colors.redAccent.withOpacity(0.2),
        strokeWidth: 2,
        strokeColor: Colors.redAccent,
      );
    });
    // save markers
    saveMarkers();

    if (id != "temporary") {
      GeofenceLoader.addGeofence(
          "$id;${position.latitude};${position.longitude};${range}");
    }
  }

  void removeMarker({String id}) {
    _markersDescriptions.remove(id);
    googleMarkers.remove(id);
    zones.remove(id);
    if (id != "temporary") GeofenceLoader.deleteGeofence(id);

    if (PrefService.get('selected_marker') == id) {
      PrefService.setString('selected_marker', 'temporary');
    }
  }

  // save markers to local storage
  void saveMarkersFromBackup({Map<String, FlatMappMarker> content}) async {
    _markersDescriptions = content;
    saveMarkers();
  }

  void addTemporaryMarker(LatLng position) {
    addMarker(
      id: "temporary",
      position: position,
      icon: 'default',
      title: "",
      description: "",
      range: 12,
      actions: [],
    );
  }

  FlatMappMarker getMarkerDescription(String id) {
    return _markersDescriptions[id];
  }

  Map<String, FlatMappMarker> getMarkersDescriptions() {
    return _markersDescriptions;
  }

  Marker getGoogleMarker({String id}) {
    return googleMarkers[id];
  }

  List<String> getDescriptionsKeys() {
    return _markersDescriptions.keys.toList();
  }

  double getRange({String id}) {
    return zones[id].radius;
  }

  List<FlatMappAction> getMarkerActions({String id}) {
    return _markersDescriptions[id].actions;
  }

  FlatMappAction getMarkerActionSingle(
      {String marker_id, int action_position}) {
    return _markersDescriptions[marker_id].actions[action_position];
  }

  void setMarkerActionSingle(
      {String marker_id,
      int action_position,
      Map<String, dynamic> action_parameters}) {
    _markersDescriptions[marker_id].actions[action_position].parameters =
        action_parameters;
  }

  void addMarkerAction({String id, FlatMappAction action}) {
    if (_markersDescriptions[id].actions == null) {
      _markersDescriptions[id].actions = [];
    }

    // update action position
    action.action_position =
        (_markersDescriptions[id].actions.length + 1).toDouble();

    _markersDescriptions[id].actions.add(action);
    if(updatestate!=null)
      updatestate(); //We can pass more then 1 parameter



    saveMarkers();
  }

  void removeMarkerAction({String id, int index}) {
    if (_markersDescriptions[id].actions[index] != null) {
      _markersDescriptions[id].actions.removeAt(index);
    } else {
      print("no action to remove at index $index from marker $id");
    }
  }

  Future<void> removeAllMarkers() async {
    // copy temporary marker
    FlatMappMarker _temp = getMarkerDescription("temporary");

    // from non-persistent storage
    _markersDescriptions.clear();
    googleMarkers.clear();
    zones.clear();

    // add temporary marker
    addTemporaryMarker(LatLng(_temp.position_x, _temp.position_y));
    _temp = null;

    saveMarkers();
  }
}
