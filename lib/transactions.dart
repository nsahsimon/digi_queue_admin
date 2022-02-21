// import 'package:flutter/cupertino.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert' as convert;
// import 'package:flutter/material.dart';
// import 'package:no_queues_manager/constants.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
// import 'dart:async';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
//
// //payment using MTN or Orange Mobile Money
// //the phone number can either be MTN or Orange
//
//
//
//
// Stream<int> timerCounter () async*{
//   int i = 0;
//   while(true) {
//     await Future.delayed(Duration(seconds: 1));
//     yield i++;
//   }
// }
//
//
// class Transactions {
//   String minAmount;
//   final Duration timeout;
//   final BuildContext context;
//   final Function recordPaymentCallback;
//
//   Transactions({this.timeout = const Duration(
//       seconds: 30), this.context, this.recordPaymentCallback});
//
//
//   String username;
//   String password;
//   String webHookKey;
//   String appId;
//   // String username = 'T04imI7TG8ggtlg48ZccS-rbUtRoPLVP_OajwTILQ0sfF4IUauJPqNOWP4jzF_uO_kIrFw-TE7Ti06RV_uep2A';
//   // String password = 'm-DJcDCI3lne03D4gd_sFZnagDoWeLJKyv-zZtLz5Bmz3Ox9NDKsUEhQqFG_HXqPUx0nJH2jr3L9GN2NqiuOSw';
//   // String appId = 'rOy0PhQI4qVwtOy6y1RC1En-jKt66j7T0_juJROXJfBGM6eu-ZUvJsW8CewAKS3XmxKyL2vfvZZpZNHXpV_BRA';
//   // String webHookKey = 'PnieKYDzvPUUb6R4CGJV2On0rQNc2F4mtmIEQgOOoYBFWS1gAOLfQLjfZze8f5AyJn58dqG5fgPO0GsNvyfzZg';
//   String getAccessTokenUrl = 'https://www.campay.net/api/token/';
//   String requestPaymentUrl = 'https://www.campay.net/api/collect/';
//   String withdrawalUrl = 'https://www.campay.net/api/withdraw/';
//   String webHookUrl = 'https://example.com/yourcallback';
//   String getBalanceUrl = 'https://www.campay.net/api/balance/';
//   String transactionHistoryUrl = 'https://www.campay.net/api/history/';
//   String airtimeTransferUrl = 'https://www.campay.net/api/utilities/airtime/transfer/';
//   String reference = '';
//   String token = '';
//   String ussdCode = '';
//   String operator = '';
//   bool success = true;
//   int counter = 0;
//   String status = 'PENDING';
//   bool _break  = false;
//
//   String get transactionStatusUrl {
//     return 'https://www.campay.net/api/transaction/$reference/';
//   }
//
//
//   Future<bool> getApiInfo() async {
//     bool success = false;
//     try {
//       await FirebaseFirestore.instance.runTransaction((transaction) async {
//         DocumentReference apiDocRef = FirebaseFirestore.instance.collection('global_info').doc('campay');
//         DocumentSnapshot apiDoc = await transaction.get(apiDocRef);
//         username = apiDoc['username'];
//         debugPrint('----username: $username-----');
//         password = apiDoc['password'];
//         debugPrint('----password: $password------');
//         appId = apiDoc['app_id'];
//         debugPrint('-----appId: $appId-----');
//         webHookKey = apiDoc['web_hook_key'];
//         debugPrint('-----webHookKey: $webHookKey-----');
//         minAmount = apiDoc['min_amount'];
//         debugPrint('----minAmount: $minAmount------');
//         if(username != null && username != '' && apiDoc.exists) {
//           debugPrint('------I got the campay api information from firebase-------');
//           success = true;
//         }
//       });
//     }catch(e) {
//       debugPrint(e);
//       success = false;
//     }
//     return success;
//   }
//
//
//   String getCode() {
//     if(operator == 'MTN'){
//       return '*126#';
//     } else {
//       return '#150*50#';
//     }
//   }
//
//   Future<bool> getCredentials() async {
//     bool result = false;
//     debugPrint('payment initiated');
//     var headers = {
//       'Content-Type': 'application/json'
//     };
//
//     var request;
//     try {
//       request = http.Request(
//           'POST', Uri.parse(getAccessTokenUrl));
//       request.body = convert.json.encode({
//         "username": username,
//         "password": password,
//       });
//
//       request.headers.addAll(headers);
//     } catch (e) {
//       debugPrint(e);
//     }
//
//
//     try {
//       http.StreamedResponse response = await request.send();
//       if (response.statusCode == 200) {
//         var result = await response.stream.bytesToString();
//         token = 'Token ' + convert.json.decode(result)['token'];
//         debugPrint(result);
//         debugPrint('successful retrieval of credentials');
//
//         return true;
//       } else {
//         debugPrint('${response.statusCode}');
//         debugPrint(response.reasonPhrase);
//
//         return false;
//       }
//     } catch (e) {
//       debugPrint(e);
//       return false;
//     }
//
//   }
//
//   Future<bool> requestPayment(String phoneNumber) async {
//     var headers = {
//       'Authorization': token,
//       'Content-Type': 'application/json'
//     };
//     var request = http.Request('POST', Uri.parse(requestPaymentUrl));
//     request.body = convert.json.encode({
//       "amount": minAmount,
//       "currency": "XAF",
//       "from": '237' + phoneNumber,
//       "description": "Test",
//       "external_reference": "",
//       "external_user": ""
//     });
//
//     request.headers.addAll(headers);
//
//     try {
//       http.StreamedResponse response = await request.send();
//       if (response.statusCode == 200) {
//         var result = await response.stream.bytesToString();
//         debugPrint(result);
//         reference = convert.json.decode(result)['reference'];
//         ussdCode = convert.json.decode(result)['ussd_code'];
//         operator = convert.json.decode(result)['operator'];
//         debugPrint('successful payment request');
//         return true;
//       }
//       else {
//         debugPrint('${response.statusCode}');
//         debugPrint(response.reasonPhrase);
//         return false;
//       }
//     } catch (e) {
//       debugPrint(e.message);
//       return false;
//     }
//   }
//
//
//   Future<String> transactionStatus() async {
//     debugPrint(token);
//     var headers = {
//       'Authorization': token,
//       'Content-Type': 'application/json'
//     };
//
//     var request = http.Request('GET', Uri.parse(transactionStatusUrl));
//     request.headers.addAll(headers);
//
//     try {
//       http.StreamedResponse response = await request.send();
//       var result = await response.stream.bytesToString();
//       status = convert.json.decode(result)['status'];
//
//       debugPrint('transactions status: $status');
//       if (response.statusCode == 200) {
//         debugPrint('successful retrieval of transaction status');
//         debugPrint(result);
//         if (status == 'SUCCESSFUL')
//           return 'SUCCESSFUL';
//         else if(status == 'FAILED')
//           return 'FAILED';
//         else if(status == 'PENDING')
//           return 'PENDING';
//       }
//       else {
//         debugPrint('${response.statusCode}');
//         debugPrint(response.reasonPhrase);
//         return 'ERROR1';
//       }
//     } catch (e) {
//       debugPrint(e.message);
//       return 'ERROR2';
//     }
//   }
//
//   Future<bool> mobileMoneyPayment() async {
//     bool result = false;
//     if(await getApiInfo()) {
//       result = await Navigator.push(context, MaterialPageRoute(builder: (context) =>
//           GetMomoNumScreen(
//             transactionStatus: transactionStatus,
//             getCredentials: getCredentials,
//             requestPayment: requestPayment,
//             getCode: getCode,
//             recordPaymentCallback: recordPaymentCallback,
//             getApiInfo: getApiInfo,
//             minAmount: minAmount,
//           )));
//     }
//     debugPrint('-----result has been returned-------');
//     return result;
//   }
//
// }
//
//
//
//
// class GetMomoNumScreen extends StatefulWidget {
//   final String network;
//   final Function transactionStatus;
//   final Function getCredentials;
//   final Function requestPayment;
//   final Function getCode;
//   final Function recordPaymentCallback;
//   final Function getApiInfo;
//   final String minAmount;
//   GetMomoNumScreen({@required this.recordPaymentCallback, @required this.minAmount, @required this.getApiInfo, this.network = 'MTN', this.transactionStatus, this.requestPayment, this.getCredentials, this.getCode});
//   @override
//   _GetMomoNumScreenState createState() => _GetMomoNumScreenState();
// }
//
// class _GetMomoNumScreenState extends State<GetMomoNumScreen> {
//   final formKeyMomoNum = GlobalKey<FormState>();
//
//
//   bool result;
//   TextEditingController numberController = TextEditingController();
//   bool hasGottenSmsNumber = false;
//   bool isLoading = false;
//   bool isPaymentConfirmed = false;
//   void startLoading(){
//     setState(() {
//       isLoading = true;
//     });
//   }
//
//
//   void stopLoading() {
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   Stream<String> transactionStatusStream() async*{
//     while(true) {
//       String result = await widget.transactionStatus();
//       await Future.delayed(Duration(seconds: 3));
//       yield result;
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async{
//         Navigator.pop(context, false);
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: appColor,
//         body: ModalProgressHUD(
//           inAsyncCall: isLoading,
//           child: Center(
//               child: Container(
//                 margin: EdgeInsets.all(20),
//                 padding: EdgeInsets.all(20),
//                 height: 250,
//                 decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.all(
//                         Radius.circular(20)
//                     )
//                 ),
//                 child: Form(
//                   key: formKeyMomoNum,
//                   child: SingleChildScrollView(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(AppLocalizations.of(context).requestPaymentNum(widget.minAmount),
//                             textAlign: TextAlign.center),
//                         SizedBox(
//                           height: 10,
//                         ),
//                         TextFormField(
//                             keyboardType: TextInputType.number,
//                             controller: numberController,
//                             validator: (newNumber) {
//                               String newNum = newNumber.trim().replaceAll(' ','');
//                               if(newNum.length != 9) {
//                                 return AppLocalizations.of(context).invalidNum;
//                               }
//                               else if (newNum.substring(0,1) != '6') {
//                                 return AppLocalizations.of(context).numMustBeginWith6;
//                               }
//                               else return null;
//                             }
//                         ),
//                         FlatButton(
//                             color: appColor,
//                             onPressed: () async{
//                               // await initiatePayment(numberController.text);
//                               if (formKeyMomoNum.currentState.validate()) {
//                                 startLoading();
//                                 if(await widget.getCredentials()){
//                                   debugPrint('----i got the payment credentials------');
//                                   if(await widget.requestPayment(numberController.text)) {
//                                     stopLoading();
//                                     bool hasUserAcceptedPayment = await Navigator.push(context, MaterialPageRoute(builder: (context) => TimerScreen(transactionStatusStream : transactionStatusStream(),getCode: widget.getCode , transactionStatus: widget.transactionStatus, recordPaymentCallback: widget.recordPaymentCallback )));
//                                     Navigator.pop(context, hasUserAcceptedPayment);
//                                   } else {
//                                     stopLoading();
//                                     Navigator.pop(context);
//                                   }
//                                 } else {
//                                   stopLoading();
//                                   Navigator.pop(context);
//                                 }
//                               }
//                             },
//                             child: Text(AppLocalizations.of(context).pay)),
//                         SizedBox(
//                           height: 10,
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Image.asset('assets/orange_money.jpg',
//                               height: 30,),
//                             Image.asset('assets/mtn_momo.jpg',
//                                 height: 30),
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               )
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
// class TimerScreen extends StatefulWidget {
//   final Stream<String> transactionStatusStream;
//   final Function getCode;
//   final Function transactionStatus;
//   final Function recordPaymentCallback;
//   TimerScreen({@required this.recordPaymentCallback, this.transactionStatusStream, this.getCode, this.transactionStatus});
//
//   @override
//   _TimerScreenState createState() => _TimerScreenState();
// }
//
// class _TimerScreenState extends State<TimerScreen> {
//
//   int _timeout = 180;
//   int _counter = 0;
//   String _status = 'PENDING';
//   Stream myStream = timerCounter();
//   bool requestSent = false;
//   bool result = false;
//   bool isLoading = false;
//   StreamSubscription streamSubscription;
//
//   // StreamSubscription timerSubscription;
//
//   void startLoading() {
//     if (mounted) {
//       setState(
//               () {
//             isLoading = true;
//           }
//       );
//     }
//   }
//
//   void stopLoading() {
//     if (mounted) {
//       setState(
//               () {
//             isLoading = false;
//           }
//       );
//     }
//   }
//
//   Future<bool> isThereConnection() async {
//     try {
//       final result = await InternetAddress.lookup('www.google.com');
//       if(result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
//         debugPrint('------connected to the internet----');
//         debugPrint('----you are not connected to the internet--1---');
//         return true;
//       }
//       final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
//       ScaffoldMessenger.of(context).showSnackBar(msg);
//       return false;
//     }on SocketException catch (e) {
//       debugPrint('----you are not connected to the internet--2---');
//       final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
//       ScaffoldMessenger.of(context).showSnackBar(msg);
//       return false;
//     }
//   }
//
//   Future<void> checkStatus () async{
//     int i = 0;
//     String status = '';
//     while(i<5){
//       startLoading();
//       status = await widget.transactionStatus();
//       if(status == 'PENDING') {
//         stopLoading();
//         final SnackBar msg = SnackBar(content: Text('Transaction is still pending'), duration: Duration(seconds: 1));
//         ScaffoldMessenger.of(context).showSnackBar(msg);
//         if( i == 4) {
//           break;
//         }
//       }
//       else if(status == 'SUCCESSFUL') {
//         await widget.recordPaymentCallback();
//         break;
//       }
//       else if(status == 'FAILED') {
//         break;
//       }
//       else if (status == 'ERROR2'){
//         debugPrint('an error occurred');
//         stopLoading();
//         final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).connectionFailed));
//         ScaffoldMessenger.of(context).showSnackBar(msg);
//       }
//       i++;
//       await Future.delayed(Duration(seconds: 2));
//     }
//     if(status == 'SUCCESSFUL') Navigator.pop(context, true);
//     else if (status == 'FAILED') Navigator.pop(context, false);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     debugPrint('disposed method was called');
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var locale = AppLocalizations.of(context);
//     debugPrint(
//         'the build method was called'
//     );
//     return WillPopScope(
//       onWillPop: () async => false, //This line of code prevents an abrupt exit from this screen when joining the queue
//       child: Scaffold(
//           backgroundColor: appColor,
//           body: StreamBuilder<int>(
//               stream: myStream,
//               builder: (context, snapshot) {
//                 debugPrint('stream builder was executed ');
//                 if(snapshot.hasData) {
//                   _counter = snapshot.data;
//                   if(_counter >= _timeout) Future((){Navigator.pop(context, false);});
//                 }
//
//                 return ModalProgressHUD(
//                   inAsyncCall: isLoading,
//                   child: Center(
//                     child: Container(
//                       decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.all(
//                               Radius.circular(20)
//                           )
//                       ),
//                       height: 200,
//                       margin: EdgeInsets.all(20),
//                       padding: EdgeInsets.all(20),
//                       child: Center(
//                         child: SingleChildScrollView(
//                           child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text( "${locale.pleaseDial} ${widget.getCode()}  ${locale.dialCont}",
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       color: Colors.black,
//                                     )),
//                                 Text('${locale.transStatus}: $_status',
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       color: Colors.blue,
//                                     )),
//                                 Text('${locale.youHave} ${_timeout - _counter} ${locale.secondsLeft}...',
//                                     style: TextStyle(
//                                       color: Colors.red,
//                                       fontSize: 12,
//                                     )),
//
//                                 SizedBox(
//                                   height: 15,
//                                 ),
//                                 FlatButton(
//                                     color: appColor,
//                                     onPressed: () async {
//                                       await isThereConnection();
//                                       await checkStatus();
//                                     },
//                                     child: Text('OK'))
//                               ]
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }
//           )
//       ),
//     );
//   }
// }
//
