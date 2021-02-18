import 'dart:convert';

import 'package:flatmapp/resources/objects/models/flatmapp_action.dart';

class FlatMappGroup{
  String name;
  double range;
  String icon;
  List<FlatMappAction> actions;
  List<String> markers;

  FlatMappGroup(
      this.name,
      this.range,
      this.icon,
      this.actions,
      this.markers
      );

  String toString() {
    return '{'
        '"name": "${this.name}", '
        '"range": "${this.range}", '
        '"icon": "${this.icon}", '
        '"actions": "${this.actions}", '
        '"markers": "${this.markers}", '
        '}';
  }

  FlatMappGroup.fromJson(Map<String, dynamic> json) {
    fromJson(json);
  }

  FlatMappGroup.toJson() {
    toJson();
  }

  void fromJson(Map<String, dynamic> group) {
    this.name = group['name'];
    this.range = group['range'];
    this.icon = group['icon'];
    this.actions = actionsFromList(group['actions']);
    this.markers = markersFromList(group['markers']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': this.name,
      'range': this.range,
      'icon': this.icon,
      'actions': this.actions,
      'markers': this.markers
    };
  }

  List<FlatMappAction> actionsFromList(List<dynamic> actions_list) {
    List<FlatMappAction> actions = [];
    if (actions_list.isNotEmpty) {
      actions_list.forEach((element) {
        if (element['action_detail'] == null) {
          print(element);
          print("no action_detail object found!");
        } else {
          actions.add(FlatMappAction(
            element['Action_Name'].toString(),
            element['icon'].toString(),
            element['action_position'],
            json.decode(element['action_detail']),
          ));
        }
      });
    }
    return actions;
  }

  List<String> markersFromList(List<dynamic> markers_list) {
    List<String> markers = [];
    if (markers_list.isNotEmpty) {
      markers_list.forEach((element) {
        markers.add(element);
      });
    }
    return markers;
  }


}
