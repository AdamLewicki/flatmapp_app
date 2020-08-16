import 'package:flatmapp/resources/routes/ActionParametersRoute.dart';
import 'package:flatmapp/resources/routes/ActionsRoute.dart';
import 'package:flatmapp/resources/routes/ChangePasswordRoute.dart';
import 'package:flatmapp/resources/routes/EraseAccountRoute.dart';
import 'package:flatmapp/resources/routes/LogInRoute.dart';
import 'package:flatmapp/resources/routes/MapRoute.dart';
import 'package:flatmapp/resources/routes/ProfileRoute.dart';
import 'package:flatmapp/resources/routes/IconsRoute.dart';
import 'package:flatmapp/resources/routes/CommunityRoute.dart';
import 'package:flatmapp/resources/routes/CommunityIconsRoute.dart';
import 'package:flatmapp/resources/routes/RegisterRoute.dart';
import 'package:flatmapp/resources/routes/SettingsRoute.dart';
import 'package:flatmapp/resources/routes/AboutRoute.dart';

import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/isolated_subprocess.dart';

import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:preferences/preferences.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

import 'package:flutter/services.dart';
// import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:permission_handler/permission_handler.dart';


// store chosen starting route
String initScreen;

// data loader
final MarkerLoader _markerLoader = MarkerLoader();

// =============================================================================
// ----------------------- MAIN PROCESS SECTION --------------------------------

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefService.init(prefix: 'pref_');
  await GlobalConfiguration().loadFromAsset("app_settings");

  PrefService.setDefaultValues({
    'project_description': 'FlatMapp prototype',
    'start_page': 'Map',
    'ui_theme': 'light',
    "cloud_enabled": false,
    'selected_marker': 'temporary',
    'selected_action': 0,
    'selected_icon': 'default',
    'isolate_port': 0,
    'token': '',
    'login': '',
    'isolate_enabled': false,
    'isolate_spawned': false,
    'community_icon': 'default'
  });

  // get start page
  initScreen = PrefService.getString('start_page');
  switch(initScreen) {
    case 'Map': {initScreen = '/map';} break;
    case 'Profile': {initScreen = '/profile';} break;
    case 'Community': {initScreen = '/community';} break;
    case 'Settings': {initScreen = '/settings';} break;
    case 'About': {initScreen = '/about';} break;
    case 'Log In': {initScreen = '/login';} break;
    default: { throw Exception('wrong start_page value: $initScreen'); } break;
  }

  await _markerLoader.loadMarkers();

  // check permission
  if (!(await Permission.location.request().isGranted)) {
    // request access to location
    Permission.location.request();
  }

  if(PrefService.getBool('isolate_enabled') && !PrefService.getBool('isolate_spawned')){

//    triggerEntryPoint(null);

    // initiate isolated subprocess
    // ignore: unused_local_variable
//    final isolate = await FlutterIsolate.spawn(
//        triggerEntryPoint,
//        ""
//    );
//
//    PrefService.setString('isolate_port', isolate.controlPort.toString());
//    print("isolate control port: " + isolate.controlPort.toString());

    // PrefService.setBool('isolate_spawned', true);
  }

  // disable device orientation changes and force portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new MyApp());
  });
  // runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context){

    // initiate isolated subprocess TODO remove or use test section
    // ignore: unused_local_variable
//    final isolate = await FlutterIsolate.spawn(
//        triggerEntryPoint,
//        context
//    );
//
//    PrefService.setString('isolate_port', isolate.controlPort.toString());
//    print("isolate control port: " + isolate.controlPort.toString());

    return new DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) => new ThemeData(
          brightness: brightness,
          accentColor: Colors.green
      ),
      themedWidgetBuilder: (context, theme){
        return MaterialApp(
          title: 'FlatMApp',
          debugShowCheckedModeBanner: false,
          theme: theme,
          initialRoute: initScreen,
          routes: {
            // When navigating to the "/name" route, build the NameRoute widget.
            '/map': (context) => MapRoute(_markerLoader),
            '/profile': (context) => ProfileRoute(_markerLoader),
            '/community': (context) => CommunityRoute(_markerLoader),
            '/settings': (context) => SettingsRoute(),
            '/about': (context) => AboutRoute(),
            '/login': (context) => LogInRoute(),
            '/icons': (context) => IconsRoute(),
            '/community_icons': (context) => CommunityIconsRoute(),
            '/actions': (context) => ActionsRoute(_markerLoader),
            '/change_password': (context) => ChangePasswordRoute(),
            '/erase_account': (context) => EraseAccountRoute(),
            '/register': (context) => RegisterRoute(),
            '/action_parameters': (context) => ActionParametersRoute(_markerLoader)
          },
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              child: _PageView(),
            ),
          ),
        );
      }
    );
  }
}

class _PageView extends StatefulWidget {
  @override
  _PageViewState createState() => _PageViewState();
}

class _PageViewState extends State<_PageView> {

  PageController _pageViewController = PageController(
    initialPage: 0,
  );

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageViewController,
      children: [
        MapRoute(_markerLoader),
        ProfileRoute(_markerLoader),
        CommunityRoute(_markerLoader),
        SettingsRoute(),
        AboutRoute(),
        LogInRoute(),
      ],
    );
  }
}
