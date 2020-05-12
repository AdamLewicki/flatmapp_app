import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_form_fields.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:http/http.dart' as http;
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/data/net_loader.dart';

import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:preferences/preference_service.dart';


class LogInRoute extends StatefulWidget {

  @override
  _LogInRouteState createState() => _LogInRouteState();
}

class _LogInRouteState extends State<LogInRoute> {

  // internet service
  NetLoader netLoader = NetLoader();

  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData =
  {
    'username': '',
    'password': '',
  };
  final focusPassword = FocusNode();

  Widget _buildEmailField(context) {
    return TextFormField(
      style: bodyText(),
      decoration: textFieldStyle(
          labelTextStr: "Email",
          hintTextStr: "Your email goes here"
      ),
      // ignore: missing_return
      validator: (String value) {
        if (!RegExp(
            r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
            .hasMatch(value)) {
          return 'Invalid email format';
        }
        return null;
      },
      onSaved: (String value) {
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
      decoration: textFieldStyle(
          labelTextStr: "Password",
          hintTextStr: "Your password goes here"
      ),
      obscureText: false,
      // ignore: missing_return
      validator: (String value) {
        if (value.isEmpty) {
          return 'Password can not be empty';
        }
        return null;
      },
      onSaved: (String value) {
        _formData['password'] = value;
      },
      focusNode: focusPassword,
      onFieldSubmitted: (v) {
        _submitForm();
      },
    );
  }

  Future<void> _submitForm() async {
    // validate form
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      //print('FormData : ' + json.encode(_formData));
      // send credentials to server and get the response
      http.Response _response = await netLoader.postForToken(
          endpoint:'/api/account/login/', content:_formData);
      //print('resonse:' + _response.body);
      // if there is token in response
      if(json.decode(_response.body)["token"] != null)
        {
          // save token to global variables
          PrefService.setString("token", json.decode(_response.body)["token"]);

          // reset Widget
          String initScreen = PrefService.get('start_page');
          switch(initScreen) {
            case 'About': {initScreen = '/about';} break;
            case 'Community': {initScreen = '/community';} break;
            case 'Log In': {initScreen = '/login';} break;
            case 'Map': {initScreen = '/map';} break;
            case 'Profile': {initScreen = '/profile';} break;
            case 'Settings': {initScreen = '/settings';} break;
            default: { throw Exception('wrong start_page value: $initScreen'); } break;
          }
          Navigator.pushNamed(context, initScreen);
        }
      //print('Token : ' + PrefService.getString("token"));
    }
  }

  void _logOut(){
    PrefService.setString('token', null);
    Navigator.pushNamed(context, '/login');
}

  Widget _logInForm(){
    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20),
            _buildEmailField(context),
            SizedBox(height: 20),
            _buildPasswordField(),
            SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                textFieldButton(text: "Log in", onPressedMethod: _submitForm),
                SizedBox(width: 20),
                textFieldButton(text: "Sign up", onPressedMethod: _submitForm),
                SizedBox(width: 20),
                textFieldButton(text: "Use as guest", onPressedMethod: _submitForm),
              ],
            ),
          ],
        )
    );
  }

  Widget _logOutForm(){
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
            'Are you sure you want to log out?',
            style: header(),
            ),
          ]
        ),
          SizedBox(height: 40),
          textFieldButton(text: "Yes", onPressedMethod: _logOut),
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),

      // BODY FORM
      body: PrefService.getString('token') == null ? _logInForm() : _logOutForm(),

      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}
