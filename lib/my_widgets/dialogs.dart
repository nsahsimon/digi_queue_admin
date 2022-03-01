import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';


class Dialogs {

  FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  ///we need the context herein
  BuildContext context;
  Dialogs({this.context});

  ///displays a simple success message
  Future<void> success() async{
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Container(
            height: 100,
            child: Center(
              child: Icon(Icons.check_sharp,
              size: 70,
              color: Colors.green),
            ),
          )
        );
      }
    );
  }

  ///displays a success message when account is successfully created
  Future<void> createAccountSuccess({String code, bool isTerminal = false}) async{
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: Container(
                height: 200,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AutoSizeText('Account successfully created', //todo: translate
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.green,
                      )),
                      Icon(Icons.check_sharp,
                          size: 70,
                          color: Colors.green),
                      SizedBox(
                        height: 5
                      ),
                      AutoSizeText('Your ${(!isTerminal) ? 'Service' : 'Terminal'} Code is', //todo: translate
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.black,
                      )),
                      SizedBox(
                          height: 5
                      ),
                      AutoSizeText('$code',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 70,
                            color: Colors.blue,
                          ))
                    ],
                  ),
                ),
              ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text('Continue',
                      style: TextStyle(
                        color: Colors.blue,
                      )))
            ]
          );
        }
    );
  }

  ///displays a failure message when account fails to get created
  Future<void> createAccountFailed() async{
    await showDialog(
        context: context,
        builder: (context) {
      return AlertDialog(
          content: Container(
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AutoSizeText('Failed to create account', //todo: translate
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.red,
                      )),
                  Text(
                    'X',
                    style: TextStyle(
                      fontSize: 70,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                 ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text('Continue', //todo: translate
                    style: TextStyle(
                      color: Colors.blue,
                    )))
          ]
      );
    }
    );
  }

  ///displays a failure message
  Future<void> failureDialog() async{
    await showDialog(
        context: context,
        builder: (context)
    {
      return AlertDialog(
          content: Container(
            height: 100,
            child: Center(
              child: Text(
                'X',
                style: TextStyle(
                  fontSize: 70,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
      );
  });
  }

  Future<void> customDialog({String text ,Color color = Colors.black, Widget icon} ) async {
    await showDialog(
        context: context,
        builder: (context)
        {
          return AlertDialog(
            title: Center(
              child: icon ?? Text('!',
              style: TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 70 ) ),
            ),
              content: Container(
                child: AutoSizeText(
                  '$text',
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                  ),
                ),
              )
          );
        });
  }

  ///checks if the user is connected to a mobile network which has access to the internet
  Future<bool> checkConnectionDialog() async {
    Future<bool> isThereConnection() async {
      try {
        final result = await InternetAddress.lookup('www.google.com');
        if(result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          debugPrint('------connected to the internet----');
          return true;
        }
        final SnackBar msg = SnackBar(content: Text('no internet'), duration: Duration(seconds: 1)); //todo: translate this line
        ScaffoldMessenger.of(context).showSnackBar(msg);

        return false;
      }on SocketException catch (e) {
        debugPrint('----you are not connected to the internet-----');
        final SnackBar msg = SnackBar(content: Text('no internet'), duration: Duration(seconds: 1)); //todo: translate this line
        ScaffoldMessenger.of(context).showSnackBar(msg);
        return false;
      }
    }
    bool result;
    result = await isThereConnection().timeout(Duration(seconds: 5), onTimeout: (){return result = false;});

    if(result) {
      return true;
    }else {
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                content: SingleChildScrollView(
                  child: Container(
                      height: 110,
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          Center(child: Text('!',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 70
                              ))),
                          Center(child: AutoSizeText('No internet Connection', maxLines: 1,)) //todo: translate
                        ],
                      )
                  ),
                )
            );
          }
      );

      return false;
    }

  }

  ///Poor internet connection dialog
  Future<void> poorInternetConnectionDialog() async{
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: SingleChildScrollView(
                child: Container(
                    height: 120,
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        Center(child: Text('!',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 70
                            ))),
                        Center(child: AutoSizeText('Poor internet Connection', //todo: translation
                            maxLines: 1 ,
                        textAlign: TextAlign.center))
                      ],
                    )
                ),
              )
          );
        }
    );
  }

  ///dialog to confirm an operation or a task
  Future<bool> confirmationDialog({String text, Color textColor = Colors.black, String actionText1 = 'Yes', String actionText2 = 'No', }) async{
   bool result =  await showDialog(
        context: context,
        builder: (context)
        {
          return AlertDialog(
              content: Container(
                height: 100,
                child: Center(
                  child: Text(
                    '$text',
                    style: TextStyle(
                      //fontSize: 25,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            actions: [
              TextButton(
                child: Text(actionText1),
                onPressed: (){
                  Navigator.pop(context, true);
              }
              ),

              TextButton(
                  child: Text(actionText2),
                  onPressed: (){
                    Navigator.pop(context, false);
                  }
              )
            ]
          );
        });

   return result;
  } //todo: translate

  //Check add updates dialog

  Future<bool> checkUpdatesDialog() async {
    //return true;
    bool isSignedInAnonymously = false; //we might at times neeed to sign nin anonymously in order to perform the below operations
    if(_auth.currentUser == null) {
       try {
         await _auth.signInAnonymously();
       }catch (e) {
         debugPrint('$e');
         return false;
       }
      isSignedInAnonymously = true;
    }


    String _updateLink = "";

    ///compares the in-App version with the latest app version from  the database
    Future<bool> compareAppVersions() async {
      bool result = false;
      DocumentReference appInfoRef = _db.collection('global_info').doc('admin_app_info');
      DocumentSnapshot appInfoDoc;
      String _appVersion;
      try {
        await _db.runTransaction((transaction) async {
          appInfoDoc = await transaction.get(appInfoRef);
          _appVersion = appInfoDoc['admin_app_version'];
          _updateLink = appInfoDoc['update_link'];
        },
        timeout: Duration(seconds: 10));

      }catch(e) {
        debugPrint('$e');
        debugPrint('Could\'nt retrieve the app version from firebase');
        ///return a null if unable to retrieve the app version from firebase
        return null;
      }

      ///compare the two app versions
      if(adminAppVersion == _appVersion) {
        ///if the two app versions are identical return true
        return true;
      }

      ///Checking if the retrieved appVersion if null
      else if(_appVersion == null) {
        ///return a null if the _appVersion retrieved is false;
        return null;

      }
      ///return a false if the appVersion gotten from firebase isn't equal to the saved appVersion
      else return false;
    }

    bool isLatestVersion;
    try {
      isLatestVersion = await compareAppVersions().timeout(Duration(seconds: 5));
    } on TimeoutException catch (e) {
       debugPrint('$e');
       debugPrint('-----Compare app versions timeout!!!------');
       poorInternetConnectionDialog();
       return false;
    }

    ///if the appVersions match, exit: the app is up to date
    if(isLatestVersion == true) {
      if(isSignedInAnonymously) {
        var user = _auth.currentUser;
        //await _auth.signOut();
        ///delete the anoymous account
        await user.delete();
      }
      return true;
    }

    ///if the appVersions don't match and the result of the comparaism is not null,
    ///show the alert dialog
    else if(isLatestVersion == false){
      if(isSignedInAnonymously) {
        ///get an instance of the current user before signing out
        var user = _auth.currentUser;
        //await _auth.signOut();
        ///delete the anonymous account
        await user.delete();
      }
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                content: SingleChildScrollView(
                  child: Container(
                      height: 150,
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          Center(child: Text('!',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 70
                              ))),
                          Center(child: AutoSizeText('An update is required', //todo: translation
                            maxLines: 1,
                          )),
                          Center(child: TextButton(
                            onPressed: () async{
                              if(await canLaunch('$_updateLink')) {
                                await launch('$_updateLink');
                              }
                            },
                            child: AutoSizeText('update the app here', //todo: translation
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                )),
                          )),

                        ],
                      )
                  ),
                )
            );
          }
      );

      return false;
    }

    ///return false if the result of the comparison is null

    else {
      if(isSignedInAnonymously) {
        var user = _auth.currentUser;
        //await _auth.signOut();
        ///delete this user account
        await user.delete();
      }
      return false;
    }
  }

  ///get the pause duration from the queue administrator
  Future<int> getPauseTimeDialog() async {
    int minutesValue = 10;
    int hourValue = 0;
    int dayValue = 0;
    int totalPauseDuration;

    ///Generate droplist of dropdown menu items
    List<DropdownMenuItem> durations(int count) {
      List<DropdownMenuItem> durationList= [];
      for(var i = 0; i<count; i++) {
        var ddmi = DropdownMenuItem(
          child: Text('$i'),
          value: i,
        );
        durationList.add(ddmi);
      }
      return durationList;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Center(
                child: Text('Set pause duration',
                    textAlign: TextAlign.center,//todo: translate
                style: TextStyle(
                  color: Colors.black
                )),
              ),
              content: Container(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ///for days
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            DropdownButton(
                                items: durations(7),
                                value: dayValue,
                            onChanged: (newValue) {
                                  setState ((){
                                    dayValue = newValue;
                                  });
                            }),
                            Text(
                              'Day(s)' //todo: translate
                            )
                          ]
                        ),

                        ///For hours
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              DropdownButton(
                                  items: durations(24),
                                  value: hourValue,
                                  onChanged: (newValue) {
                                    setState ((){
                                      hourValue = newValue;
                                    });
                                  }),
                              Text(
                                  'Hour(s)' //todo: translate
                              )
                            ]
                        ),

                        ///For minutes
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              DropdownButton(
                                  items: durations(60),
                                  value: minutesValue,
                                  onChanged: (newValue) {
                                    setState ((){
                                      minutesValue = newValue;
                                    });
                                  }
                              ),
                              Text(
                                  'minutes(s)' //todo: translate
                              )
                            ]
                        )
                      ]
                    ),

                  ],
                ),
              ),
              actions: [
                Align(
                  alignment: Alignment.center,
                  child: FlatButton(
                    color: Colors.red,
                    child: Text('Pause', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        ///Calculate the total pause time in seconds
                        totalPauseDuration = dayValue * 24 * 60 * 60 + hourValue * 60 * 60 + minutesValue * 60;
                        ///Quit the alert dialog
                        Navigator.pop(context);
                      }
                  ),
                )
              ]
            );
          }
        );
      }
    );

    return totalPauseDuration;
  }
}

class GetPauseTimeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

