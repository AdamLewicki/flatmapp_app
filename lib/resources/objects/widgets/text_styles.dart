import 'package:flutter/material.dart';

TextStyle header() {
  return TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );
}

TextStyle bodyText({Color color}) {
  if (color != null) {
    return TextStyle(fontSize: 16, color: color);
  } else {
    return TextStyle(
      fontSize: 16,
    );
  }
}

TextStyle formButtonText({Color color}) {
  if (color != null) {
    return TextStyle(fontSize: 14, color: color);
  } else {
    return TextStyle(
      fontSize: 14,
    );
  }
}

TextStyle addMarkerText({Color color}) {
  if (color != null) {
    return TextStyle(fontSize: 16, color: color);
  } else {
    return TextStyle();
  }
}

TextStyle footer() {
  return TextStyle(
    fontStyle: FontStyle.italic,
    fontSize: 12,
  );
}

TextStyle sideBarMenuStyle() {
  return TextStyle(
    fontSize: 16,
  );
}

TextStyle sideBarMenuStyleGrey() {
  return TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );
}

Padding textInfo(String text) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Align(
      alignment: Alignment.topCenter,
      child: Card(
        elevation: 2,
        color: Colors.grey.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  );
}

InputDecoration textFieldStyle({
  String labelTextStr = "",
  String hintTextStr = "",
}) {
  return InputDecoration(
    contentPadding: EdgeInsets.all(12),
    labelText: labelTextStr,
    hintText: hintTextStr,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

BoxDecoration buttonFieldStyle() {
  return BoxDecoration(
    border: Border.all(width: 0.5),
    borderRadius: BorderRadius.circular(10),
  );
}

//
