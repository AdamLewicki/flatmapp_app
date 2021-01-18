//// TODO REMOVE THIS SCRIPT
//
//import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
//import 'package:flatmapp/resources/objects/loaders/trigger_loader.dart';
//
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:geolocator/geolocator.dart';
//
//
//// https://pub.dev/packages/flutter_isolate
//// =============================================================================
//// -------------------- TRIGGER ISOLATE SECTION --------------------------------
//Future<dynamic> onSelectNotification(String payload) async {
//  // TODO function after opening notification
////  await Navigator.push(
////    context,
////    MaterialPageRoute(builder: (context) => AboutRoute()),
////  );
//}
//
//// This function happens in the isolate
//// void triggerEntryPoint(BuildContext context) async { TODO remove or use test section
//void triggerEntryPoint(var message) async {
//  // THIS IS "MAIN" FOR SUBPROCESS
//
//  // marker loader init
//  final MarkerLoader _markerLoader = MarkerLoader();
//  await _markerLoader.loadMarkers();
//
//  // geolocator API:
//  // https://pub.dev/documentation/geolocator/latest/geolocator/Geolocator-class.html
//  Geolocator _geolocator = Geolocator();
//
//  // notifications on location change
//  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
//
//  // check permission
//  _geolocator.isLocationServiceEnabled().then((status){
//    if (status == false) {
//      print("GEOLOCATION MODULE IS TURNED OFF");
//    } else {
//      _geolocator.checkGeolocationPermissionStatus().then((permission) {
//        // check permission status
//        if (permission != GeolocationStatus.granted) {
//          print("GEOLOCATION PERMISSION IS NOT GRANTED YET");
//        }
//        print(permission);
//      });
//    }
//  });
//
//
//  // init notifications
//  var initializationSettingsAndroid =
//  new AndroidInitializationSettings('mipmap/ic_launcher');
//  var initializationSettingsIOS = new IOSInitializationSettings();
//  var initializationSettings = new InitializationSettings(
//      initializationSettingsAndroid, initializationSettingsIOS
//  );
//  _flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
//  _flutterLocalNotificationsPlugin.initialize(
//    initializationSettings,
//    onSelectNotification: onSelectNotification
//  );
//
//  // initiate trigger loader in isolated process
//  // ignore: unused_local_variable
//  TriggerLoader _triggerLoader = TriggerLoader(
//      _geolocator,
//      _markerLoader,
//      _flutterLocalNotificationsPlugin
//  );
//}