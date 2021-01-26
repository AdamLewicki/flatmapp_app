


import 'dart:async';

import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:preferences/preference_service.dart';


class  UpdateMarkerLocation  extends StatefulWidget {
  LatLng latLng =new LatLng(0.0, 0.0);
  final ValueSetter<LatLng> onUpdateButton;

  UpdateMarkerLocation(this.latLng, this.onUpdateButton, {Key key }) : super(key: key);

  @override
  _UpdateMarkerLocationState createState() => _UpdateMarkerLocationState();
}

class _UpdateMarkerLocationState extends State< UpdateMarkerLocation > {

  List<Marker> markers=[];
  GoogleMapController _mapController;
  final String _preset = PrefService.getString('ui_theme');
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    markers.add(Marker(markerId: MarkerId("value"),
      draggable: true,
      onTap: (){

      },
      position: LatLng(widget.latLng.latitude,widget.latLng.longitude),
    )
    );
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: appBar(title: "Update Marker Position"),
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: LatLng(widget.latLng.latitude,widget.latLng.longitude),
                zoom: 16.0,
              ),
              markers: Set.from(markers),
              onMapCreated: (controller) => _onMapCreated(controller),
              onTap: (position){
                _moveToPosition(position);
              },
              zoomControlsEnabled: false,
            ),
            Align(alignment: Alignment.bottomCenter,
              child:Container(
                margin: EdgeInsets.all(10.0),
                child:RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  onPressed: () {
                    widget.onUpdateButton(widget.latLng);
                    Navigator.pop(context);
                  },
                  color: Colors.white,
                  textColor: Colors.green,
                  child: Text("Update Position".toUpperCase(),
                      style: TextStyle(fontSize: 14)),
                ),
              ),),
          ],
          )
      ),
    );
  }
  // Called when the Google Map widget is created.
  // Updates the map loading state and initializes markers.
  void _onMapCreated(GoogleMapController controller) {
    _setStyle(controller);
    // crete map controller
    _mapController=controller;
    setState(() {

    });
  }
  // TextStyle bodyText({Color color}) {
  //   if (color != null) {
  //     return TextStyle(fontSize: 16, color: color);
  //   } else {
  //     return TextStyle(
  //       fontSize: 16,
  //     );
  //   }
  // }
  void _moveToPosition(LatLng position){
    setState(() {
      markers = [];
      widget.latLng=position;
      markers.add(Marker(markerId: MarkerId(position.toString()),
        position: LatLng(position.latitude,position.longitude),
      ));
      // _mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target:position,zoom: 16.0)));

    });

  }
  void _setStyle(GoogleMapController controller) async {
    String value = await DefaultAssetBundle.of(context)
        .loadString('assets/map_style_$_preset.json');
    controller.setMapStyle(value);
  }
}
