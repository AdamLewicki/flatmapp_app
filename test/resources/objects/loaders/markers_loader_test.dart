import 'package:flatmapp/resources/objects/models/flatmapp_marker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
//  await PrefService.init();
  group("Markers_Loader", () {
    test("Simple adding marker test", (){
      final markerLoader = MarkerLoader();

      markerLoader.addMarker(
          id: "test1",
          position: LatLng(-43.0, 170.0),
          icon: "default",
          title: "test marker 1",
          description: "marker presenting chosen position 1",
          range: 12.5,
          actions: null,
          queue: 1,
          groupId: "test group"
      );

      FlatMappMarker _marker = markerLoader.getMarkerDescription("test1");

      expect(_marker.position_x, -43.0);
      expect(_marker.position_y, 170.0);
      expect(_marker.title, "test marker 1");
      expect(_marker.description, "marker presenting chosen position 1");
      expect(_marker.range, 12.5);
      expect(_marker.icon, "default");
      expect(_marker.actions, null);
      expect(_marker.queue, 1);
      expect(_marker.groupId, "test group");

    });

    test("Simple editing markers test", (){
      final markerLoader = MarkerLoader();

      expect(0, markerLoader.getDescriptionsKeys().length);

      markerLoader.addMarker(
          id: "test1",
          position: LatLng(-43.0, 170.0),
          icon: "default",
          title: "test marker 1",
          description: "marker presenting chosen position 1",
          range: 12.5,
          actions: null,
          queue: 1,
          groupId: 'test group'
      );

      expect(1, markerLoader.getDescriptionsKeys().length);

      markerLoader.addMarker(
          id: "test1",
          position: LatLng(-73.0, 10.0),
          icon: "pointer_place",
          title: "test marker 1 edited",
          description: "marker presenting chosen position 1 edited",
          range: 20.0,
          actions: null,
          queue: 3,
          groupId: "test group edited"
      );

      FlatMappMarker _marker = markerLoader.getMarkerDescription("test1");

      expect(_marker.position_x, -73.0);
      expect(_marker.position_y, 10.0);
      expect(_marker.icon, "pointer_place");
      expect(_marker.title, "test marker 1 edited");
      expect(_marker.description, "marker presenting chosen position 1 edited");
      expect(_marker.range, 20.0);
      expect(_marker.actions, null);
      expect(_marker.queue, 3);
      expect(_marker.groupId, "test group edited");
      expect(1, markerLoader.getDescriptionsKeys().length);
    });
  });
}