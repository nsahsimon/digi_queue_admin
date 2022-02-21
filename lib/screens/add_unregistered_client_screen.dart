import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';


class AddUnregClient {
  String managerId;
  String inputClientName;
  bool success = false;
  AddUnregClient({this.managerId,this.inputClientName});

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  String token;

  ///main function that to add an unregistered client to the queue
  Future<String> addUnregClient (context, startLoading, stopLoading) async{
    String clientName;

    ///make sure app is up to date
    //if(await Dialogs(context: context).checkUpdatesDialog() == false) return null;

    ///If the client name is provided, then just use it!!
    if(inputClientName == null) clientName = await getClientNameDialog(context,startLoading, stopLoading);
    else clientName = inputClientName;
    if(clientName != null) {
      success = await joinQueue(clientName,startLoading,stopLoading,context);
      if(success) {
        await  displayTokenDialog(context);
      }else {
        final SnackBar msg = SnackBar(content: Text('Failed to join queue'), duration: Duration(seconds: 1)); //todo: translate
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
      return token;
    }
  }

  ///Get the client name
  Future<String> getClientNameDialog(context,startLoading, stopLoading) async{
    String name;
    name = await showDialog(
      context: context,
      builder: (context) {
        String name;
        return AlertDialog(
          content: Container(
            height: 100,
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    onChanged: (newText) {
                      name = newText;
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).enterTheClientName
                    ) ,

                ),
                  FlatButton(
                    color: appColor,
                    child: AutoSizeText(
                      AppLocalizations.of(context).add,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                      )
                    ),
                    onPressed: () async{
                      if(name != null && name.trim() != '') {
                          Navigator.pop(context, name.trim());
                      }else {
                        Navigator.pop(context, null);
                      }
                    },
                  )
                ]
              )
            )
          )
        );
      }
    );
    return name;
  }

  Future<bool> joinQueue(String name, Function startLoading, Function stopLoading, BuildContext context) async{
    bool success = false;
    startLoading();
      try {
        await db.runTransaction((transaction) async{
          int clientIndex;
          int clientToken;
          int initialPosition;


          DocumentReference managerReference = db.collection('manager_details').doc(managerId ?? FirebaseAuth.instance.currentUser.uid);
          DocumentSnapshot managerDetails = await transaction.get(managerReference);


          int firstClientIndex = managerDetails['first_client_index'];
          int clientCount = managerDetails['client_count'];

          // if this client is the first subscriber of this service,
          clientIndex = firstClientIndex + clientCount;
          print('--------(add client screen) client count : $clientCount------');
          print('--------(add client screen) firstClientIndex : $firstClientIndex-------');
          initialPosition = clientCount + 1;
          token = '${Random().nextInt(1000)}';
          if (clientCount < maxClientCount) {
            DocumentReference subsSummaryDoc = db.collection('manager_details').doc(managerId ?? FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
            transaction.set(subsSummaryDoc, {
              'subscribers' : FieldValue.arrayUnion(
                  [
                    { 'id': '$clientIndex',
                      'name': name,
                    }
                  ]
              )
            }, SetOptions(merge: true));

            DocumentReference subscriberReference = db.collection('manager_details').doc(managerId ?? FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('$clientIndex');
            transaction.set(subscriberReference, {
              'skip_count' : 0,
              'client_id' : '$clientIndex',
              'timestamp' : FieldValue.serverTimestamp(),
              'client_index' : clientIndex,
              'initial_position' : initialPosition,
              'name': name,
              'registered' : false,
              'token' : token,
              'first_notification_index' : -1,
              'second_notification_index' : -1,
              'validation_time' : FieldValue.serverTimestamp()
            },);

            managerReference = db.collection('manager_details').doc(managerId ?? FirebaseAuth.instance.currentUser.uid);
            transaction.update(managerReference, {
              'client_count': FieldValue.increment(1),
            });
            success = true;
          }else {
            success = false;
            final SnackBar msg = SnackBar(content: Text('Failed to add. Max client limit reached.'), duration: Duration(seconds: 1));
            ScaffoldMessenger.of(context).showSnackBar(msg);
          }

        },
          timeout: Duration(seconds: 10),
        );

        //TODO: Display a dialog box when client successfully joins the queue.
      } catch(e) {
        debugPrint('$e');
        debugPrint('--------failed to join queue---------');
        success = false;
      }
      stopLoading();
    return success;

  }

  Future<void> displayTokenDialog(context) async{
    if(token != null){
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            actionsAlignment: MainAxisAlignment.center,
            content: Container(
              height: 100,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center ,
                  children: [
                    Text(
                      AppLocalizations.of(context).yourTokenIs,
                    ),
                    Text(
                      '${token}',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 50,
                      )
                    )
                  ]
                ),
              ),
            ),
          );
        }
      );
    }
  }
}
