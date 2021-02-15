import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_action.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_marker.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_group.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class GroupLoader {
  // ===========================================================================
  //-------------------------- VARIABLES ---------------------------------------
  Map<String, FlatMappGroup> _groups = <String, FlatMappGroup>{};
  MarkerLoader markerLoader;
  VoidCallback updateState;

  // ===========================================================================
  //-------------------------- LOADING METHODS ---------------------------------

  Future<String> getFilePath() async {
    // get file storage path
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/group_storage.json';
    } on FileSystemException catch (e) {
      // file error
      print('File processing error: $e');
      return '';
    }
  }

//  Future updateMarkersOnFileChange() async {
//    String path = await getFilePath();
//    try {
//      // check if there was a change in markers
//      if (File(path).lastModifiedSync().isAfter(_markersLastModification)) {
//        _markersLastModification = File(path).lastModifiedSync();
//        this.loadMarkers();
//      }
//    } on FileSystemException catch (e) {
//      print(e);
//    }
//  }

  void _repairFile(String path) {
    // clear file
    File(path).writeAsString('');
  }

  // save markers to local storage
  void saveGroups() async {
    // save markersDescription
    final path_ = await getFilePath();
    final file = new File(path_);
    String markerStorage = json.encode(_groups);

    await file.writeAsString(markerStorage);

    print("groups saved!");
  }

  Future loadGroups() async {
    String path = await getFilePath();
    // if group storage does exist
    if (await File(path).exists()) {
      // get storage content
      final file = File(path);
      String groupStorage = await file.readAsString();

      try {
        Map<String, dynamic> jsonObj =
        Map<String, dynamic>.from(json.decode(groupStorage));

        if (jsonObj.isNotEmpty) {
          jsonObj.forEach((key, dynamic value) {
            _groups[key] = FlatMappGroup.fromJson(value);
          });
        } else {
          print("could not parse file content");
          // add temporary marker
          saveGroups();
        }
      } on FormatException {
        print('local storage is empty...');
        // add temporary marker
        saveGroups();
      }
    } else {
      _repairFile(path);
      print('local storage did not exist, created new one...');
    }
  }

  // generate unique id for groups
  String generateId() {
    return UniqueKey().toString();
  }

  void addGroup(
      String id,
      String name,
      double range,
      String icon,
      List<FlatMappAction> actions,
      List<String> markers
      )
  {
    _groups[id] = FlatMappGroup(name, range, icon, actions, markers);
    saveGroups();
  }

  // deletes group but doesn't touch markers assigned to it
  void deleteGroup(String groupId)
  {
    _groups.remove(groupId);
    saveGroups();
  }

  // deletes group and all markers assigned to it
  void deleteGroupWithMarkers(String groupId)
  {
    _groups[groupId].markers.forEach((element) {
      markerLoader.removeMarker(id: element);
    });
    deleteGroup(groupId);
  }

  // clears group from assigned markers
  void removeAllMarkersFromGroup(String groupId)
  {
    _groups[groupId].markers.clear();
    saveGroups();
  }

  // adds marker to group
  void addMarkerToGroup(String groupId, String markerId)
  {
    if(!_groups[groupId].markers.contains(markerId))
      _groups[groupId].markers.add(markerId);
    FlatMappMarker marker = markerLoader.getMarkerDescription(markerId);
    markerLoader.addMarker(
        id: markerId,
        position: LatLng(marker.position_x, marker.position_y),
        icon: _groups[groupId].icon,
        title: marker.title,
        description: marker.description,
        range: _groups[groupId].range,
        actions: _groups[groupId].actions,
        queue: marker.queue,
        groupId: groupId
    );
    saveGroups();
  }

  // removes marker from group but doesn't delete it overall
  void removeMarkerFromGroup(String groupId, String markerId)
  {
    _groups[groupId].markers.remove(markerId);
    saveGroups();
  }

  // initiates action list with a single action in given group and
  // updates markers assigned to it
  void setGroupActionSingle(
      {String groupId,
        int action_position,
        Map<String, dynamic> action_parameters}) {
    _groups[groupId].actions[action_position].parameters =
        action_parameters;

    _groups[groupId].markers.forEach((element) {
      addMarkerToGroup(groupId, element);
    });
  }

  // adds action to action List in given group and updates markers
  // assigned to it
  void addGroupAction({String groupId, FlatMappAction action}) {
    if (_groups[groupId].actions == null) {
      _groups[groupId].actions = [];
    }

    // update action position
    action.action_position =
        (_groups[groupId].actions.length + 1).toDouble();
    _groups[groupId].actions.add(action);
    if(updateState!=null)
      updateState(); //We can pass more then 1 parameter

    _groups[groupId].markers.forEach((element) {
      addMarkerToGroup(groupId, element);
    });
  }

  // removes action from action List in given group and updates markers
  // assigned to it
  void removeGroupAction({String groupId, int index}) {
    if (_groups[groupId].actions[index] != null) {
      _groups[groupId].actions.removeAt(index);
      _groups[groupId].markers.forEach((element) {
        addMarkerToGroup(groupId, element);
      });
    } else {
      print("no action to remove at index $index from group $groupId");
    }
  }

  void removeAllGroups(){
    _groups.clear();
  }

  void printGroup(String groupId){
    print(_groups[groupId].toString());
  }
}