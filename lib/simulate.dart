///Former dashboard screen
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:no_queues_manager/constants.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:no_queues_manager/screens/log_in_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
// import 'package:no_queues_manager/screens/my_clients_screen.dart';
// import 'package:no_queues_manager/sms.dart';
// import 'package:no_queues_manager/models/messaging.dart';
// import 'package:no_queues_manager/screens/add_unregistered_client_screen.dart';
// import 'package:no_queues_manager/screens/validate_unregistered_client_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:io';
// import 'dart:core';
// import 'package:no_queues_manager/data_analysis/time_data.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
//
// class DashBoard extends StatefulWidget {
//   @override
//   _DashBoardState createState() => _DashBoardState();
// }
//
// class _DashBoardState extends State<DashBoard> {
//   static const int maxSkipCount = 2;
//   static const int maxClientIndex = 10;
//   static const int maxClientCount = 10;
//   String managerName = "unknown";
//   String serviceCode = "unknown";
//   String id = FirebaseAuth.instance.currentUser.uid;
//   String email = FirebaseAuth.instance.currentUser.email;
//   bool isLoadingActions = false;
//   bool isLoadingStreams = false;
//   int clientCount = 10;
//   List timeData = [];
//   List emptyList = [];
//   int currentClientIndex = 3;
//   int firstClientIndex = 3;
//   int firstNotificationIndex = 3;
//   int secondNotificationIndex = 3;
//   List<MsgData> firstMessages = [];
//   List<MsgData> secondMessages = [];
//   String currentClientName = 'N/A';
//   String currentClientPhoneNumber = 'N/A';
//   String currentClientId = 'N/A';
//   String currentClientFirebaseDeviceToken = '';
//   int currentClientInitialPosition = 0;
//   int currentClientSkipCount = 0;
//   int currentSampleCount = 0;
//   String currentClientLanguage = 'en';
//   var currentClientTimestamp;
//   FirebaseAuth _auth = FirebaseAuth.instance;
//   FirebaseFirestore _db = FirebaseFirestore.instance;
//   bool isValidated = false;
//   bool isSkipButtonPressed = false;
//   String currentClientToken = '';
//   bool isCurrentClientRegistered = true;
//   int previousClientCount = 0;
//   int previousFirstClientIndex = 0;
//
//   Future<void> saveAccountType(String accountType) async {
//     var prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lastAccountType', accountType);
//   }
//
//   void logout() async{
//     await FirebaseAuth.instance.signOut();
//     await saveAccountType('void');
//     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
//         LogInScreen()));
//   }
//
//   String realName(String username) {
//     List<String> _usernameList = username.split('|');
//     String _username = '';
//     for(var name in _usernameList) {
//       print('----name = ${name}----');
//       if(!name.contains('@')){
//         _username = _username + ' ' +name.toUpperCase();
//       }; //TODO:  '@' as a reserved character.
//     }
//     return _username.trim();
//   }
//
//   String initials(String text) {
//     text = text.trim();
//     List<String> words = text.split(' ');
//     String initials = '';
//     for(String word in words) {
//       initials = initials + word.substring(0,1);
//     }
//     String allInitials = initials.toUpperCase(); //might need this in the future but all i need for the now is just the first initial
//     String firstLetter = allInitials.substring(0,1);
//     return firstLetter;
//   }
//   Widget profileImage() {
//     return GestureDetector(
//       onTap: () {
//         showDialog(
//             context: context,
//             builder: (context) {
//               return AlertDialog(
//                   content: SingleChildScrollView(
//                     child: Container(
//                       child: Center(
//                           child: Column(
//                             children: [
//                               CircleAvatar(
//                                   backgroundColor: Colors.lightBlueAccent,
//                                   radius: 20,
//                                   child: Center(
//                                       child: Text(initials(managerName),
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 30,
//                                           ))
//                                   )
//                               ),
//                               Text(
//                                   '${AppLocalizations.of(context).name}: $managerName',
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                   )
//                               ),
//                               Text(
//                                   '${AppLocalizations.of(context).serviceCode}: $serviceCode',
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                   )
//                               ),
//
//                             ],
//                           )
//                       ),
//                     ),
//                   )
//               );
//             }
//         );
//       },
//       child: Center(
//           child: CircleAvatar(
//               backgroundColor: Colors.lightBlueAccent,
//               radius: 20,
//               child: Center(
//                   child: Text(initials(managerName),
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 30,
//                       ))
//               )
//           )
//       ),
//     );
//   }
//
//   void resetVariables() {
//     setState((){
//       isLoadingActions = false;
//       isLoadingStreams = false;
//       clientCount = 10;
//       currentClientIndex = 3;
//       firstClientIndex = 3;
//       firstNotificationIndex = 3;
//       secondNotificationIndex = 3;
//       firstMessages = [];
//       secondMessages = [];
//       timeData = [];
//       currentClientName = 'Anonymous';
//       currentClientPhoneNumber = 'N/A';
//       currentClientLanguage = 'en';
//       currentClientId = 'N/A';
//       currentClientFirebaseDeviceToken = '';
//       currentClientInitialPosition = 0;
//       currentClientSkipCount = 0;
//       currentSampleCount = 0;
//       isValidated = false;
//       isSkipButtonPressed = false;
//       isCurrentClientRegistered = true;
//       previousClientCount = 0;
//       previousFirstClientIndex = 0;
//       currentClientToken = '';
//     });
//   }
//
//   bool isClientRegistered(QueryDocumentSnapshot clientDoc) {
//     bool result = false;
//     try {
//       bool isRegistered = clientDoc['registered'];
//       if (isRegistered == false) result = false;
//       else if (isRegistered == true) result = true;
//     }catch(e){
//       print(e);
//       result = true;
//     }
//
//     isCurrentClientRegistered = result;
//     return result;
//   }
//
//   Future<void> validateRegClient() async {
//     String lineColor = '#ff6666';
//     String cancelButtonText = 'cancel';
//     bool isShowFlashIcon = true;
//     ScanMode scanMode = ScanMode.QR;
//     String scanResult;
//     try {
//       scanResult = await FlutterBarcodeScanner.scanBarcode(
//           lineColor, cancelButtonText, isShowFlashIcon, scanMode);
//     } on PlatformException {
//       scanResult = 'failed to get platform version: ';
//     }
//     if (!mounted) return;
//     try {
//       if (currentClientId == scanResult) {
//         await _db.runTransaction((transaction) async {
//           var managerDocRef = _db.collection('manager_details').doc(_auth.currentUser.uid);
//           var managerDoc = await transaction.get(managerDocRef);
//           if(managerDoc.exists) {
//             try{
//               Timestamp prevValTime = managerDoc['prev_val_time'];
//               List<dynamic>_timeData = [];
//               try{
//                 _timeData = managerDoc['time_data'];
//               }catch(e) {
//                 print(e);
//               }
//               if (currentClientInitialPosition != 1) {
//                 var currentValTime = DateTime.now();
//                 var duration = currentValTime.difference(prevValTime.toDate()).inSeconds; //TODO: LATER ON CHANGE ,THIS THING TO MINUTES
//                 _timeData.add(duration);  //update time data
//                 print('-------duration in seconds : $duration seconds------');
//                 (currentClientInitialPosition != 1) ? //Check whether or not the current client was initially at the firs position
//                 //if yes, ignore the duration from the previous client
//                 transaction.update(managerDocRef, {
//                   'time_data': _timeData,
//                   'prev_val_time' : currentValTime,
//                 }) :
//                 transaction.update(managerDocRef, {
//                   'prev_val_time' : currentValTime,
//                 });
//               }
//             }catch(e) {
//               print(e);
//               print('----setting previous validation time-----');
//               transaction.update(managerDocRef, {
//                 'prev_val_time' : DateTime.now(),
//               });
//             }
//           } else {
//             print('---the manager you are looking for does not exist-----');
//           }
//         });
//         setState(() {
//           isValidated = true;
//         });
//       }
//     } catch (e) {
//       final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).valErrorMsg), duration: Duration(seconds: 1));
//       ScaffoldMessenger.of(context).showSnackBar(msg);
//       print('----unable to validate this client----');
//     }
//   }
//
//   Future<void> validateUnregClient(BuildContext context) async {
//     bool result = await validateUnregisteredClient(currentClientToken, context);
//     try {
//       if (result) {
//         await _db.runTransaction((transaction) async {
//           var managerDocRef = _db.collection('manager_details').doc(_auth.currentUser.uid);
//           var managerDoc = await transaction.get(managerDocRef);
//           if(managerDoc.exists) {
//             try{
//               Timestamp prevValTime = managerDoc['prev_val_time'];
//               List<dynamic> _timeData = [];
//               try{
//                 _timeData = managerDoc['time_data'];
//                 print('-----what is got as time data in the validation function------');
//                 print(_timeData);
//               }catch(e) {
//                 print(e);
//               }
//
//
//
//               var currentValTime = DateTime.now();
//               var duration = currentValTime.difference(prevValTime.toDate()).inSeconds; //TODO: LATER ON CHANGE ,THIS THING TO MINUTES
//               _timeData.add(duration);  //update time data
//               print('-------duration in seconds : $duration seconds------');
//               (currentClientInitialPosition != 1) ? //Check whether or not the current client was initially at the firs position
//               //if yes, ignore the duration from the previous client
//               transaction.update(managerDocRef, {
//                 'time_data': _timeData,
//                 'prev_val_time' : currentValTime,
//               }) :
//               transaction.update(managerDocRef, {
//                 'prev_val_time' : currentValTime,
//               });
//             }catch(e) {
//               print(e);
//               print('----setting previous validation time-----');
//               transaction.update(managerDocRef, {
//                 'prev_val_time' : DateTime.now(),
//               });
//             }
//           } else {
//             print('---the manager you are looking for does not exist-----');
//           }
//         });
//         setState(() {
//           isValidated = true;
//         });
//       }
//     } catch (e) {
//       final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).valErrorMsg), duration: Duration(seconds: 1));
//       ScaffoldMessenger.of(context).showSnackBar(msg);
//       print('----unable to validate this client----');
//     }
//   }
//
//   void startLoading() {
//     setState(() {
//       isLoadingActions = true;
//     });
//   }
//
//   void stopLoading() {
//     setState(() {
//       isLoadingActions = false;
//     });
//   }
//
//   void getManagerDetails() async {
//     try{
//       DocumentSnapshot managerDetails = await FirebaseFirestore.instance.collection('manager_details').doc(id).get();
//
//       String _managerName = managerDetails['name'];
//       String _serviceCode = managerDetails['service_code'];
//       print('----$_managerName-----');
//       setState(() {
//         managerName = _managerName;
//         serviceCode = _serviceCode;
//       });
//     }catch(e){
//       print('---something went wrong-----');
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     getManagerDetails();
//   }
//
//   Widget skipAlertDialog() {
//     return AlertDialog(
//         title: Center(child: Text('${AppLocalizations.of(context).warning} !!!', style: TextStyle(color: Colors.red))),
//         content: Container(
//             height: 50,
//             child: Center(child: Text(AppLocalizations.of(context).skipClientWarning))),
//         actions: [
//           TextButton(child: Text(AppLocalizations.of(context).yes,
//               style: TextStyle(color: Colors.blue)),
//             onPressed: () {
//               setState(() {
//                 isSkipButtonPressed = false;
//               });
//               skip();
//               Navigator.pop(context);
//             },),
//           TextButton(child: Text(AppLocalizations.of(context).no, style: TextStyle(color: Colors.blue)),
//             onPressed: () {
//               setState(() {
//                 isSkipButtonPressed = false;
//               });
//               Navigator.pop(context);
//             },),
//         ]
//     );
//   }
//
//   Future<void> sendSMSReminders() async {
//     Future<void> firstReminder() async{
//       if(firstMessages == [] || firstMessages == null) return;
//       for(MsgData msgData in firstMessages) {
//         await SMSService().send(msgData);
//       }
//     }
//
//     Future<void> secondReminder() async{
//       if(secondMessages == [] || secondMessages == null) return;
//       for(MsgData msgData in secondMessages) {
//         await SMSService().send(msgData);
//       }
//     }
//
//     await firstReminder();
//     await secondReminder();
//
//   }
//
//   Future<int> newTimePeriod() async{
//     return  await DataAnalysis(timeDataInSeconds: timeData.cast<int>()).trueMeanInSeconds(); //TODO: CHANGE THIS TO MINUTES LATER ON
//   }
//
//   List<dynamic> swapItemsInList({List list, var item1, var item2}) {
//     int item1Index = list.indexOf(item1);
//     int item2Index = list.indexOf(item2);
//     List newItemList = [];
//     newItemList[item1Index] = item2;
//     newItemList[item2Index] = item1;
//     return newItemList;
//   }
//
//
//   //Swaps the user details of a registered client with the first unregistered client if there exist an unregistered client.
//   //or places the current registered client at the last position
//   // or deletes the current unregistered client
//   Future<void> skip() async {
//     startLoading();
//     //get the first unregistered client.
//     if (!isValidated && isCurrentClientRegistered != null) {
//       if (isCurrentClientRegistered == true && currentClientSkipCount < maxSkipCount) {
//
//         try {
//           //get the list of unregistered clients
//           QuerySnapshot unregisteredClientDocs = await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers')
//               .where('registered', isEqualTo: false)
//               .orderBy('timestamp')
//               .limit(1)
//               .get();
//           //checking for available unregistered clients
//           if(unregisteredClientDocs.docs.isNotEmpty) {
//             //if there exists unregistered clients i.e if the list is not empty, do the following things
//             //get the first unregistered client
//             var firstUnregClientDoc = unregisteredClientDocs.docs[0];
//             try {
//               await _db.runTransaction((transaction) async {
//                 DocumentReference subsSummaryDoc = _db.collection('manager_details').doc(FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
//                 //get the list of subscribers from the summary document
//                 List oldSubsList = (await transaction.get(subsSummaryDoc))['subscribers'];
//                 //swap client details in the subscriber list
//                 List newSubsList = swapItemsInList(list: oldSubsList, item1: {'id' : currentClientId, 'name' : currentClientName}, item2: {'id' : firstUnregClientDoc['id'], 'name' : firstUnregClientDoc['name']});
//                 transaction.set(subsSummaryDoc, {
//                   'subscribers' : newSubsList,
//                 }, SetOptions(merge: true));
//
//
//                 DocumentReference regSubscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(currentClientId);
//                 transaction.update(regSubscriberReference, {
//                   'skip_count' : FieldValue.increment(1),
//                   'timestamp' : firstUnregClientDoc['timestamp'],
//                   'initial_position' : firstUnregClientDoc['initial_position'],
//                   'client_index' : firstUnregClientDoc['client_index'],
//                   'first_notification_index' : -1, //A skipped client can no longer receive sms notifications
//                   'second_notification_index' : -1 //A skipped client can no longer receive sms notifications
//                 },);
//
//                 DocumentReference unRegSubscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(firstUnregClientDoc['client_id']);
//                 transaction.update(unRegSubscriberReference, {
//                   'timestamp' : currentClientTimestamp,
//                   'initial_position' : currentClientInitialPosition,
//                   'client_index' : currentClientIndex,
//                   'first_notification_index' : -1, //A skipped client can no longer receive sms notifications
//                   'second_notification_index' : -1 //A skipped client can no longer receive sms notifications
//                 },);
//
//
//
//               });
//               resetVariables();
//             } catch (e) {
//               print(e);
//               final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).skipClientFailureMsg), duration: Duration(seconds: 1));
//               ScaffoldMessenger.of(context).showSnackBar(msg);
//             }
//
//           } else {
//             //if there exist no unregistered client ,
//             int clientIndex;
//             int initialPosition;
//             //add this client to the list of clients subscribed to this queue;
//             try {
//               await _db.runTransaction((transaction) async{
//                 DocumentReference managerReference = _db.collection('manager_details').doc(_auth.currentUser.uid);
//                 DocumentSnapshot managerDetails = await transaction.get(managerReference);
//
//                 int _firstClientIndex = managerDetails['first_client_index'];
//                 int _clientCount = managerDetails['client_count'];
//                 int offsetIndex = managerDetails['offset_index'];
//
//                 clientIndex = _firstClientIndex + _clientCount;
//                 initialPosition = _clientCount;
//
//                 //remove client from the subscriber list
//                 DocumentReference subsSummaryDoc = _db.collection('manager_details').doc(FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
//                 transaction.set(subsSummaryDoc, {
//                   'subscribers' : FieldValue.arrayRemove(
//                       [
//                         { 'id': currentClientId,
//                           'name': currentClientName,
//                         }
//                       ]
//                   )
//                 }, SetOptions(merge: true));
//
//                 //add client to the subscriber list
//                 transaction.set(subsSummaryDoc, {
//                   'subscribers' : FieldValue.arrayUnion(
//                       [
//                         { 'id': currentClientId,
//                           'name': currentClientName,
//                         }
//                       ]
//                   )
//                 }, SetOptions(merge: true));
//
//                 DocumentReference subscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(currentClientId);
//                 transaction.update(subscriberReference, {
//                   'skip_count' : FieldValue.increment(1),
//                   'timestamp' : FieldValue.serverTimestamp(),
//                   'initial_position' : initialPosition,
//                   'client_index' : clientIndex,
//                   'first_notification_index' : -1, //the first client index at which the current client is to be firstly notified
//                   'second_notification_index' : -1 //the first client index at which the current client is to be secondly notified.
//                 },);
//
//                 DocumentReference queueReference = _db.collection('manager_details').doc(_auth.currentUser.uid);
//                 if(_firstClientIndex == (maxClientIndex -1)) {
//                   offsetIndex = maxClientIndex + _clientCount - 2;
//                   print('----(dashboard) new offsetIndex = $offsetIndex-------');
//                   transaction.set(queueReference, {
//                     'first_client_index': (_clientCount == 1) ? 1 : FieldValue.increment(1),
//                     'offset_index' : (_clientCount == 1) ? 0 : offsetIndex,
//                   },
//                       SetOptions(merge: true));
//                 }else if(firstClientIndex == offsetIndex) {
//                   offsetIndex = 0;
//                   transaction.set(queueReference, {
//                     'first_client_index': 1,
//                     'offset_index' : 0,
//                   },
//                       SetOptions(merge: true));
//                 }else {
//                   transaction.set(queueReference, {
//                     'first_client_index': FieldValue.increment(1),
//                   },
//                       SetOptions(merge: true));
//                 }
//
//
//                 //TODO: Send sms messages to the relevant clients
//               },
//                 timeout: Duration(seconds: 10),
//               );
//               //if skipping transaction doesn't fail, do the following things
//               resetVariables();
//             } catch(e) {
//               print(e);
//               final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).skipClientFailureMsg), duration: Duration(seconds: 1));
//               ScaffoldMessenger.of(context).showSnackBar(msg);
//             }
//           }
//         }catch(e) {
//           print(e);
//           final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).skipClientFailureMsg), duration: Duration(seconds: 1));
//           ScaffoldMessenger.of(context).showSnackBar(msg);
//         }
//       }
//       else {
//         try {
//           await _db.runTransaction((transaction) async{
//             print('---client has reached the maximum skip count-----');
//             print('----deleting this client----');
//             DocumentReference subscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(currentClientId);
//             transaction.delete(subscriberReference);
//
//             DocumentReference clientQueueDoc = _db.collection('client_details').doc(currentClientId);
//             transaction.set(clientQueueDoc, {
//               'my_queues' : FieldValue.arrayRemove([{
//                 'id' : _auth.currentUser.uid,
//                 'name' : managerName,
//               }])
//             }, SetOptions(merge: true));
//
//             DocumentReference subsSummaryDoc = _db.collection('manager_details').doc(FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
//             transaction.set(subsSummaryDoc, {
//               'subscribers' : FieldValue.arrayRemove(
//                   [
//                     { 'id': currentClientId,
//                       'name': currentClientName,
//                     }
//                   ]
//               )
//             }, SetOptions(merge: true));
//
//             DocumentReference queueReference = _db.collection('manager_details').doc(_auth.currentUser.uid);
//             transaction.update(queueReference, {
//               'client_count': FieldValue.increment(-1),
//               'first_client_index': FieldValue.increment(1)
//             });
//
//             print('------successful transition to the next client-----');
//             //TODO: Uncomment the line below to send sms messages to the relevant clients
//             //await sendSMSReminders();
//           });
//           // if skipping transaction does fail,
//           resetVariables();
//         } catch (e) {
//           print(e);
//           final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).skipClientFailureMsg), duration: Duration(seconds: 1));
//           ScaffoldMessenger.of(context).showSnackBar(msg);
//         }
//       }
//     }
//     stopLoading();
//   }
//
//   Future<void> next() async {
//     if (isValidated) {
//       print('---next was pressed-----');
//       startLoading();
//       try {
//
//         await _db.runTransaction((transaction) async{
//           int offsetIndex;
//           int _clientCount;
//           int _firstClientIndex;
//
//           DocumentReference subscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(currentClientId);
//
//           DocumentReference queueReference = _db.collection('manager_details').doc(_auth.currentUser.uid);
//           var queueDoc = await transaction.get(queueReference);
//           _clientCount = queueDoc['client_count'];
//           _firstClientIndex = queueDoc['first_client_index'];
//           offsetIndex = queueDoc['offset_index'];
//
//           DocumentReference docRef = _db.collection('client_details').doc(currentClientId).collection('my_queues').doc(_auth.currentUser.uid);
//           transaction.delete(docRef);
//
//           transaction.delete(subscriberReference);
//
//           DocumentReference clientQueueDoc = _db.collection('client_details').doc(currentClientId);
//           transaction.set(clientQueueDoc, {
//             'my_queues' : FieldValue.arrayRemove([{
//               'id' : _auth.currentUser.uid,
//               'name' : managerName,
//             }])
//           }, SetOptions(merge: true));
//
//           DocumentReference subsSummaryDoc = _db.collection('manager_details').doc(FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
//           transaction.set(subsSummaryDoc, {
//             'subscribers' : FieldValue.arrayRemove(
//                 [
//                   { 'id': currentClientId,
//                     'name': currentClientName,
//                   }
//                 ]
//             )
//           }, SetOptions(merge: true));
//
//           if(currentSampleCount >= 10){//todo: change the threshold time to 10 minutes
//             int _newTimePeriod = await newTimePeriod();
//
//             if(_firstClientIndex == (maxClientIndex -1)) {
//               offsetIndex = maxClientIndex + clientCount - 2;
//               print('----(dashboard) new offsetIndex = $offsetIndex-------');
//               transaction.set(queueReference, {
//                 'first_client_index': (clientCount == 1) ? 1 : FieldValue.increment(1),
//                 'offset_index' : (clientCount == 1) ? 0 : offsetIndex,
//                 'client_count': FieldValue.increment(-1),
//                 'time_data' : [],
//                 'time_period' : _newTimePeriod
//               },
//                   SetOptions(merge: true));
//             }else if(_firstClientIndex == offsetIndex) {
//               offsetIndex = 0;
//               print('------(dashboard) setting offset index to: $offsetIndex-------');
//               print('------(dashboard) first Client Index to: 1 -------');
//               transaction.set(queueReference, {
//                 'first_client_index': 1,
//                 'offset_index' : 0,
//                 'client_count': FieldValue.increment(-1),
//                 'time_data' : [],
//                 'time_period' : _newTimePeriod
//               },
//                   SetOptions(merge: true));
//             }else {
//               transaction.set(queueReference, {
//                 'first_client_index': FieldValue.increment(1),
//                 'client_count': FieldValue.increment(-1),
//                 'time_data' : [],
//                 'time_period' : _newTimePeriod
//               },
//                   SetOptions(merge: true));
//             }
//             // transaction.update(queueReference, {
//             //   'client_count': FieldValue.increment(-1),
//             //   'first_client_index': FieldValue.increment(1),
//             //   'time_data' : [],
//             //   'time_period' : _newTimePeriod
//             // });
//           }else {
//
//             if(_firstClientIndex == (maxClientIndex -1)) {
//               offsetIndex = maxClientIndex + clientCount - 2;
//               print('----(dashboard) new offsetIndewx = $offsetIndex-------');
//               transaction.set(queueReference, {
//                 'first_client_index': (clientCount == 1) ? 1 : FieldValue.increment(1),
//                 'offset_index' : (clientCount == 1) ? 0 : offsetIndex,
//                 'client_count': FieldValue.increment(-1),
//               },
//                   SetOptions(merge: true));
//             }else if(_firstClientIndex == offsetIndex) {
//               offsetIndex = 0;
//               transaction.set(queueReference, {
//                 'first_client_index': 1,
//                 'offset_index' : 0,
//                 'client_count': FieldValue.increment(-1),
//               },
//                   SetOptions(merge: true));
//             }else {
//               transaction.set(queueReference, {
//                 'first_client_index': FieldValue.increment(1),
//                 'client_count': FieldValue.increment(-1),
//               },
//                   SetOptions(merge: true));
//             }
//
//             // transaction.update(queueReference, {
//             //   'client_count': FieldValue.increment(-1),
//             //   'first_client_index': FieldValue.increment(1),
//             // });
//           }
//
//           print('------successful transition to the next client-----');
//           setState(() {
//             isValidated = false;
//           });
//
//           //TODO: Uncomment the following line s to send sms to the relevant clients
//           //await sendSMSReminders();
//         });
//         resetVariables();
//       } catch (e) {
//         print(e);
//       }
//     }
//     stopLoading();
//   }
//
//   Future<void> extractInfo(DocumentSnapshot managerDoc) async{
//
//     clientCount = managerDoc['client_count'];
//     print('-----client count : $clientCount------');
//     firstClientIndex = managerDoc['first_client_index'];
//     print('-----firstClientIndex: $firstClientIndex-----');
//     managerName = managerDoc['name'];
//     print('-------managerName: $managerName-------');
//     try {
//       timeData = managerDoc['time_data'];
//       print('-------timeData: $timeData-------');
//       currentSampleCount = timeData.length;
//       print('-------currentSampleCount: $currentSampleCount-------');
//     } catch (e) {
//       print(e);
//       currentSampleCount = 0;
//     }
//
//     if(currentSampleCount == 10) {
//       //TODO: compute the average time period(add statistical logic here)
//     }
//
//     if(clientCount != previousClientCount || previousFirstClientIndex != firstClientIndex ) {
//       previousClientCount = clientCount; //this is to avoid unnecessary execution of this function
//       previousFirstClientIndex = firstClientIndex; // this is to avoid unnecessary execution of this function
//
//       isLoadingStreams = true;
//
//       QuerySnapshot clientDetailsSnapshot =  await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers')
//           .where('client_index', isEqualTo: firstClientIndex).get();
//
//       try {
//         print('----return list is empty: ${clientDetailsSnapshot.docs.isEmpty}-----');
//         QueryDocumentSnapshot clientDoc = (clientDetailsSnapshot.docs)[0];
//         currentClientIndex = clientDoc['client_index'];
//         print('-----currentClientIndex: $currentClientIndex------');
//         currentClientName = clientDoc['name'];
//         print('-----currentClientName: $currentClientName------');
//         currentClientInitialPosition = clientDoc['initial_position'];
//         print('-----currentClientInitialPosition: $currentClientInitialPosition------');
//         currentClientId = clientDoc['client_id'];
//         print('---------currentClientId: $currentClientId------');
//         currentClientSkipCount = clientDoc['skip_count'];
//         print('---------currentClientSkipCount: $currentClientSkipCount------');
//         currentClientTimestamp = clientDoc['timestamp'];
//         print('------currentClientTimestamp: $currentClientTimestamp------');
//
//         //checking if the current client is registered or not so as to extract data from some particular fields
//         if(isClientRegistered(clientDoc)){
//           firstNotificationIndex = clientDoc['first_notification_index'];
//           print('--------firstNotificationIndex: $firstNotificationIndex-------');
//           secondNotificationIndex = clientDoc['second_notification_index'];
//           print('---------secondNotificationIndex: $secondNotificationIndex------');
//           currentClientPhoneNumber = clientDoc['phone'];
//           print('------currentClientPhoneNumber: $currentClientPhoneNumber------');
//           currentClientFirebaseDeviceToken = clientDoc['firebaseDeviceToken'];
//           print('------currentClientDeviceToken: $currentClientFirebaseDeviceToken----');
//           currentClientLanguage = clientDoc['lang'];
//           print('------currentClientLanguage: $currentClientLanguage------');
//         }else {
//           currentClientToken = clientDoc['token'];
//         }
//
//         firstMessages = [];
//         try {
//           QuerySnapshot clientsForFirstNotificationSnapshot =  await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers')
//               .where('first_notification_index', isEqualTo: currentClientIndex).get();
//           List<QueryDocumentSnapshot> clientsForFirstNotificationDocs = clientsForFirstNotificationSnapshot.docs;
//           for (QueryDocumentSnapshot clientDoc in clientsForFirstNotificationDocs) {
//             print('-------receiverPhoneNumber: ${clientDoc['phone']}-------');
//             print('-------receiverDeviceToken: ${clientDoc['firebaseDeviceToken']}-------');
//             print('-------receiverName: ${clientDoc['name']}-------');
//             firstMessages.add(
//                 MsgData(
//                     senderName: managerName,
//                     receiverPhoneNumber: clientDoc['phone'],
//                     receiverDeviceToken: clientDoc['firebaseDeviceToken'],
//                     receiverId: clientDoc['client_id'],
//                     receiverName: clientDoc['name'],
//                     receiverInitialPosition: clientDoc['initial_position'],
//                     receiverLanguage: clientDoc['lang'],
//                     completionPercentage: 0.6
//                 )
//             );
//           }
//         }catch (e) {
//           print('-----could not load first notification messages--------');
//         }
//
//         secondMessages = [];
//         try {
//           QuerySnapshot clientsForSecondNotificationSnapshot =  await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers')
//               .where('second_notification_index', isEqualTo: currentClientIndex).get();
//           List<QueryDocumentSnapshot> clientsForSecondNotificationDocs = clientsForSecondNotificationSnapshot.docs;
//           for (QueryDocumentSnapshot clientDoc in clientsForSecondNotificationDocs) {
//             secondMessages.add(
//                 MsgData(
//                     senderName: managerName,
//                     receiverPhoneNumber: clientDoc['phone'],
//                     receiverDeviceToken: clientDoc['firebaseDeviceToken'],
//                     receiverName: clientDoc['name'],
//                     receiverId: clientDoc['client_id'],
//                     receiverInitialPosition: clientDoc['initial_position'],
//                     receiverLanguage: clientDoc['lang'],
//                     completionPercentage: 0.8
//                 )
//             );
//           }
//         } catch (e) {
//           print('-------was unable to load the second notification messages---------');
//         }
//       } catch (e) {
//         print(e);
//         print('-----------was unable to extract the client info---------');
//       }
//       setState((){
//         isLoadingStreams = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: ()async => false,
//       child: SafeArea(
//           child: ModalProgressHUD(
//               inAsyncCall: isLoadingActions,
//               child: StreamBuilder<DocumentSnapshot>(
//                   stream: _db.collection('manager_details').doc(_auth.currentUser.uid).snapshots(),
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData) {
//                       isLoadingStreams = true;
//                     } else {
//                       isLoadingStreams = false;
//                       //this might pose a problem
//                       print('----stream loaded-----');
//                       extractInfo(snapshot.data);
//                     }
//                     return ModalProgressHUD(
//                       inAsyncCall: isLoadingStreams,
//                       child: Scaffold(
//                           drawer: Padding(
//                             padding: const EdgeInsets.only(right: 60),
//                             child: Drawer(
//                                 child: ListView(
//                                     children: [
//                                       DrawerHeader(
//                                         decoration: BoxDecoration(
//                                           color: appColor,
//                                         ),
//                                         child: Column(
//                                           mainAxisAlignment: MainAxisAlignment.end,
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(AppLocalizations.of(context).options,
//                                                 style: TextStyle(
//                                                   color: Colors.white,
//                                                   fontSize: 20,
//                                                 )),
//                                           ],
//                                         ),
//                                       ),
//                                       ListTile(
//                                           leading: Icon(Icons.edit),
//                                           title: Text(AppLocalizations.of(context).editAccount),
//                                           onTap: () {
//                                             Navigator.popAndPushNamed(context, '/DashBoardScreen/EditingScreen');
//                                           }),
//
//                                       ListTile(
//                                           leading: Icon(Icons.flag,),
//                                           title: Text(AppLocalizations.of(context).language,
//                                           ),
//                                           onTap: () {
//                                             Navigator.popAndPushNamed(context, '/ModifiedSelectLangScreen');
//                                           }
//                                       ),
//                                       ListTile(
//                                           onTap: logout,
//                                           leading: Icon(Icons.logout,),
//                                           title: Text(AppLocalizations.of(context).logout,
//                                           )),
//                                       ListTile(
//                                           onTap: () {
//                                             Navigator.push(context, MaterialPageRoute(builder: (context) => MyClientsScreen()));
//                                           },
//                                           leading: Icon(Icons.supervised_user_circle_sharp, color: Colors.green),
//                                           title: Text(AppLocalizations.of(context).myClients,
//                                           )),
//                                       ListTile(
//                                           onTap: () {
//                                             Navigator.popAndPushNamed(context, '/DashBoardScreen/MyTerminalsScreen');
//                                           },
//                                           leading: Icon(Icons.supervised_user_circle_sharp, color: Colors.red),
//                                           title: Text(AppLocalizations.of(context).myTerminals,
//                                           ))
//                                     ]
//                                 )
//                             ),
//                           ),
//                           appBar: AppBar(
//                             backgroundColor: appColor,
//                             actions: [
//                               IconButton(icon: Icon(Icons.add),
//                                 onPressed: ()async{
//                                   await AddUnregClient().addUnregClient(context, startLoading, stopLoading);
//                                 },),
//                               profileImage(),
//                             ],
//                             title: SingleChildScrollView(
//                               child: Text(AppLocalizations.of(context).dashBoard,
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 20,
//                                   )),
//                             ),
//                           ),
//                           body:Container(
//                             child: Column(
//                                 children: [
//                                   Expanded(
//                                     flex: 3,
//                                     child: Row(
//                                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                       children: [
//                                         Expanded(
//                                           flex: 1,
//                                           child: Card(
//                                             margin: EdgeInsets.symmetric(horizontal: 8),
//                                             elevation: 10,
//                                             shadowColor: Colors.red,
//                                             child: Container(
//                                                 height: 200,
//                                                 child: Center(child: Column(
//                                                   mainAxisAlignment: MainAxisAlignment
//                                                       .center,
//                                                   children: [
//                                                     Text('$clientCount',
//                                                         style: TextStyle(
//                                                           fontSize: 100,
//                                                           color: Colors.green,
//                                                         )),
//                                                     Text('${(clientCount == 1) ? AppLocalizations.of(context).clientWaiting
//                                                         : AppLocalizations.of(context).clientsWaiting}')
//                                                   ],
//                                                 ))),
//                                           ),
//                                         ),
//                                         Expanded(
//                                           flex: 1,
//                                           child: Card(
//                                             margin: EdgeInsets.symmetric(horizontal: 8),
//                                             elevation: 10,
//                                             shadowColor: Colors.red,
//                                             child: Container(
//                                                 height: 200,
//                                                 child:(clientCount == 0)? Center(child: Text(AppLocalizations.of(context).noClients)) : Column(
//                                                   children: [
//                                                     Center(
//                                                         child: Text(
//                                                             AppLocalizations.of(context).currentClient
//                                                         )),
//                                                     Padding(
//                                                       padding: const EdgeInsets
//                                                           .symmetric(horizontal: 30),
//                                                       child: Divider(thickness: 2,
//                                                           color: Colors.red),
//                                                     ),
//                                                     SizedBox(height: 20),
//                                                     Center(child: (currentClientName == null ||
//                                                         currentClientName == '') ? Text(
//                                                         AppLocalizations.of(context).anonymous) : Text(
//                                                         '${currentClientName}')),
//                                                     SizedBox(height: 10),
//                                                     Center(
//                                                         child: Text('${currentClientPhoneNumber}',
//                                                             style: TextStyle(
//                                                               fontSize: 15,
//                                                               fontWeight: FontWeight
//                                                                   .bold,
//                                                             ))),
//                                                     isValidated ? Icon(Icons.check,
//                                                         size: 70,
//                                                         color: Colors.green) : Text('?',
//                                                         style: TextStyle(
//                                                           color: Colors.orange,
//                                                           fontSize: 70,
//                                                           fontWeight: FontWeight.bold,
//                                                         )),
//                                                   ],
//                                                 )),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   Expanded(
//                                       flex: 1,
//                                       child: Card(
//                                         elevation: 10,
//                                         shadowColor: Colors.red,
//                                         child: (clientCount == 0) ? null : Container(
//                                             width: MediaQuery
//                                                 .of(context)
//                                                 .size
//                                                 .width * 0.9,
//                                             height: 100,
//                                             child: Column(
//                                               children: [
//                                                 Center(child: Text(
//                                                     AppLocalizations.of(context).clientId
//                                                 )),
//                                                 Padding(
//                                                   padding: const EdgeInsets.symmetric(
//                                                       horizontal: 110),
//                                                   child: Divider(thickness: 2,
//                                                       color: Colors.lightBlueAccent),
//                                                 ),
//                                                 SizedBox(height: 10),
//                                                 Center(child: Text('$currentClientId'))
//                                               ],
//                                             )),
//                                       )
//                                   ),
//                                   Row(
//                                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                       children: [
//                                         Center(
//                                           child: ElevatedButton(
//                                               style: ButtonStyle(
//                                                 backgroundColor: MaterialStateProperty
//                                                     .all(Colors.red),
//                                                 elevation: MaterialStateProperty.all(5),
//                                               ),
//                                               onPressed: () {
//                                                 showDialog(context: context,
//                                                     builder: (context) {
//                                                       return skipAlertDialog();
//                                                     });
//                                               },
//
//                                               child: Text(
//                                                   AppLocalizations.of(context).skip,
//                                                   style: TextStyle(
//                                                     color: Colors.white,
//                                                   )
//                                               )),
//                                         ),
//                                         Center(
//                                           child: ElevatedButton(
//                                               style: ButtonStyle(
//                                                 backgroundColor: MaterialStateProperty
//                                                     .all(Colors.green),
//                                                 elevation: MaterialStateProperty.all(5),
//                                               ),
//                                               onPressed: () async {
//                                                 if (!isValidated) {
//                                                   startLoading();
//                                                   if(isCurrentClientRegistered) await validateRegClient();
//                                                   else await validateUnregClient(context);
//                                                   stopLoading();
//                                                 }else {
//                                                   final SnackBar msg = SnackBar(content: Text(
//                                                     AppLocalizations.of(context).alreadyValidated,
//                                                   ), duration: Duration(seconds: 1));
//                                                   ScaffoldMessenger.of(context).showSnackBar(msg);
//                                                 }
//                                               },
//                                               child: Text(
//                                                   AppLocalizations.of(context).validate,
//                                                   style: TextStyle(
//                                                     color: Colors.white,
//                                                   )
//                                               )),
//                                         ),
//                                         Center(
//                                           child: ElevatedButton(
//                                               style: ButtonStyle(
//                                                 backgroundColor: MaterialStateProperty
//                                                     .all(Colors.blue),
//                                                 elevation: MaterialStateProperty.all(5),
//                                               ),
//                                               onPressed: () async {
//                                                 await next();
//                                               },
//                                               child: Text(
//                                                   AppLocalizations.of(context).next,
//                                                   style: TextStyle(
//                                                     color: Colors.white,
//                                                   )
//                                               )),
//                                         ),
//                                       ]
//                                   ),
//                                   SizedBox(height: 30),
//                                   Center(
//                                     child: ElevatedButton(
//                                         style: ButtonStyle(
//                                           backgroundColor: MaterialStateProperty.all(
//                                               Colors.green),
//                                           elevation: MaterialStateProperty.all(5),
//                                         ),
//                                         onPressed: () async {
//                                           await sendSMSReminders();
//                                         },
//                                         child: Text(
//                                             'Send Notification',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                             )
//                                         )),
//                                   ),
//                                 ]
//                             ),
//                           )
//                       ),
//                     );
//                   }
//               )
//           )
//       ),
//     );
//   }
// }
//
//
//


///former add_unregistered_client_screen
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:no_queues_manager/constants.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// class AddUnregClient {
//   static const int maxClientIndex = 10;
//   static const int maxClientCount = 10;
//   String managerId;
//   AddUnregClient({this.managerId});
//   FirebaseAuth auth = FirebaseAuth.instance;
//   FirebaseFirestore db = FirebaseFirestore.instance;
//   String token;
//   Future<void> addUnregClient (context, startLoading, stopLoading) async{
//     String clientName = await getClientNameDialog(context,startLoading, stopLoading);
//     bool success = await joinQueue(clientName,startLoading,stopLoading,context);
//     if(success) {
//       displayTokenDialog(context);
//     }else {
//       final SnackBar msg = SnackBar(content: Text('Failed to join queue'), duration: Duration(seconds: 1));
//       ScaffoldMessenger.of(context).showSnackBar(msg);
//     }
//   }
//
//   Future<String> getClientNameDialog(context,startLoading, stopLoading) async{
//     String name;
//     await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//               content: Container(
//                   height: 100,
//                   color: Colors.white,
//                   child: SingleChildScrollView(
//                       child: Column(
//                           children: [
//                             TextField(
//                               onChanged: (newText) {
//                                 name = newText;
//                               },
//                               decoration: InputDecoration(
//                                   hintText: AppLocalizations.of(context).enterTheClientName
//                               ) ,
//
//                             ),
//                             FlatButton(
//                               color: appColor,
//                               child: Text(
//                                   AppLocalizations.of(context).add,
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                   )
//                               ),
//                               onPressed: () async{
//                                 if(name.trim() != null) {
//                                   Navigator.pop(context);
//                                 }
//                               },
//                             )
//                           ]
//                       )
//                   )
//               )
//           );
//         }
//     );
//     return name.trim();
//   }
//
//   Future<bool> joinQueue(String name, Function startLoading, Function stopLoading, BuildContext context) async{
//     bool success = false;
//     startLoading();
//     try {
//       await db.runTransaction((transaction) async{
//         int clientIndex;
//         int clientToken;
//         int initialPosition;
//
//
//         DocumentReference managerReference = db.collection('manager_details').doc(managerId ?? FirebaseAuth.instance.currentUser.uid);
//         DocumentSnapshot managerDetails = await transaction.get(managerReference);
//
//
//         int offsetIndex = managerDetails['offset_index'];
//         int firstClientIndex = managerDetails['first_client_index'];
//         int clientCount = managerDetails['client_count'];
//
//         // if this client is the first subscriber of this service,
//         clientIndex = firstClientIndex + clientCount - offsetIndex;
//         print('--------(add client screen) client count : $clientCount------');
//         print('--------(add client screen) firstClientIndex : $firstClientIndex-------');
//         print('--------(add client screen) offsetIndex : $offsetIndex-------');
//         initialPosition = clientCount + 1;
//         token = '$clientIndex';
//         if (clientCount < maxClientCount) {
//           DocumentReference subsSummaryDoc = db.collection('manager_details').doc(managerId ?? FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
//           transaction.set(subsSummaryDoc, {
//             'subscribers' : FieldValue.arrayUnion(
//                 [
//                   { 'id': '$clientIndex',
//                     'name': name,
//                   }
//                 ]
//             )
//           }, SetOptions(merge: true));
//
//           DocumentReference subscriberReference = db.collection('manager_details').doc(managerId ?? FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('$clientIndex');
//           transaction.set(subscriberReference, {
//             'skip_count' : 0,
//             'client_id' : '$clientIndex',
//             'timestamp' : FieldValue.serverTimestamp(),
//             'client_index' : clientIndex,
//             'initial_position' : initialPosition,
//             'name': name,
//             'registered' : false,
//             'token' : token,
//             'first_notification_index' : -1,
//             'second_notification_index' : -1,
//             'validation_time' : FieldValue.serverTimestamp()
//           },);
//
//           managerReference = db.collection('manager_details').doc(managerId ?? FirebaseAuth.instance.currentUser.uid);
//           transaction.update(managerReference, {
//             'client_count': FieldValue.increment(1),
//           });
//           success = true;
//         }else {
//           success = false;
//           final SnackBar msg = SnackBar(content: Text('Failed to add. Max client limit reached.'), duration: Duration(seconds: 1));
//           ScaffoldMessenger.of(context).showSnackBar(msg);
//         }
//
//       },
//         timeout: Duration(seconds: 10),
//       );
//
//       //TODO: Display a dialog box when client successfully joins the queue.
//     } catch(e) {
//       print(e);
//       print('--------failed to join queue---------');
//       success = false;
//     }
//     stopLoading();
//     return success;
//
//   }
//
//   void displayTokenDialog(context){
//     if(token != null){
//       showDialog(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               actionsAlignment: MainAxisAlignment.center,
//               content: Container(
//                 height: 100,
//                 child: Center(
//                   child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       mainAxisAlignment: MainAxisAlignment.center ,
//                       children: [
//                         Text(
//                           AppLocalizations.of(context).yourTokenIs,
//                         ),
//                         Text(
//                             '${token}',
//                             style: TextStyle(
//                               color: Colors.blue,
//                               fontSize: 50,
//                             )
//                         )
//                       ]
//                   ),
//                 ),
//               ),
//             );
//           }
//       );
//     }
//   }
// }
