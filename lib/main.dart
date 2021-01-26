import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flatmapp/resources/extensions.dart';
import 'package:flatmapp/resources/objects/loaders/languages/language_constants.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_localizations_delegate.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/routes/AboutRoute.dart';
import 'package:flatmapp/resources/routes/ActionParametersRoute.dart';
import 'package:flatmapp/resources/routes/ActionsRoute.dart';
import 'package:flatmapp/resources/routes/ChangePasswordRoute.dart';
import 'package:flatmapp/resources/routes/CommunityIconsRoute.dart';
import 'package:flatmapp/resources/routes/CommunityRoute.dart';
import 'package:flatmapp/resources/routes/EraseAccountRoute.dart';
import 'package:flatmapp/resources/routes/IconsRoute.dart';
import 'package:flatmapp/resources/routes/LogInRoute.dart';
import 'package:flatmapp/resources/routes/MapRoute.dart';
import 'package:flatmapp/resources/routes/MarkersRoute.dart';
import 'package:flatmapp/resources/routes/ProfileRoute.dart';
import 'package:flatmapp/resources/routes/RegisterRoute.dart';
import 'package:flatmapp/resources/routes/SettingsRoute.dart';
import 'package:flatmapp/resources/routes/UpdateMarkerLocation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter\_localizations/flutter\_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:preferences/preferences.dart';

// store chosen starting route
String initScreen;

// data loader
final MarkerLoader _markerLoader = MarkerLoader();

void _setUserPosition() async {
  // move temporary marker to user's location
//  Geolocator().isLocationServiceEnabled().then((status) async {
//    if (status == false) {
//      print("GEOLOCATION MODULE IS TURNED OFF");
//    } else {
//      Position _position = await Geolocator()
//          .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//      _markerLoader.addTemporaryMarker(_position.toLatLng());
//      // send position to garbage collector
//      _position = null;
//    }
//  });

  bool _geoEnabled = await Geolocator().isLocationServiceEnabled();
  if (_geoEnabled) {
    print("ANASCL geo location  enabled");
    Position _position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _markerLoader.addTemporaryMarker(_position.toLatLng());
    // send position to garbage collector
    _position = null;
  }
}

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
    "cloud_enabled": true,
    "map_enabled": true,
    'selected_marker': 'temporary',
    'selected_action': 0,
    'selected_icon': 'default',
    'token': '',
    'login': '',
    'isolate_spawned': false,
    'community_icon': 'default',
    'licence_accepted': false
  });

  // get start page
  initScreen = PrefService.getString('start_page');
  switch (initScreen) {
    case 'Map':
      {
        initScreen = '/map';
      }
      break;
    case 'Markers':
      {
        initScreen = '/markers';
      }
      break;
    case 'Profile':
      {
        initScreen = '/profile';
      }
      break;
    case 'Community':
      {
        initScreen = '/community';
      }
      break;
    case 'Settings':
      {
        initScreen = '/settings';
      }
      break;
    case 'About':
      {
        initScreen = '/about';
      }
      break;
    case 'Log In':
      {
        initScreen = '/login';
      }
      break;
    default:
      {
        throw Exception('wrong start_page value: $initScreen');
      }
      break;
  }

  await _markerLoader.loadMarkers();

  // check permission
  if (!(await Permission.location.request().isGranted)) {
    // request access to location
    Permission.location.request();
  }

  _setUserPosition();

  // disable device orientation changes and force portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new MyApp());
  });

  //runApp(MyApp());
}

class MyApp extends StatefulWidget {

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>();
    state.setLocale(newLocale);
  }
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Locale _locale;
  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }
  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        this._locale = locale;
      });
    });
    super.didChangeDependencies();
  }
  @override
  Widget build(BuildContext context) {
    // load app
    return new DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) =>
            new ThemeData(brightness: brightness, accentColor: Colors.green),
        themedWidgetBuilder: (context, theme) {
          return MaterialApp(
            title: 'FlatMApp',
            debugShowCheckedModeBanner: false,
            theme: theme,
            initialRoute: initScreen,
            locale: _locale,
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
              '/action_parameters': (context) =>
                  ActionParametersRoute(_markerLoader),
              '/markers': (context) => MarkersRoute(_markerLoader),

            },
            // TODO add all languages available here
            supportedLocales: [
              const Locale('pl', 'PL'),
              const Locale('en', 'US'),
              const Locale('es', 'ES'),
            ],

            localizationsDelegates: [
              const LanguagesLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate
            ],
            localeResolutionCallback:
                (Locale locale, Iterable<Locale> supportedLocales) {
              for (Locale supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode ||
                    supportedLocale.countryCode == locale.countryCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
          );
        });
  }
}
