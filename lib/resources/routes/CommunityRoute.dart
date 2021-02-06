import 'package:flatmapp/resources/extensions.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/loaders/net_loader.dart';
import 'package:flatmapp/resources/objects/widgets/actions_list.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:preferences/preference_service.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// Putting language dictionaries seams done
// ignore: must_be_immutable
class CommunityRoute extends StatefulWidget {
  MarkerLoader _markerLoader = MarkerLoader(); // TODO unused element
  CommunityRoute(this._markerLoader, {Key key}) : super(key: key);

  @override
  _CommunityRouteState createState() => _CommunityRouteState();
}

class _CommunityRouteState extends State<CommunityRoute> {
  // style preset
  final String _preset = PrefService.getString('ui_theme');

  NetLoader netLoader = NetLoader();
  List<Map<String, dynamic>> _placesDescriptions = [];
  Geolocator _geolocator = Geolocator();

  // form controllers:
  TextEditingController _categoryController = new TextEditingController();
  TextEditingController _formRangeController = new TextEditingController();

  // sliding form controller
  PanelController _slidingFormController = new PanelController();

  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  bool if_already_added = false;
  String _last_search = "text"; // ignore: unused_field, // something not empty

  Map<String, dynamic> _formCategoryData = {
    'category': '',
    'range': 100,
    'position_x': 0,
    'position_y': 0,
    'approximate': true,
    'language': 'EN',
  };

  @override
  void initState() {
    super.initState();

    // update form
    updateFormData();
  }

  void updateFormData() {
    _formRangeController.text = _formCategoryData['range'].toString();
  }

  void _closePanel(context) {
    // close keyboard
    FocusScope.of(context).requestFocus(FocusNode());
    // close panel
    _slidingFormController.close();
  }

  Future<LatLng> getCurrentPosition() async {
    Position temp = await _geolocator.getCurrentPosition();
    return temp.toLatLng();
  }

  void addMarkerFromCategory(Map<String, dynamic> item, String _id, int queue) {
    item['radius'] = _formCategoryData['range'];

    widget._markerLoader.addMarker(
      id: _id,
      position: LatLng(item['position_x'], item['position_y']),
      icon: PrefService.get('community_icon'),
      title: item['name'],
      description: item['address'],
      range: item['radius'].toDouble(),
      actions: widget._markerLoader.getMarkerActions(id: "temporary"),
      queue: queue,
    );
  }

  //
  // Widget _buildMarkerApproximateRangeField() {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: <Widget>[
  //       Tooltip(
  //         message: LanguagesLoader.of(context).translate("marker range in meters"),
  //         child: new Text(
  //           LanguagesLoader.of(context).translate("Range:"),
  //           style: bodyText(),
  //         ),
  //       ),
  //       SizedBox(height: 20),
  //       IconButton(
  //         icon: Icon(Icons.remove),
  //         onPressed: () {
  //           if (_formCategoryData['range'] > 1) {
  //             setState(() {
  //               _formCategoryData['range'] -= 1;
  //               _formRangeController.text = _formCategoryData['range'].toString();
  //             });
  //           }
  //         },
  //       ),
  //       SizedBox(
  //         width: 100,
  //         child: TextFormField(
  //           controller: _formRangeController,
  //           onSaved: (String input) {
  //             _formCategoryData['range'] = toDouble(input, 100);
  //           },
  //           onFieldSubmitted: (String value) {
  //             _formCategoryData['range'] = value;
  //             FocusScope.of(context).requestFocus(FocusNode());
  //           },
  //           textInputAction: TextInputAction.next,
  //           decoration: InputDecoration(
  //             border: OutlineInputBorder(),
  //             // labelText: state.value.toString(),
  //           ),
  //           keyboardType: TextInputType.number,
  //           inputFormatters: <TextInputFormatter>[
  //             WhitelistingTextInputFormatter.digitsOnly,
  //             LengthLimitingTextInputFormatter(7),
  //           ],
  //         ),
  //       ),
  //       Text(
  //         " m",
  //         style: bodyText(),
  //       ),
  //       IconButton(
  //         icon: Icon(Icons.add),
  //         onPressed: () {
  //           setState(() {
  //             _formCategoryData['range'] += 1;
  //             _formRangeController.text = _formCategoryData['range'].toString();
  //           });
  //         },
  //       ),
  //     ],
  //   );
  // }

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
            _formKey2.currentState.save();
            if (_formCategoryData['range'] > 1) {
              setState(() {
                _formCategoryData['range'] -= 1;
                _formRangeController.text =
                    _formCategoryData['range'].toString();
              });
            }
          },
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            controller: _formRangeController,
            onSaved: (String input) {
              _formCategoryData['range'] = int.parse(input);
            },
            onFieldSubmitted: (String input) {
              _formCategoryData['range'] = int.parse(input);
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
              _formKey2.currentState.save();
              _formCategoryData['range'] += 1;
              _formRangeController.text = _formCategoryData['range'].toString();
            });
          },
        ),
      ],
    );
  }

  // Widget _buildApproximatedCheckboxField(){
  //   return Container(
  //     decoration: BoxDecoration(
  //       border: Border.all(width: 0.5),
  //       borderRadius: BorderRadius.all(
  //           Radius.circular(10.0) //         <--- border radius here
  //       ),
  //     ), //       <--- BoxDecoration here
  //     child: CheckboxListTile(
  //       title: Text(
  //         LanguagesLoader.of(context).translate("Use >Google nearby< range"),
  //         style: bodyText(),
  //       ),
  //       value: _formCategoryData['approximate'],
  //       onChanged: (value) {
  //         setState(() {
  //           _formCategoryData['approximate'] = value;
  //         });
  //       },
  //       controlAffinity: ListTileControlAffinity.trailing, //or leading
  //     ),
  //   );
  // }

  Widget _buildCategoryTextFieldAndButton() {
    return Form(
        key: _formKey,
        child: Row(children: <Widget>[
          Expanded(
            child: new Container(
              margin: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: TextFormField(
                controller: _categoryController,
                style: bodyText(),
                decoration: textFieldStyle(
                    labelTextStr:
                        LanguagesLoader.of(context).translate("Category name"),
                    hintTextStr: LanguagesLoader.of(context)
                        .translate("please provide category for search")),
                onSaved: (String value) {
                  _formCategoryData['category'] = value;
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
                  _formCategoryData['category'] = value;
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                onChanged: (String value) {
                  _formCategoryData['category'] = value;
                },
              ),
            ),
          ),
          Expanded(
            child: new Container(
              decoration: BoxDecoration(
                border: Border.all(width: 0.5),
                borderRadius: BorderRadius.all(
                    Radius.circular(10.0) //         <--- border radius here
                    ),
              ), //
              child: ListTile(
                  title: Text(LanguagesLoader.of(context).translate("Search"),
                      style: bodyText()),
                  trailing: Icon(Icons.search),
                  onTap: () {
                    if (_formKey.currentState.validate()) {
//                    if (_last_search != _formCategoryData['category']){
//                      // send request
                      sendCategoryRequest();
//                    } else {
//                      netLoader.showToast(LanguagesLoader.of(context).translate("No new category to search"));
//                    }
                    } else {
                      print("field didn't pass validation");
                    }
                  }),
            ),
          ),
        ]));
  }

  Future<void> sendCategoryRequest() async {
    // get phone localization language code
    _formCategoryData['language'] =
        Localizations.localeOf(context).languageCode;

    // UPDATE USER POSITION
    _geolocator.isLocationServiceEnabled().then((status) {
      if (status == false) {
        netLoader.showToast(
            LanguagesLoader.of(context).translate("Geolocation is turned off"));
      } else {
        netLoader.checkNetworkConnection().then((connected) {
          if (connected) {
            getCurrentPosition().then((position) {
              _formCategoryData['position_x'] = position.latitude;
              _formCategoryData['position_y'] = position.longitude;
              // send request to server via NetLoader and get category cards
              netLoader
                  .categoryRequest("/api/category/", _formCategoryData)
                  .then((v) {
                setState(() {
                  _placesDescriptions = v;
                  _last_search = _formCategoryData['category'];
                });
              });
            });
            // reset control of category add button
            if_already_added = false;
          } else {
            netLoader.showToast(LanguagesLoader.of(context)
                .translate("Network connection is off"));
          }
        });
      }
    });
  }

  Widget addAllPlaces(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 0.5),
        borderRadius: BorderRadius.all(
            Radius.circular(10.0) //         <--- border radius here
            ),
      ), //       <--- BoxDecoration here
      child: ListTile(
        title: Text(
          LanguagesLoader.of(context).translate("Add all placemarks from list"),
          style: bodyText(),
        ),
        leading: Icon(Icons.add_circle_outline),
        onTap: () {
          // TODO add global value which keeps last prioryty number
          int last_queue_index = PrefService.getInt('number_of_markers');
          for (int index = 0; index < _placesDescriptions.length; index++) {
            // add placemark method
            String _id = widget._markerLoader.generateId();
            print(_placesDescriptions[index]);
            addMarkerFromCategory(_placesDescriptions[index], _id, last_queue_index + index + 1);
          }
          setState(() {
            if_already_added = true;
          });
          netLoader.showToast(LanguagesLoader.of(context)
              .translate("All placemarks added successfully"));
          Navigator.pushNamed(context, '/map');
        },
      ),
    );
  }

  Widget openDefaultMarkerForm(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 0.5),
        borderRadius: BorderRadius.all(
            Radius.circular(10.0) //         <--- border radius here
            ),
      ), //       <--- BoxDecoration here
      child: ListTile(
        title: Text(
          LanguagesLoader.of(context).translate("Change default marker"),
          style: bodyText(),
        ),
        leading: Icon(Icons.edit),
        onTap: () {
          // reload icon in form - requires setState update on preferences
          setState(() {});
          // update form
          updateFormData();
          // open sliding form
          _slidingFormController.open();
        },
      ),
    );
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
                      Navigator.pushNamed(context, '/community_icons');
                    },
                    padding: EdgeInsets.all(0.0),
                    child: Image.asset(
                        widget._markerLoader.iconsLoader.markerImageLocal[
                            PrefService.getString('community_icon')])))),
      ),
    );
  }

  Widget _listPlaces(BuildContext context) {
    if (_placesDescriptions.length > 0) {
      return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: _placesDescriptions.length,
        itemBuilder: (context, index) {
          // add placemark expandable card:
          return Card(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 5.0, left: 10.0, right: 10.0, bottom: 0.0),
              child: ExpansionTile(
//                  leading: CircleAvatar(
//                    backgroundColor: Colors.white,
//                    backgroundImage: AssetImage(
//                        _iconsLoader.markerImageLocal[_marker.icon]
//                    ),
//                  ),
                title:
                    Text(_placesDescriptions[index]['name'], style: bodyText()),
                subtitle: Text(_placesDescriptions[index]['address'],
                    style: footer()),
                trailing: Icon(Icons.keyboard_arrow_down),
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.location_searching),
                        tooltip: LanguagesLoader.of(context)
                            .translate("Find placemark"),
                        onPressed: () {
                          // move temporary marker to new position
                          widget._markerLoader.addTemporaryMarker(LatLng(
                              _placesDescriptions[index]['position_x'],
                              _placesDescriptions[index]['position_y']));
                          // set selected marker
                          PrefService.setString('selected_marker', "temporary");
                          // Navigate to the profile screen using a named route.
                          Navigator.pushNamed(context, '/map');
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_forever),
                        tooltip: LanguagesLoader.of(context)
                            .translate("Delete placemark from list"),
                        onPressed: () {
                          // remove element from list
                          setState(() {
                            _placesDescriptions.removeAt(index);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        tooltip:
                            LanguagesLoader.of(context).translate("add_marker"),
                        onPressed: () {
                          // add placemark method
                          String _id = widget._markerLoader.generateId();
                          addMarkerFromCategory(
                              _placesDescriptions[index], _id, PrefService.getInt('number_of_markers') + 1);
                          // set selected marker
                          PrefService.setString('selected_marker', _id);
                          // Navigate to the profile screen using a named route.
                          Navigator.pushNamed(context, '/map');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return ListTile(
        title: Text(LanguagesLoader.of(context).translate("no places found"),
            style: footer()),
        leading: Icon(Icons.error_outline),
      );
    }
  }

  Widget _markerAddForm(context) {
    ActionsList _actionsList = ActionsList(widget._markerLoader);
    return Form(
        key: _formKey2,
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
                      color: (PrefService.get('ui_theme') == 'dark')
                          ? Colors.white
                          : Colors.black,
                      tooltip:
                          LanguagesLoader.of(context).translate("Close form"),
                      onPressed: () {
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
            _actionsList.buildActionsList(context, "temporary"),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    // check permission
//    _geolocator.checkGeolocationPermissionStatus().then((permission){
//      // check permission status
//      if(permission != GeolocationStatus.granted){
//        print("GEOLOCATION PERMISSION IS NOT GRANTED YET");
//      }
//      print(permission);
//    });

    // set selected marker to temporary
    PrefService.setString('selected_marker', "temporary");

    // add form radius
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );

    return GestureDetector(
        onTap: (){
      FocusScope.of(context).requestFocus(new FocusNode());
    },
    child: Scaffold(
      appBar: appBar(),
      body:
          // BODY
          PrefService.getString('token') == ''
              ? textInfo(
                  LanguagesLoader.of(context).translate("You need to log") ??
                      '')
              : Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    SlidingUpPanel(
                      color: _preset == 'dark' ? Colors.black : Colors.white,
                      minHeight: 0,
                      padding: EdgeInsets.only(
                        left: 30,
                        right: 30,
                      ),
                      borderRadius: radius,
                      isDraggable: false,
                      defaultPanelState: PanelState.CLOSED,
                      controller: _slidingFormController,
                      panel: _markerAddForm(context),
                      body: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                title: Text(
                                  LanguagesLoader.of(context)
                                      .translate("Community"),
                                  style: header(),
                                ),
                                leading: Icon(Icons.language),
                              ),
                              ListTile(
                                title: Text(
                                  LanguagesLoader.of(context)
                                      .translate("community_descrtiption_1"),
                                  style: bodyText(),
                                ),
                              ),

                              // SizedBox(height: 10),
                              // _buildApproximatedCheckboxField(),

                              SizedBox(height: 10),

                              // dropdown list
                              _buildCategoryTextFieldAndButton(),

                              _placesDescriptions.length != 0 &&
                                      !if_already_added
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          child: addAllPlaces(context),
                                        ),
                                        Expanded(
                                          child: openDefaultMarkerForm(context),
                                        ),
                                        // SizedBox(
                                        //     width: 100,
                                        //     child: _iconChangeButton()
                                        // ),
                                      ],
                                    )
                                  : SizedBox.shrink(),

                              // places cards list
                              SizedBox(
                                height: 400, // fixed height
                                child: _listPlaces(context),
                              ),

                              // Container(
                              //   child: SingleChildScrollView(
                              //     child: Column(
                              //       children: [
                              //         _listPlaces(context)
                              //       ],
                              //     ),
                              //   ),
                              // )

                              // Row(
                              //   children: <Widget>[
                              //     Flexible(child: _listPlaces(context),),
                              //     // more widgets
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    ),
    );
  }
}
