import 'package:flatmapp/resources/objects/loaders/languages/languages_loader.dart';
import 'package:flatmapp/resources/objects/widgets/app_bar.dart';
import 'package:flatmapp/resources/objects/widgets/side_bar_menu.dart';
import 'package:flatmapp/resources/objects/widgets/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:launch_review/launch_review.dart';
import 'package:url_launcher/url_launcher.dart';

// Putting language dictionaries seams done

class AboutRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // show licence agreement
//    Future.delayed(Duration.zero, () => showLicenceAgreement(context));
    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              ListTile(
                title: Text(
                  LanguagesLoader.of(context).translate("About"),
                  style: header(),
                ),
                leading: Icon(Icons.info_outline),
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text(
                  LanguagesLoader.of(context).translate("about_section_1"),
                  style: bodyText(),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text(
                  LanguagesLoader.of(context).translate("about_section_2"),
                  style: bodyText(),
                ),
              ),
              SizedBox(height: 10),
              ListTile(
                title: Linkify(
                  text:
                  "${LanguagesLoader.of(context).translate("Privacy policy")}: \n${LanguagesLoader.of(context).translate("Privacy policy link")}",
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      // show message
                      Fluttertoast.showToast(
                        msg:
                        '${LanguagesLoader.of(context).translate("Could not launch")} $link',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  },
                  style: bodyText(),
                  linkStyle: TextStyle(color: Colors.green),
                ),
                trailing: Icon(Icons.link),
              ),
              SizedBox(height: 10),
              ListTile(
                title: Linkify(
                  text:
                      "${LanguagesLoader.of(context).translate("Application repository")} \nhttps://github.com/AdamLewicki/flatmapp_app",
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      // show message
                      Fluttertoast.showToast(
                        msg:
                            '${LanguagesLoader.of(context).translate("Could not launch")} $link',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  },
                  style: bodyText(),
                  linkStyle: TextStyle(color: Colors.green),
                ),
                trailing: Icon(Icons.link),
              ),
              SizedBox(height: 10),

              ListTile(
                title: Linkify(
                  text:
                      "${LanguagesLoader.of(context).translate("Server repository")}: \nhttps://github.com/AdamLewicki/flatmapp_server",
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      // show message
                      Fluttertoast.showToast(
                        msg:
                            '${LanguagesLoader.of(context).translate("Could not launch")} $link',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  },
                  style: bodyText(),
                  linkStyle: TextStyle(color: Colors.green),
                ),
                trailing: Icon(Icons.link),
              ),
              SizedBox(height: 10),

              // ListTile(
              //   title: SelectableLinkify(
              //     text: "${LanguagesLoader.of(context).translate("Test report")}: \nhttps://forms.gle/T4XomZRWfQ1iRBQD8",
              //     onOpen: (link) async {
              //       Fluttertoast.showToast(
              //         msg: '${LanguagesLoader.of(context).translate("Opening test report")}',
              //         toastLength: Toast.LENGTH_SHORT,
              //         gravity: ToastGravity.BOTTOM,
              //       );
              //       if (await canLaunch(link.url)) {
              //         await launch(link.url);
              //       } else {
              //         // show message
              //         Fluttertoast.showToast(
              //           msg: '${LanguagesLoader.of(context).translate("Could not launch")} $link',
              //           toastLength: Toast.LENGTH_SHORT,
              //           gravity: ToastGravity.BOTTOM,
              //         );
              //       }
              //     },
              //     style: bodyText(),
              //     linkStyle: TextStyle(color: Colors.green),
              //   ),
              //   trailing: Icon(Icons.link),
              // ),
              // SizedBox(height: 10),
              //
              // ListTile(
              //   title: SelectableLinkify(
              //     text: "${LanguagesLoader.of(context).translate("Bug report")}: \nhttps://forms.gle/V7MRhwb7fDVFc8TV8",
              //     onOpen: (link) async {
              //       Fluttertoast.showToast(
              //         msg: '${LanguagesLoader.of(context).translate("Opening bug report")}',
              //         toastLength: Toast.LENGTH_SHORT,
              //         gravity: ToastGravity.BOTTOM,
              //       );
              //       if (await canLaunch(link.url)) {
              //         await launch(link.url);
              //       } else {
              //         // show message
              //         Fluttertoast.showToast(
              //           msg: '${LanguagesLoader.of(context).translate("Could not launch")} $link',
              //           toastLength: Toast.LENGTH_SHORT,
              //           gravity: ToastGravity.BOTTOM,
              //         );
              //       }
              //     },
              //     style: bodyText(),
              //     linkStyle: TextStyle(color: Colors.green),
              //   ),
              //   trailing: Icon(Icons.link),
              // ),
              // SizedBox(height: 10),

              Container(
                decoration: buttonFieldStyle(),
                child: ListTile(
                  title: Text(
                    '${LanguagesLoader.of(context).translate("rate_on_google")}',
                    style: bodyText(),
                  ),
                  trailing: Icon(Icons.star_border),
                  onTap: () {
                    // go to Google Play app review
                    LaunchReview.launch();
                  },
                ),
              ),
              SizedBox(height: 10),

              ListTile(
                title: Text(
                  LanguagesLoader.of(context).translate("flatmapp_footer"),
                  style: footer(),
                ),
              ),
            ],
          ).toList(),
        ),
      ),

      // SIDE PANEL MENU
      drawer: sideBarMenu(context),
    );
  }
}
