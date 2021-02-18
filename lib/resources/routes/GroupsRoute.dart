import 'package:flatmapp/resources/objects/loaders/group_loader.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_group.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';

import 'package:flutter/material.dart';
import 'package:preferences/preference_service.dart';


// ignore: must_be_immutable
class GroupsRoute extends StatefulWidget {
  // data loader
  GroupLoader _groupLoader = GroupLoader();
  MarkerLoader _markerLoader = MarkerLoader();

  GroupsRoute(this._groupLoader, this._markerLoader, {Key key}) : super(key: key);

  @override
  _GroupsRouteState createState() => _GroupsRouteState();

}

class _GroupsRouteState extends State<GroupsRoute>{

  @override
  void initState(){
    super.initState();
  }
  // ---------------------------------------------------------------------------
  // ==================  ALERT DIALOGS =========================================
  Future<void> raiseAlertDialogRemoveGroup(String id) async {
    FlatMappGroup _group = widget._groupLoader.getGroup(id);

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(
              LanguagesLoader.of(context).translate("Remove group?"),
            ),
            content: Text(LanguagesLoader.of(context)
                .translate("You are about to remove group") +
                "\n"
                    "${_group.name}\n"
                    "${id}"),
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
                  // remove group
                  widget._groupLoader.deleteGroupWithMarkers(id);
                  // save groups state to file
                  widget._groupLoader.saveGroups();
                  // dismiss alert
                  Navigator.of(context).pop();
                  // refresh cards
                  setState(() {});
                },
              ),
            ]);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ======================= COLUMNS ===========================================

  Widget _groupsColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: ListTile(
                title: Text(
                    LanguagesLoader.of(context).translate("Marker groups:") +
                        ' #' + widget._groupLoader.getGroupsIds().length.toString(),
                    style: bodyText()),
                leading: Icon(Icons.bookmark_border),
              ),
            ),
          ],
        ),

        _listGroups(context),

        ListTile(
          title: Text(
            LanguagesLoader.of(context).translate("flatmapp_footer"),
            style: footer(),
          ),
        ),
      ],
    );
  }

  Widget _listGroups(BuildContext context) {
    List<String> _groupsIds = widget._groupLoader.getGroupsIds();
    if(_groupsIds.length > 0) {
      return Expanded(
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: _groupsIds.length + 1,
            itemBuilder: (context, index) {
              if(index == _groupsIds.length) {
                return SizedBox.shrink();
              } else {
                String id = _groupsIds.elementAt(index);
                FlatMappGroup _group = widget._groupLoader.getGroup(id);
                return Card(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 5.0, left: 10.0, right: 10.0, bottom: 0.0),
                    child: ExpansionTile(
                      title: Text(_group.name, style: bodyText()),
                      subtitle: Text(LanguagesLoader.of(context)
                          .translate("Id") + id, style: footer()),
                      trailing: Icon(Icons.keyboard_arrow_down),
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.edit),
                              tooltip: LanguagesLoader.of(context)
                                  .translate("Edit group"),
                              onPressed: (){
                                PrefService.setString('selected_marker', 'temporary');
                                PrefService.setString('selected_group', id);
                                PrefService.setString('selected_icon', _group.icon);
                                widget._markerLoader
                                    .addTemporaryMarkerWithCustomActions(
                                    _group.actions
                                );
                                Navigator.pushNamed(context, '/edit_group');
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.format_list_bulleted),
                              tooltip: LanguagesLoader.of(context)
                                  .translate("Show Markers"),
                              onPressed: (){
                                PrefService.setString('selected_group', id);
                                Navigator.pushNamed(context, '/group_markers');
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever),
                              tooltip: LanguagesLoader.of(context)
                                  .translate("Delete group"),
                              onPressed: (){
                                raiseAlertDialogRemoveGroup(id);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }
            }
        ),
      );
    } else {
      return ListTile(
        title: Text(LanguagesLoader.of(context).translate("no groups found"),
            style: footer()),
        leading: Icon(Icons.error_outline),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar(),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _groupsColumn(),
        ),
        drawer: sideBarMenu(context)
    );
  }
}
