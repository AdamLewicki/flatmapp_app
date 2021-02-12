import 'dart:convert';

import 'package:flatmapp/resources/objects/models/flatmapp_action.dart';

class FlatMappMarker {
  double position_x;
  double position_y;
  double range;
  double action_position;
  String title;
  String icon;
  String description;
  List<FlatMappAction> actions;
  int queue;

  FlatMappMarker(
      this.position_x,
      this.position_y,
      this.range,
      this.action_position,
      this.title,
      this.description,
      this.icon,
      this.actions,
      this.queue);

  // override print
  String toString() {
    return '{'
        '"position_x": "${this.position_x}", '
        '"position_y": "${this.position_y}", '
        '"range": "${this.range}", '
        '"action_position": "${this.action_position}", '
        '"title": "${this.title}", '
        '"description": "${this.description}", '
        '"icon": "${this.icon}", '
        '"actions": "${this.actions}", '
        '"queue": "${this.queue}", '
        '}';
  }

  FlatMappMarker.fromJson(Map<String, dynamic> json) {
    fromJson(json);
  }

  FlatMappMarker.toJson() {
    toJson();
  }

  void fromJson(Map<String, dynamic> marker) {
    this.position_x = marker['position_x'];
    this.position_y = marker['position_y'];
    this.range = marker['range'];
    this.action_position = marker['action_position'];
    this.title = marker['title'];
    this.icon = marker['icon'];
    this.description = marker['description'];
    this.actions = actionsFromList(marker['actions']);
    this.queue = marker['queue'];
  }

  Map<String, dynamic> toJson() {
    return {
      'position_x': this.position_x,
      'position_y': this.position_y,
      'range': this.range,
      'action_position': this.action_position,
      'title': this.title,
      'icon': this.icon,
      'description': this.description,
      'actions': this.actions,
      'queue': this.queue
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
}
