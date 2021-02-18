import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flatmapp/resources/objects/loaders/group_loader.dart';
import 'package:flatmapp/resources/objects/loaders/markers_loader.dart';
import 'package:flatmapp/resources/objects/models/flatmapp_action.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:preferences/preferences.dart';

class NetLoader {
  // ignore: deprecated_member_use
  String _serverURL = GlobalConfiguration().getString("server_url");

  Future<bool> checkNetworkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      print("connected to mobile network");
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      print("connected to WIFI network");
      return true;
    }
    print("not connected to any network");
    return false;
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void analyseResponse(http.Response response) {
    if (response.statusCode >= 300) {
      print(response.statusCode);
      throw HttpException(response.body);
    }
    // verify if response can be parsed
    try {
      var decoded = json.decode(response.body);
      if (!(decoded is Map) && !(decoded is List)) {
        throw Exception(
            "Can not decode response body to correct JSON\n\n" + response.body);
      }
    } on FormatException catch (e) {
      print("Format exception error\n$e");
      print("Response body: ${response.body}");
    }
  }

  Future<http.Response> _postToServer(
      {String endpoint, List<Map<String, dynamic>> content}) async {
    String _token = PrefService.getString('token');
    http.Response _response = await http.post(_serverURL + endpoint,
        headers: {
          "Content-type": "application/json",
          HttpHeaders.authorizationHeader: "Token $_token",
        },
        body: json.encode(content)
      // body:
    );
    // verify response
    analyseResponse(_response);
    return _response;
  }

  Future<http.Response> _putToServer(
      {String endpoint, Map<String, dynamic> content}) async {
    String _token = PrefService.getString('token');
    http.Response _response = await http.put(_serverURL + endpoint,
        headers: {
          "Content-type": "application/json",
          HttpHeaders.authorizationHeader: "Token $_token",
        },
        body: json.encode(content));
    // verify response
    analyseResponse(_response);
    return _response;
  }

  Future<http.Response> _putToServer2(
      {String endpoint, Map<String, dynamic> content}) async {
    http.Response _response = await http.post(_serverURL + endpoint,
        headers: {
          "Content-type": "application/json",
        },
        body: json.encode(content));
    // verify response
    analyseResponse(_response);
    return _response;
  }

  Future<List<dynamic>> _getFromServer(
      {String endpoint, String content}) async {
    String _token = PrefService.getString('token');
    http.Response _response = await http.get(
      _serverURL + endpoint,
      headers: {
        "Content-type": "application/json",
        HttpHeaders.authorizationHeader: "Token $_token",
      },
    );
    // verify response
    analyseResponse(_response);
    return List<dynamic>.from(json.decode(utf8.decode(_response.bodyBytes)));
  }

  Future<http.Response> _deleteToServer({String endpoint}) async {
    String _token = PrefService.getString('token');
    http.Response _response = await http.delete(
      _serverURL + endpoint,
      headers: {
        "Content-type": "application/json",
        HttpHeaders.authorizationHeader: "Token $_token",
      },
    );
    // verify response
    analyseResponse(_response);
    PrefService.setString('token', '');
    return _response;
  }

  // ------------------------------------------------------------------------
  Future<http.Response> getToken(
      {String endpoint, Map<String, dynamic> content}) async {
    http.Response _response;
    try {
      _response = await http.post(_serverURL + endpoint,
          headers: {
            "Content-type": "application/json",
          },
          body: json.encode(content));
      // verify response
      analyseResponse(_response);
    } on SocketException catch (e) {
      print(e);
      showToast("Error: request timed out");
    } on HttpException catch (e) {
      print(e);
      showToast("Error: Unable to log in with provided credentials.");
    }
    return _response;
  }

  Future<void> postBackup(
      BuildContext context, MarkerLoader markerLoader, GroupLoader groupLoader) async {
    bool connected = await checkNetworkConnection();
    if (connected) {
      try {
        List<Map<String, dynamic>> parsedMarkers = [];
        List<Map<String, dynamic>> parsedGroups = [];

        // parse markers to form acceptable in server interface
        markerLoader.getMarkersDescriptions().forEach((key, value) {
          // TODO can not store temporary marker in backup due to the:
          // empty title
          // empty name
          // permanent id (temporary) equal for all users
          // impossibility of recovering temporary data -
          // it is indistinguishable from other markers
          if (key != "temporary") {
            parsedMarkers.add({
              "Action_Name": value.actions,
              "position_x": value.position_x,
              "position_y": value.position_y,
              "_range": value.range,
              // TODO determine what action_position means
              // "action_position": value.action_position,
              "title": value.title,
              "icon": value.icon,
              "description": value.description,
              "queue": value.queue,
              // TODO determine what action_detail means
              // "action_detail": "none",
            });
          }
        });

        groupLoader.getGroupsMap().forEach((key, value) {
          parsedGroups.add({
            "Action_Name": value.actions,
            "_range": value.range,
            "Group_Id": key,
            "name": value.name,
            "icon": value.icon,
          });
        });

        // send parsed markers
        await _postToServer(
          endpoint: "/api/backup/",
          content: parsedMarkers,
        );

        print(json.encode(parsedGroups));

//        await _postToServer(
//          endpoint: "/api/backup/",
//          content: parsedGroups,
//        );

        showToast("Backup uploaded successfully");
      } on SocketException catch (e) {
        print(e);
        showToast("Error: request timed out");
      } on HttpException catch (e) {
        print(e);
        showToast("Error: server could not process backup");
      }
    } else {
      showToast("Network connection is off");
    }
  }

  // parse list from backup to marker actions list
  List<FlatMappAction> toActionsList(List<dynamic> actionsList) {
    List<FlatMappAction> result = [];
    actionsList.forEach((element) {
      try {
        if (element != null) {
          result.add(FlatMappAction.fromJson(element));
        } else {
          print("action is null");
        }
      } on Exception catch (e) {
        print("action parsing error:\n$e");
      }
    });
    return result;
  }

  // odczyt znaczników z bazy
  Future<void> getBackup(
      BuildContext context, MarkerLoader markerLoader, GroupLoader groupLoader) async {
    bool connected = await checkNetworkConnection();
    if (connected) {
      try {
        List<dynamic> parsedMarkers = await _getFromServer(
          endpoint: "/api/backup/",
        );
        // TODO replace endpoint to one which will be set up on server
        List<dynamic> parsedGroups = await _getFromServer(
          endpoint: "/api/backup/",
        );

        // reset focused marker
        PrefService.setString("selected_marker", 'temporary');

        if (parsedMarkers.isEmpty) {
          showToast("Backup is empty");
        } else {
          // remove markers from local storage
          markerLoader.removeAllMarkers();
          groupLoader.removeAllGroups();
          // add markers
          parsedMarkers.forEach((marker) {
            markerLoader.addMarker(
              id: markerLoader.generateId(),
              position: LatLng(marker['position_x'], marker['position_y']),
              icon: marker['icon'].toString(),
              title: marker['title'].toString(),
              description: marker['description'].toString(),
              range: marker['_range'],
              queue: marker['queue'],
              actions: toActionsList(List<dynamic>.from(marker['Action_Name'])),
              groupId: marker['groupId'],
            );
            int number_of_markers = PrefService.getInt('number_of_markers');
            PrefService.setInt('number_of_markers', number_of_markers + 1);
          });
          // save backup to file
          markerLoader.saveMarkers();
          if (parsedGroups.isNotEmpty){
            parsedGroups.forEach((group) {
              groupLoader.addGroup(
                  group["Group_id"],
                  group["name"].toString(),
                  group["_range"],
                  group["icon"].toString(),
                  toActionsList(List<dynamic>.from(group['Action_Name'])),
                  <String>[]
              );
            });
            markerLoader.getMarkersDescriptions().forEach((markerId, marker) {
              if(marker.groupId != '')
              {
                groupLoader.addMarkerToGroup(marker.groupId, markerId);
              }
            });


          }
          showToast("Backup downloaded successfully");
        }
      } on SocketException catch (e) {
        print(e);
        showToast("Error: request timed out");
      } on HttpException catch (e) {
        print(e);
        showToast("Error: server could not process backup");
      } on Exception catch (e) {
        print(e);
        showToast("Error: something went wrong during download");
      }
    } else {
      showToast("Network connection is off");
    }
  }

  Future<http.Response> changePassword(Map<String, dynamic> content) async {
    try {
      return await _putToServer(
        endpoint: "/api/account/change_password/",
        content: content,
      );
    } on HttpException catch (e) {
      print(e);
      showToast("Error: server could not process data");
      return http.Response("", 300);
    } on Exception catch (e) {
      print(e);
      showToast("Error: something went wrong");
      return http.Response("", 300);
    }
  }

  Future<http.Response> removeAccount() async {
    try {
      return await _deleteToServer(
        endpoint: "/api/account/delete_account/",
      );
    } on HttpException catch (e) {
      print(e);
      showToast("Error: server could not process data");
      return http.Response("", 300);
    } on Exception catch (e) {
      print(e);
      showToast("Error: something went wrong");
      return http.Response("", 300);
    }
  }

  Future<void> removeBackup() async {
    bool connected = await checkNetworkConnection();
    if (connected) {
      try {
        await _deleteToServer(
          endpoint: "/api/backup/",
        );
      } on HttpException catch (e) {
        print(e);
        showToast("Error: server could not process data");
      } on Exception catch (e) {
        print(e);
        showToast("Error: something went wrong");
      }
    } else {
      showToast("Network connection is off");
    }
  }

  Future<http.Response> register(Map<String, dynamic> content) async {
    try {
      // register endpoint
      return await _putToServer2(
        endpoint: "/api/account/register/",
        content: content,
      );
    } on HttpException catch (e) {
      print(e);
      showToast("Error: server could not process data");
      return http.Response("", 300);
    } on Exception catch (e) {
      print(e);
      showToast("Error: something went wrong");
      return http.Response("", 300);
    }
  }

  // --------- PLACES COMMUNITY SYSTEM -----------------------------------------
  Future<List<Map<String, dynamic>>> categoryRequest(
      String endpoint, Map<String, dynamic> content) async {
    if (PrefService.getString('token') != '') {
      try {
        String _token = PrefService.getString('token');

        print(json.encode(content));

        http.Response _response = await http.post(_serverURL + endpoint,
            headers: {
              "Content-type": "application/json",
              HttpHeaders.authorizationHeader: "Token $_token",
            },
            body: json.encode(content)
          // body:
        );
        // verify response
        analyseResponse(_response);

        Map<String, dynamic> parsedMarkers = Map<String, dynamic>.from(
            json.decode(utf8.decode(_response.bodyBytes)));

        List<Map<String, dynamic>> temp = [];

        parsedMarkers['data'].values.forEach((place) {
          temp.add({
            'address': place['addres'],
            'position_x': place['location']['lat'],
            'position_y': place['location']['lng'],
            'name': place['name'],
            'radius': place['radius'],
          });
        });

        if (temp.isEmpty) {
          showToast("Category is empty");
        } else {
          showToast("Category downloaded successfully");
        }
        return temp;
      } on SocketException catch (e) {
        print(e);
        showToast("Error: request timed out");
        return null;
      } on HttpException catch (e) {
        print(e);
        showToast("Error: server could not process data");
        return null;
      } on Exception catch (e) {
        print(e);
        showToast("Error: something went wrong during download");
        return null;
      }
    } else {
      showToast("Not logged in - please log in to proceed");
      return null;
    }
  }

  // --------- FILE UPLOAD -----------------------------------------------------
  void sendFile(String filepath, String endpoint) {
    assert(filepath != null && endpoint != null);

    // https://dev.to/carminezacc/advanced-flutter-networking-part-1-uploading-a-file-to-a-rest-api-from-flutter-using-a-multi-part-form-data-post-request-2ekm
    // init request
    var request =
    new http.MultipartRequest("POST", Uri.parse(_serverURL + endpoint));

    // add file to request
    http.MultipartFile.fromPath('backup', filepath).then((file) {
      request.files.add(file);
    });

    // send request
    request.send().then((response) {
      if (response.statusCode / 100 == 2) {
        print("Uploaded!");
      } else {
        print(response.statusCode);
        print("something went wrong during upload");
      }
    });
  }

  // --------- FILE DOWNLOAD ---------------------------------------------------
  // https://github.com/salk52/Flutter-File-Upload-Download/blob/master/upload_download_app/lib/services/file_service.dart
  static HttpClient getHttpClient() {
    HttpClient httpClient = new HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback =
      ((X509Certificate cert, String host, int port) => true);
    return httpClient;
  }

  Future<String> fileDownload(String filepath, String endpoint) async {
    assert(filepath != null && endpoint != null);

    final url = Uri.parse(_serverURL + endpoint);

    final httpClient = getHttpClient();

    final request = await httpClient.getUrl(url);
    request.headers
        .add(HttpHeaders.contentTypeHeader, "application/octet-stream");

    var httpResponse = await request.close();

    // ignore: unused_local_variable
    int byteCount = 0; // TODO unused element
    // ignore: unused_local_variable
    int totalBytes = httpResponse.contentLength; // TODO unused element
    File file = new File(filepath);
    var raf = file.openSync(mode: FileMode.write);
    Completer completer = new Completer<String>();

    httpResponse.listen(
          (data) {
        byteCount += data.length;
        raf.writeFromSync(data);
      },
      onDone: () {
        raf.closeSync();
        completer.complete(file.path);
      },
      onError: (e) {
        raf.closeSync();
        file.deleteSync();
        completer.completeError(e);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

// TODO propozycja wysłania zip na serwer
// https://stackoverflow.com/questions/56410086/flutter-how-to-create-a-zip-file
// ===========================================================================
}
