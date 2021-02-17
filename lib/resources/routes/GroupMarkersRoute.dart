import 'package:flatmapp/resources/objects/loaders/group_loader.dart';
import 'package:flatmapp/resources/objects/loaders/icons_loader.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_marker.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

// ignore: must_be_immutable
class GroupMarkersRoute extends StatefulWidget {
  // data loader
  MarkerLoader _markerLoader = MarkerLoader();
  GroupLoader _groupLoader = GroupLoader();

  GroupMarkersRoute(this._markerLoader, this._groupLoader, {Key key}) : super(key: key);

  @override
  _GroupMarkersRouteState createState() => _GroupMarkersRouteState();
}

// Putting language dictionaries seams done

class _GroupMarkersRouteState extends State<GroupMarkersRoute> {
  IconsLoader _iconsLoader = IconsLoader();

  @override
  void initState() {
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // ==================  ALERT DIALOGS =========================================
  Future<void> raiseAlertDialogRemoveMarker(String id) async {
    FlatMappMarker _marker = widget._markerLoader.getMarkerDescription(id);

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(
              LanguagesLoader.of(context).translate("Remove marker?"),
            ),
            content: Text(LanguagesLoader.of(context)
                .translate("You are about to remove marker") +
                "\n"
                    "${_marker.title}\n"
                    "${_marker.description}"),
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
                  if(_marker.groupId == '')
                    widget._markerLoader.removeMarker(id: id);
                  else{
                    widget._groupLoader.removeMarkerFromGroup(_marker.groupId, id);
                    widget._markerLoader.removeMarker(id: id);
                  }
                  // save markers state to file
                  widget._markerLoader.saveMarkers();
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

  Future<void> raiseAlertDialogRemoveMarkerFromGroup(String id) async {
    FlatMappMarker _marker = widget._markerLoader.getMarkerDescription(id);

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(
              LanguagesLoader.of(context).translate("Remove marker?"),
            ),
            content: Text(LanguagesLoader.of(context)
                .translate("You are about to remove marker from group") +
                "\n"
                    "${_marker.title}\n"
                    "${_marker.description}"),
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
                  widget._groupLoader.removeMarkerFromGroup(_marker.groupId, id);
                  // save markers state to file
                  widget._markerLoader.saveMarkers();
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

  Future<void> _raiseAlertDialogRemoveAllMarkersFromGroup(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(
                LanguagesLoader.of(context).translate("Remove ALL markers?")),
            content: Text(LanguagesLoader.of(context).translate(
                "You are about to remove all markers from group")),
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
                child: Text(LanguagesLoader.of(context)
                    .translate("Remove all markers")),
                onPressed: () {
                  // remove all markers
                  setState(() {
                    widget._groupLoader.removeAllMarkersFromGroup(PrefService
                        .getString('selected_group'));
                  });
                  // dismiss alert
                  Navigator.of(context).pop();
                },
              ),
            ]);
      },
    );
  }

  Future<void> _raiseAlertDialogRemoveAllMarkersAtGroup(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(
                LanguagesLoader.of(context).translate("Remove ALL markers?")),
            content: Text(LanguagesLoader.of(context).translate(
                "You are about to remove all markers from local storage")),
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
                child: Text(LanguagesLoader.of(context)
                    .translate("Remove all markers")),
                onPressed: () {
                  // remove all markers
                  setState(() {
                    widget._groupLoader.removeAllMarkersAtGroup(PrefService
                        .getString('selected_group'));
                  });
                  // dismiss alert
                  Navigator.of(context).pop();
                },
              ),
            ]);
      },
    );
  }

  // ===========================================================================
  // ---------------------------------------------------------------------------
  // ======================= COLUMNS ===========================================

  Widget _markersColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: ListTile(
                title: Text(LanguagesLoader.of(context).translate("Group markers:") +
                    ' #' + widget._groupLoader.getNumberOfMarkersInGroup(
                    PrefService.getString('selected_group')).toString(),
                    style: bodyText()),
                leading: Icon(Icons.bookmark_border),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              tooltip: LanguagesLoader.of(context)
                  .translate("Remove markers from group"),
              onPressed: () {
                _raiseAlertDialogRemoveAllMarkersFromGroup(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_forever),
              tooltip: LanguagesLoader.of(context)
                  .translate("Remove markers which are in group"),
              onPressed: () {
                _raiseAlertDialogRemoveAllMarkersAtGroup(context);
              },
            ),
          ],
        ),
        // list of active markers
        _listMarkers(context),

        ListTile(
          title: Text(
            LanguagesLoader.of(context).translate("flatmapp_footer"),
            style: footer(),
          ),
        ),
      ],
    );
  }

  Widget _listMarkers(BuildContext context) {
    List<String> _groupMarkers =
    widget._groupLoader.getGroupMarkers(
        PrefService.getString('selected_group')
    );

    // ActionsList _actionsList = ActionsList(widget._markerLoader);

    if (_groupMarkers.length > 0) {
      return Expanded(
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: _groupMarkers.length + 1,
          itemBuilder: (context, index) {
            if (index == _groupMarkers.length) {
              // add last element - card "add marker"
              // return Container( //                           <-- Card widget
              //   child: Opacity(
              //     opacity: 0.2,
              //     child: IconButton(
              //         icon: Icon(Icons.add_circle_outline, size: 40,),
              //         color: (PrefService.get('ui_theme') == 'dark') ? Colors.white : Colors.black,
              //         tooltip: "Add marker",
              //         onPressed: () {
              //           // set temporary as selected marker
              //           PrefService.setString('selected_marker', "temporary");
              //           // Navigate to the profile screen using a named route.
              //           Navigator.pushNamed(context, '/map');
              //         }
              //     ),
              //   ),
              //   alignment: Alignment(0.0, 0.0),
              // );
              return SizedBox.shrink();
            } else {
              // marker data for card
              String _id = _groupMarkers.elementAt(index);
              FlatMappMarker _marker =
              widget._markerLoader.getMarkerDescription(_id);

              // don't add temporary marker to the list
              if (_id == 'temporary') {
                return SizedBox.shrink();
              } else {
                // add marker marker expandable card:
                return Card(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 5.0, left: 10.0, right: 10.0, bottom: 0.0),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(
                            _iconsLoader.markerImageLocal[_marker.icon]),
                      ),
                      title: Text(_marker.title, style: bodyText()),
                      subtitle: Text(LanguagesLoader.of(context)
                          .translate("marker queue") + " " +_marker.queue.toString(), style: footer()),
                      trailing: Icon(Icons.keyboard_arrow_down),
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.location_searching),
                              tooltip: LanguagesLoader.of(context)
                                  .translate("Find marker"),
                              onPressed: () {
                                // set selected marker id for map screen
                                PrefService.setString('selected_marker', _id);
                                // Navigate to the profile screen using a named route.
                                Navigator.pushNamed(context, '/map');
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              tooltip: LanguagesLoader.of(context)
                                  .translate("Remove marker"),
                              onPressed: () {
                                // set up the AlertDialog
                                raiseAlertDialogRemoveMarkerFromGroup(_id);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever),
                              tooltip: LanguagesLoader.of(context)
                                  .translate("Remove marker"),
                              onPressed: () {
                                // set up the AlertDialog
                                raiseAlertDialogRemoveMarker(_id);
                              },
                            ),
                          ],
                        ),
                        // TODO add actions list to marker card in Profile
                        // _actionsList.buildActionsList(context, _id),
                      ],
                    ),
                  ),
                );
              }
            }
          },
        ),
      );
    } else {
      return ListTile(
        title: Text(LanguagesLoader.of(context).translate("no markers found"),
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
        child: _markersColumn(),
      ),
    );
  }
}
