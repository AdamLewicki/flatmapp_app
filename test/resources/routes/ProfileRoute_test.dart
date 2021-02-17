import 'package:flatmapp/resources/objects/loaders/group_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:preferences/preference_service.dart';
import 'package:flatmapp/resources/routes/ProfileRoute.dart';

Future<void> main()
async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await PrefService.init(prefix: 'pref_');
  testWidgets('Checking if ProfileRoute wiget can be loaded',
          (WidgetTester tester) async {
        final markerLoader = MarkerLoader();
        final groupLoader = GroupLoader();
        await tester.pumpWidget(
          MaterialApp(
              routes: {
                '/about': (context) => ProfileRoute(markerLoader, groupLoader),
              },
              home: ProfileRoute(markerLoader, groupLoader)
          ),
        );

        expect(find.byType(ProfileRoute), findsOneWidget);
      });
}