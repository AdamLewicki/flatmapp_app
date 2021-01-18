import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';

class SettingsRoute extends StatefulWidget {
  @override
  _SettingsRouteState createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  PreferencePage easyPreferences() {
    return PreferencePage([
      PreferenceTitle(LanguagesLoader.of(context).translate("General"),
          style: header()),
      DropdownPreference(
        LanguagesLoader.of(context).translate("Start Page"),
        'start_page',
        defaultVal: 'Map',
        values: ['Map', 'Markers', 'Profile', 'Community', 'Settings', 'About'],
        // onChange: (String value) {
        //   value = LanguagesLoader.of(context).getKey(value);
        // }
      ),

      // LanguagesLoader.of(context).getKey("light")

      PreferenceTitle(LanguagesLoader.of(context).translate("Personalization"),
          style: header()),
      DropdownPreference(
        LanguagesLoader.of(context).translate('Change background theme'),
        'ui_theme',

        // defaultVal: LanguagesLoader.of(context).translate("light"),
        // values: [
        //   LanguagesLoader.of(context).translate("light"),
        //   LanguagesLoader.of(context).translate("dark")
        // ],

        defaultVal: "light",
        values: ["light", "dark"],
        onChange: (value) {
          // if(value == LanguagesLoader.of(context).getKey("light")){
          if (value == "light") {
            DynamicTheme.of(context).setBrightness(Brightness.light);
          } else {
            DynamicTheme.of(context).setBrightness(Brightness.dark);
          }
        },
      ),

      // PreferenceTitle('Advanced', style: header()),
      // CheckboxPreference(
      //   'Enable Advanced Features',
      //   'advanced_enabled',
      //   onChange: () {
      //     setState(() {});
      //   },
      //   onDisable: () {
      //     PrefService.setBool('show_exp', false);
      //   },
      // ),
      // PreferenceHider([
      //   SwitchPreference(
      //     'Enable cloud save',
      //     'cloud_enabled',
      //     defaultVal: true,
      //   ),
      //   SwitchPreference(
      //     'Enable map loading',
      //     'map_enabled',
      //     defaultVal: true,
      //   ),
      //   PreferenceText(
      //     'Remove cloud backup markers',
      //     leading: Icon(Icons.cloud_off),
      //     onTap: () {
      //       _netLoader.removeBackup();
      //     },
      //   ),
      //   PreferenceText(
      //     'Remove account',
      //     leading: Icon(Icons.remove_circle),
      //     onTap: () {
      //       // move to account removal form
      //       Navigator.pushNamed(context, '/erase_account');
      //     },
      //   ),
      // ], '!advanced_enabled'), // Use ! to get reversed boolean values
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // show licence agreement
//    Future.delayed(Duration.zero, () => showLicenceAgreement(context));
    return Scaffold(
      appBar: appBar(),
      body: easyPreferences(),

      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}
