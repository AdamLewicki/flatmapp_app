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
    _groups[groupId].markers.forEach((markerId) {
      markerLoader.removeMarker(id: markerId);
    });
    deleteGroup(groupId);
  }

  // clears group from assigned markers and deletes them completely
  void removeAllMarkersAtGroup(String groupId)
  {
    _groups[groupId].markers.forEach((marker) {
      markerLoader.removeMarker(id: marker);
    });
    _groups[groupId].markers.clear();
    saveGroups();
  }

  // clears group from assigned markers but not form application
  void removeAllMarkersFromGroup(String groupId)
  {
    _groups[groupId].markers.forEach((marker) {
      markerLoader.getMarkerDescription(marker).groupId = '';
    });
    markerLoader.saveMarkers();
    _groups[groupId].markers.clear();
    saveGroups();
  }

  // removes marker from group but doesn't delete it overall
  void removeMarkerFromGroup(String groupId, String markerId)
  {
    _groups[groupId].markers.remove(markerId);
    markerLoader.getMarkerDescription(markerId).groupId = '';
    saveGroups();
  }

  // clears all groups of markers
  void clearAllGroupsOfMarkers(){
    _groups.forEach((groupId, group) {
      group.markers.clear();
    });
    saveGroups();
  }

  // adds marker to group
  void addMarkerToGroup(String groupId, String markerId)
  {
    if(!_groups[groupId].markers.contains(markerId))
      _groups[groupId].markers.add(markerId);
    saveGroups();
  }

  // use group values for every marker assigned to this group
  void updateMarkers(String groupId){
    _groups[groupId].markers.forEach((markerId) {
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
    });
  }

  void removeAllGroups(){
    _groups.clear();
    saveGroups();
  }

  List<String> getGroupsIds(){
    return _groups.keys.toList();
  }

  FlatMappGroup getGroup(String groupId){
    return _groups[groupId];
  }

  List<FlatMappAction> getGroupActions(String groupId){
    return _groups[groupId].actions;
  }

  Map<String, FlatMappGroup> getGroupsMap(){
    return _groups;
  }

  String getGroupNameByMarker(String markerId)
  {
    String groupId = markerLoader.getMarkerDescription(markerId).groupId;
    if(groupId != '' && _groups.containsKey(groupId))
    {
      return _groups[groupId].name;
    }
    return '';
  }

  List<String> getGroupMarkers(String groupId){
    return _groups[groupId].markers;
  }

  List<FlatMappMarker> getGroupFlatMappMarkers(String groupId){
    List<FlatMappMarker> markers = [];
    _groups[groupId].markers.forEach((marker) {
      markers.add(markerLoader.getMarkerDescription(marker));
    });
    return markers;
  }

  int getNumberOfMarkersInGroup(String groupId)
  {
    return _groups[groupId].markers.length;
  }

  void printGroup(String groupId){
    print(_groups[groupId].toString());
  }

  void setGroupName(String groupId, String name){
    _groups[groupId].name = name;
  }

  void setGroupRange(String groupId, double range){
    _groups[groupId].range = range;
  }

  void setGroupIcon(String groupId, String icon){
    _groups[groupId].icon = icon;
  }

  void setGroupActions(String groupId, List<FlatMappAction> actions){
    _groups[groupId].actions = actions;
  }
}
