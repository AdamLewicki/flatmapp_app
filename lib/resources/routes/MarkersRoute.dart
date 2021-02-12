import 'package:flatmapp/resources/objects/loaders/icons_loader.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_marker.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

// ignore: must_be_immutable
class MarkersRoute extends StatefulWidget {
  // data loader
  MarkerLoader _markerLoader = MarkerLoader();

  MarkersRoute(this._markerLoader, {Key key}) : super(key: key);

  @override
  _MarkersRouteState createState() => _MarkersRouteState();
}

// Putting language dictionaries seams done

class _MarkersRouteState extends State<MarkersRoute> {
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
                  widget._markerLoader.removeMarker(id: id);
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

  Future<void> _raiseAlertDialogRemoveAllMarkers(BuildContext context) async {
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
                    widget._markerLoader.removeAllMarkers();
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
                title: Text(
                    LanguagesLoader.of(context).translate("Active markers:") +
                        ' #' +
                        (widget._markerLoader.getDescriptionsKeys().length - 1 >
                                0
                            ? '${widget._markerLoader.getDescriptionsKeys().length - 1}'
                            : '0'),
                    style: bodyText()),
                leading: Icon(Icons.bookmark_border),
              ),
            ),
            Expanded(
              child: Container(
                decoration: buttonFieldStyle(),
                child: Tooltip(
                  message: LanguagesLoader.of(context)
                      .translate("Remove all markers"),
                  child: ListTile(
                    title: Text(
                        LanguagesLoader.of(context).translate("Remove all"),
                        style: bodyText()),
                    trailing: Icon(Icons.delete_forever),
                    onTap: () {
                      // remove all markers with alert dialog
                      _raiseAlertDialogRemoveAllMarkers(context);
                    },
                  ),
                ),
              ),
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
    List<String> _markersDescriptionsKeys =
        widget._markerLoader.getDescriptionsKeys();

    // ActionsList _actionsList = ActionsList(widget._markerLoader);

    if (_markersDescriptionsKeys.length > 0) {
      return Expanded(
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: _markersDescriptionsKeys.length + 1,
          itemBuilder: (context, index) {
            if (index == _markersDescriptionsKeys.length) {
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
              String _id = _markersDescriptionsKeys.elementAt(index);
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
      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}
