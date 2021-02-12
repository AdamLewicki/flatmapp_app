import 'dart:convert';

import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/loaders/net_loader.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:preferences/preference_service.dart';

class LogInRoute extends StatefulWidget {
  @override
  _LogInRouteState createState() => _LogInRouteState();
}

// Putting language dictionaries seams done

class _LogInRouteState extends State<LogInRoute> {
  // selected menu in navigator
  int _selectedIndex = 0;

  // internet service
  NetLoader netLoader = NetLoader();

  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'username': '',
    'password': '',
  };
  final focusPassword = FocusNode();

  Widget _buildUsernameField(context) {
    return TextFormField(
      style: bodyText(),
      key: Key('login_email_field_key'),
      decoration: textFieldStyle(
          labelTextStr: LanguagesLoader.of(context).translate("Username"),
          hintTextStr:
              LanguagesLoader.of(context).translate("Your username goes here")),
      validator: (String value) {
//        if (!RegExp(
//            r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
//            .hasMatch(value)) {
        if (value == '') {
          return LanguagesLoader.of(context)
              .translate("Invalid username format");
        }
        return null;
      },
      onSaved: (String value) {
        _formData['username'] = value;
      },
      onChanged: (String value) {
        _formData['username'] = value;
      },
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(focusPassword);
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      style: bodyText(),
      key: Key('login_password_field_key'),
      decoration: textFieldStyle(
          labelTextStr: LanguagesLoader.of(context).translate("Password"),
          hintTextStr:
              LanguagesLoader.of(context).translate("Your password goes here")),
      obscureText: true,
      validator: (String value) {
        if (value.isEmpty) {
          return LanguagesLoader.of(context)
              .translate("Password can not be empty");
        }
        return null;
      },
      onSaved: (String value) {
        _formData['password'] = value;
      },
      focusNode: focusPassword,
      onFieldSubmitted: (value) {
        _formData['password'] = value;
        _submitForm();
      },
    );
  }

  Future<void> _submitForm() async {
    // validate form
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      bool connected = await netLoader.checkNetworkConnection();
      if (connected) {
        // send credentials to server and get the response
        http.Response _response = await netLoader.getToken(
            endpoint: '/api/account/login/', content: _formData);

        String _token = json.decode(_response.body)["token"].toString();
        // if there is token in response
        if (_token != null && _token != "null") {
          // save token to global variables
          PrefService.setString("token", _token);
          // save login to global variables
          PrefService.setString("login", _formData['username'].toString());

          // reset view
          resetView(context);
        } else {
          // there is no token in response
          print("No token detected!");
          print(_response.body);
        }
      } else {
        netLoader.showToast(
            LanguagesLoader.of(context).translate("Network connection is off"));
      }
    }
  }

  void _logOut() {
    PrefService.setString('token', '');
    Navigator.pushNamed(context, '/login');
  }

  Widget _logInForm() {
    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20),
            _buildUsernameField(context),
            SizedBox(height: 20),
            _buildPasswordField(),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 0.5),
                borderRadius: BorderRadius.all(
                    Radius.circular(10.0) //         <--- border radius here
                    ),
              ), //       <--- BoxDecoration here
              child: ListTile(
                title: Text(
                  LanguagesLoader.of(context).translate("Log In"),
                  style: bodyText(),
                  textAlign: TextAlign.left,
                ),
                leading: Icon(Icons.input),
                onTap: () {
                  _submitForm();
                },
              ),
            ),
          ],
        ));
  }

  Widget _logOutForm() {
    return Form(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
          SizedBox(height: 30),
          Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  LanguagesLoader.of(context)
                      .translate("Are you sure you want to log out?"),
                  style: header(),
                ),
              ]),
          SizedBox(height: 40),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: buttonFieldStyle(),
                  child: ListTile(
                    key: Key("logout_yes_list_tile"),
                    title: Text(
                      LanguagesLoader.of(context).translate("Yes"),
                      style: bodyText(),
                    ),
                    leading: Icon(Icons.check),
                    onTap: () {
                      _logOut();
                    },
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: buttonFieldStyle(),
                  child: ListTile(
                    key: Key("logout_no_list_tile"),
                    title: Text(
                      LanguagesLoader.of(context).translate("No"),
                      style: bodyText(),
                      textAlign: TextAlign.right,
                    ),
                    trailing: Icon(Icons.close),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
//          Row(
//            mainAxisSize: MainAxisSize.max,
//              mainAxisAlignment: MainAxisAlignment.spaceBetween,
//            children: <Widget>[
//              textFieldButton(text: "No", onPressedMethod: (){
//                resetView(context);
//              }),
//              textFieldButton(text: "Yes", onPressedMethod: _logOut),
//              ]
//          )
        ]));
  }

  void resetView(BuildContext context) {
    // reset Widget
    String initScreen = PrefService.getString('start_page');
    switch (initScreen) {
      case 'About':
        {
          initScreen = '/about';
        }
        break;
      case 'Community':
        {
          initScreen = '/community';
        }
        break;
      case 'Log In':
        {
          initScreen = '/login';
        }
        break;
      case 'Map':
        {
          initScreen = '/map';
        }
        break;
      case 'Profile':
        {
          initScreen = '/profile';
        }
        break;
      case 'Settings':
        {
          initScreen = '/settings';
        }
        break;
      default:
        {
          throw Exception('wrong start_page value: $initScreen');
        }
        break;
    }

    Navigator.pushNamed(context, initScreen);

    // show message
    Fluttertoast.showToast(
      msg: "Logged in",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    // show licence agreement
//    Future.delayed(Duration.zero, () => showLicenceAgreement(context));
    return GestureDetector(
        onTap: (){
      FocusScope.of(context).requestFocus(new FocusNode());
    },
    child: Scaffold(
      appBar: appBar(),
      key: Key("login_route_key"),
      // BODY FORM
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            PrefService.getString('token') == '' ? _logInForm() : _logOutForm(),
      ),

      // SIDE PANEL MENU
      drawer: sideBarMenu(context),

      bottomNavigationBar: PrefService.getString('token') != ''
          ? SizedBox.shrink()
          : BottomNavigationBar(
              key: Key("login_button"),
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.input),
                  title: Text(LanguagesLoader.of(context).translate("Log In")),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.queue),
                  title:
                      Text(LanguagesLoader.of(context).translate("Register")),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.cloud_off),
                  title: Text(
                      LanguagesLoader.of(context).translate("Use as guest")),
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.green,
              onTap: (int index) {
                switch (index) {
                  case 0:
                    // log in
                    _submitForm();
                    break;
                  case 1:
                    // move to register screen
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/register');
                    break;
                  case 2:
                    // return to default screen
                    // Navigator.popUntil(
                    //   context,
                    //   ModalRoute.withName(Navigator.defaultRouteName)
                    // );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    break;
                }
              }),
    ),
    );
  }
}
