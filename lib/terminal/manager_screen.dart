import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:no_queues_manager/screens/log_in_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:no_queues_manager/screens/my_clients_screen.dart';
import 'package:no_queues_manager/sms.dart';
import 'package:no_queues_manager/models/messaging.dart';
import 'package:no_queues_manager/screens/add_unregistered_client_screen.dart';
import 'package:no_queues_manager/screens/validate_unregistered_client_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:core';
import 'package:no_queues_manager/data_analysis/time_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_manager/my_widgets/dialogs.dart';
import 'package:no_queues_manager/data/manager_details.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_manager/screens/editing_screen.dart';
import 'package:no_queues_manager/my_widgets/dialogs.dart';
import 'package:no_queues_manager/screens/my_routes_screen.dart';
import 'package:no_queues_manager/screens/paused_queue_screen.dart';
import 'package:no_queues_manager/push_notification.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ManagerScr extends StatefulWidget {
  ///Booliean flags to hold some of the terminal permissions
  final bool validateClientPermission;
  final bool addClientPermission;
  final String managerId;
  final bool nextPermission;
  final bool skipPermission;

  ManagerScr({@required this.validateClientPermission, @required this.addClientPermission, @required this.managerId, @required this.skipPermission, @required this.nextPermission});

  @override
  _ManagerScrState createState() => _ManagerScrState();
}

class _ManagerScrState extends State<ManagerScr> {
  static const int maxSkipCount = 2;
  DocumentSnapshot userDoc; //the document containing the details of the current user
  bool isOpen = true; //is the queue active or not
  String recentToken; //Holds the most recent client token generated for an unregistered client
  String managerName = "unknown";
  String serviceCode = "unknown";
  String email = FirebaseAuth.instance.currentUser.email;
  bool isLoadingActions = false;
  bool isLoadingStreams = false;
  int clientCount = 0;
  List timeData = [];
  List emptyList = [];
  int currentClientIndex = 3;
  int firstClientIndex = 3;
  int firstNotificationIndex = 3;
  int secondNotificationIndex = 3;
  List<MsgData> firstMessages = [];
  List<MsgData> secondMessages = [];
  String currentClientName = 'N/A';
  String currentClientPhoneNumber = 'N/A';
  String currentClientId = 'N/A';
  String currentClientOnesignalDeviceToken = '';
  int currentClientInitialPosition = 0;
  int currentClientSkipCount = 0;
  int currentSampleCount = 0;
  String currentClientLanguage = 'en';
  var currentClientTimestamp;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isPreValidated = false;

  bool isSkipButtonPressed = false;
  String currentClientToken = '';
  bool isCurrentClientRegistered = true;
  int previousClientCount = 0;
  int previousFirstClientIndex = 0;
  Timestamp prevTransitionTime;
  int timePeriod;

  get id {
    return widget.managerId;
  }

  ///This Global key variable allows us to access the state of the statefulbuilder stateful widget
  final GlobalKey _statefulBuilderState = GlobalKey();

  Future<void> saveAccountType(String accountType) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastAccountType', accountType);
  }

  void logout() async{
    await FirebaseAuth.instance.signOut();
    await saveAccountType('void');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
        LogInScreen()));
  }

  String realName(String username) {
    List<String> _usernameList = username.split('|');
    String _username = '';
    for(var name in _usernameList) {
      debugPrint('----name = ${name}----');
      if(!name.contains('@')){
        _username = _username + ' ' +name.toUpperCase();
      } //TODO:  '@' as a reserved character.
    }
    return _username.trim();
  }

  String initials(String text) {
    text = text.trim();
    List<String> words = text.split(' ');
    String initials = '';
    for(String word in words) {
      initials = initials + word.substring(0,1);
    }
    String allInitials = initials.toUpperCase(); //might need this in the future but all i need for the now is just the first initial
    String firstLetter = allInitials.substring(0,1);
    return firstLetter;
  }

  Widget profileImage() {
    var locale = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                  content: SingleChildScrollView(
                    child: Container(
                      child: Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                  backgroundColor: Colors.lightBlueAccent,
                                  radius: 20,
                                  child: Center(
                                      child: Text(initials(managerName),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                          ))
                                  )
                              ),

                              SizedBox(
                                height: 10,
                              ),
                              Text(managerName.toUpperCase(),textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
                              SizedBox(
                                height: 10,
                              ),
                              RichText(
                                  text: TextSpan(
                                      children: [
                                        TextSpan(text: 'Code: ', style: TextStyle(color: Colors.blue)),
                                        TextSpan(text: serviceCode, style: TextStyle(color: Colors.black))
                                      ]
                                  )),
                            ],
                          )
                      ),
                    ),
                  )
              );
            }
        );
      },
      child: Center(
          child: CircleAvatar(
              backgroundColor: Colors.lightBlueAccent,
              radius: 20,
              child: Center(
                  child: Text(initials(managerName),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ))
              )
          )
      ),
    );
  }


  ///checks to see if the required client delay period of 0.5*timePeriod has been respected
  ///Can skip a client if and only if this delay period is exhausted
  ///Used when skipping a registered client in the absence of an unregistered client

  bool isClientRegistered(QueryDocumentSnapshot clientDoc) {
    bool result = false;
    try {
      bool isRegistered = clientDoc['registered'];
      if (isRegistered == false) result = false;
      else if (isRegistered == true) result = true;
    }catch(e){
      debugPrint('$e');
      result = true;
    }

    isCurrentClientRegistered = result;
    return result;
  }

  void refresh() {
    setState(() {
    });
  }

  Future<void> getManagerDetails() async {
    try{
      //dynamic provider = Provider.of(context)<ManagerDetails>(context, listen: false);
      DocumentSnapshot manDetails = await FirebaseFirestore.instance.collection('manager_details').doc(id).get();
      userDoc = manDetails;
      String _managerName = manDetails['name'];
      String _serviceCode = manDetails['service_code'];
      bool _queueState = manDetails['open'];
      debugPrint('----$_managerName-----');

      try {
        if(mounted) {
          Provider.of(context)<ManagerDetails>(context, listen: false).setName(manDetails['name']);
        }
      }catch(e) {
        debugPrint('$e');
      }
      setState(() {
        managerName = _managerName;
        serviceCode = _serviceCode;
        isOpen = _queueState;
      });
    }catch(e){
      debugPrint('$e');
      debugPrint('---something went wrong-----');
    }
  }

  @override
  void initState() {
    super.initState();
    Future(() async{
      _statefulBuilderState.currentState.setState((){isLoadingStreams = true;});
      await getManagerDetails();
      await Dialogs(context: context).checkUpdatesDialog();
      _statefulBuilderState.currentState.setState((){isLoadingStreams = false;});

    });
  }


  void showSnackBar({String text, int duration}) {
    final SnackBar msg = SnackBar(content: Text(
      text,
    ), duration: Duration(seconds: duration));
    ScaffoldMessenger.of(context).showSnackBar(msg);
  }

 Future<void> extractInfo(DocumentSnapshot managerDoc) async{
    _statefulBuilderState.currentState.setState((){isLoadingStreams = true;});
    userDoc = managerDoc;
    clientCount = managerDoc['client_count'];
    debugPrint('-----client count : $clientCount------');
    firstClientIndex = managerDoc['first_client_index'];
    debugPrint('-----firstClientIndex: $firstClientIndex-----');
    managerName = managerDoc['name'] ?? 'N/A';
    debugPrint('-------managerName: $managerName-------');
    isOpen = managerDoc['open'] ?? true;
    debugPrint('-------QueueState: ${isOpen ? 'Open' : 'Closed'}-------');

    ///try to retrieve time period
    try {
      timePeriod = managerDoc['time_period'];
      debugPrint('-------timePeriod: $timePeriod-------');
    } catch (e) {
      debugPrint('$e');
      timePeriod = null;
    }

    ///try to retrieve the previous transition time
    try {
      prevTransitionTime = managerDoc['prev_transition_time'];
      debugPrint('-------prevTransitionTime: $prevTransitionTime-------');
    } catch (e) {
      debugPrint('$e');
      prevTransitionTime = null;
    }

    ///try to retrieve the timeData and the client count
    try {
      timeData = managerDoc['time_data'];
      debugPrint('-------timeData: $timeData-------');
      currentSampleCount = timeData.length;
      debugPrint('-------currentSampleCount: $currentSampleCount-------');

    } catch (e) {
      debugPrint('$e');
      currentSampleCount = 0;
      final SnackBar msg = SnackBar(content: Text('currentSampleCount: $e'), duration: Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(msg);
    }

    if(currentSampleCount == 10) {
      //TODO: compute the average time period(add statistical logic here)
    }

    if(clientCount != previousClientCount || previousFirstClientIndex != firstClientIndex ) {
      previousClientCount = clientCount; //this is to avoid unnecessary execution of this function
      previousFirstClientIndex = firstClientIndex; // this is to avoid unnecessary execution of this function

      QuerySnapshot clientDetailsSnapshot =  await _db.collection('manager_details').doc(id).collection('subscribers')
          .where('client_index', isEqualTo: firstClientIndex).get();

      try {
        debugPrint('----return list is empty: ${clientDetailsSnapshot.docs.isEmpty}-----');
        QueryDocumentSnapshot clientDoc = (clientDetailsSnapshot.docs)[0];
        currentClientIndex = clientDoc['client_index'];
        debugPrint('-----currentClientIndex: $currentClientIndex------');
        currentClientName = clientDoc['name'];
        debugPrint('-----currentClientName: $currentClientName------');
        currentClientInitialPosition = clientDoc['initial_position'];
        debugPrint('-----currentClientInitialPosition: $currentClientInitialPosition------');
        currentClientId = clientDoc['client_id'];
        debugPrint('---------currentClientId: $currentClientId------');
        currentClientSkipCount = clientDoc['skip_count'];
        debugPrint('---------currentClientSkipCount: $currentClientSkipCount------');
        currentClientTimestamp = clientDoc['timestamp'];
        debugPrint('------currentClientTimestamp: $currentClientTimestamp------');
        try { //todo: can remove this try and catch block after resetting the database
          isPreValidated = clientDoc['is_pre_validated'];
          debugPrint('-----validation state: $isPreValidated------');
        }catch(e) {
          debugPrint('$e');
        }

        //checking if the current client is registered or not so as to extract data from some particular fields
        if(isClientRegistered(clientDoc)){
          firstNotificationIndex = clientDoc['first_notification_index'];
          debugPrint('--------firstNotificationIndex: $firstNotificationIndex-------');
          secondNotificationIndex = clientDoc['second_notification_index'];
          debugPrint('---------secondNotificationIndex: $secondNotificationIndex------');
          currentClientPhoneNumber = clientDoc['phone'];
          debugPrint('------currentClientPhoneNumber: $currentClientPhoneNumber------');
          currentClientOnesignalDeviceToken = clientDoc['one_signal_token_id'];
          debugPrint('------currentClientDeviceToken: $currentClientOnesignalDeviceToken----');
          currentClientLanguage = clientDoc['lang'];
          debugPrint('------currentClientLanguage: $currentClientLanguage------');
        }else {
          currentClientToken = clientDoc['token'];
        }

        firstMessages = [];
        try {
          QuerySnapshot clientsForFirstNotificationSnapshot =  await _db.collection('manager_details').doc(id).collection('subscribers')
              .where('first_notification_index', isEqualTo: currentClientIndex).get();
          List<QueryDocumentSnapshot> clientsForFirstNotificationDocs = clientsForFirstNotificationSnapshot.docs;
          for (QueryDocumentSnapshot clientDoc in clientsForFirstNotificationDocs) {
            debugPrint('-------FIRST NOTIFICATION MESSAGE CLIENT DETAILS--------');
            debugPrint('-------receiverPhoneNumber: ${clientDoc['phone']}-------');
            debugPrint('-------receiverDeviceToken: ${clientDoc['one_signal_token_id']}-------');
            debugPrint('-------receiverName: ${clientDoc['name']}-------');
            firstMessages.add(
                MsgData(
                    senderName: managerName,
                    receiverPhoneNumber: clientDoc['phone'],
                    receiverDeviceToken: clientDoc['one_signal_token_id'],
                    receiverId: clientDoc['client_id'],
                    receiverName: clientDoc['name'],
                    receiverInitialPosition: clientDoc['initial_position'],
                    receiverLanguage: clientDoc['lang'],
                    completionPercentage: 0.6
                )
            );
          }
        }catch (e) {
          debugPrint('-----could not load first notification messages--------');
        }

        secondMessages = [];
        try {
          QuerySnapshot clientsForSecondNotificationSnapshot =  await _db.collection('manager_details').doc(id).collection('subscribers')
              .where('second_notification_index', isEqualTo: currentClientIndex).get();
          List<QueryDocumentSnapshot> clientsForSecondNotificationDocs = clientsForSecondNotificationSnapshot.docs;
          for (QueryDocumentSnapshot clientDoc in clientsForSecondNotificationDocs) {
            debugPrint('-------SECOND NOTIFICATION MESSAGE CLIENT DETAILS--------');
            debugPrint('-------receiverPhoneNumber: ${clientDoc['phone']}-------');
            debugPrint('-------receiverDeviceToken: ${clientDoc['one_signal_token_id']}-------');
            debugPrint('-------receiverName: ${clientDoc['name']}-------');
            secondMessages.add(
                MsgData(
                    senderName: managerName,
                    receiverPhoneNumber: clientDoc['phone'],
                    receiverDeviceToken: clientDoc['one_signal_token_id'],
                    receiverName: clientDoc['name'],
                    receiverId: clientDoc['client_id'],
                    receiverInitialPosition: clientDoc['initial_position'],
                    receiverLanguage: clientDoc['lang'],
                    completionPercentage: 0.8
                )
            );
          }
        } catch (e) {
          debugPrint('-------was unable to load the second notification messages---------');
        }
      } catch (e) {
        debugPrint('$e');
        debugPrint('-----------was unable to extract the client info---------');
      }
      _statefulBuilderState.currentState.setState((){isLoadingStreams = false;});
      _statefulBuilderState.currentState.setState((){});
    }
    _statefulBuilderState.currentState.setState((){isLoadingStreams = false;});
    _statefulBuilderState.currentState.setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => ManagerDetails(),
        builder: (context, child) =>  SafeArea(
            child: ModalProgressHUD(
                inAsyncCall: isLoadingActions,
                child: StreamBuilder<DocumentSnapshot>(
                    stream: _db.collection('manager_details').doc(id).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        isLoadingStreams = true;
                      } else {
                        isLoadingStreams = false;
                        //this might pose a problem
                        print('----stream loaded-----');
                        extractInfo(snapshot.data);
                      }
                      return StatefulBuilder(
                          key: _statefulBuilderState,
                          builder: (context, setState) {

                            void startLoading() {
                              setState(() {
                                isLoadingStreams = true;
                              });
                            }

                            void stopLoading() {
                              setState(() {
                                isLoadingStreams = false;
                              });
                            }

                            bool clientDelayPeriodIsExhausted() {
                              ///If previousTransition time is null or timePeriod is null, just return true and proceed
                              if(prevTransitionTime == null || timePeriod == null) return true;

                              ///Previous transition time is a timestamp so we need to convert it to a DateTime Object
                              DateTime _prevTransitionTime = prevTransitionTime.toDate();

                              ///Getting the current time
                              DateTime _currentTime = DateTime.now();

                              ///Get the time interval since last transition (in seconds since time period is also in seconds);
                              int _timeIntervalSinceLastTransition = _currentTime.difference(_prevTransitionTime).inSeconds;

                              debugPrint('-----Time interval since last transition: $_timeIntervalSinceLastTransition------');

                              ///Calculate the time left before the client can securely be skipped
                              int _waitingTimeLeft = (0.5 * timePeriod - _timeIntervalSinceLastTransition).round();

                              ///extracting hours, minutes and seconds from _waiting time left
                              int _hours =( _waitingTimeLeft / 3600).floor();
                              int _minutes = ((_waitingTimeLeft - _hours * 3600) / 60).floor();
                              int _seconds = (_waitingTimeLeft - _hours * 3600 - _minutes * 60);
                              String timeString = '${(_hours == 0) ? '': '$_hours h'}' + ' ${(_minutes == 0) ? '': '$_minutes m'}'+' ${(_seconds == 0) ? '': '$_seconds s '}';

                              ///Check if timeInterval is greater than 50% of the time period
                              if (_timeIntervalSinceLastTransition < 0.5 * timePeriod) {
                                Dialogs(context: context).customDialog(text: 'Its too early to skip this client. You can skip the client after $timeString.'); //todo: translate
                                return false;
                              }else return true;

                            }

                            void resetVariables() {
                              setState((){
                                isLoadingActions = false;
                                isLoadingStreams = false;
                                clientCount = 10;
                                currentClientIndex = 3;
                                firstClientIndex = 3;
                                firstNotificationIndex = 3;
                                secondNotificationIndex = 3;
                                firstMessages = [];
                                secondMessages = [];
                                timeData = [];
                                currentClientName = 'Anonymous';
                                currentClientPhoneNumber = 'N/A';
                                currentClientLanguage = 'en';
                                currentClientId = 'N/A';
                                currentClientOnesignalDeviceToken = '';
                                currentClientInitialPosition = 0;
                                currentClientSkipCount = 0;
                                currentSampleCount = 0;
                                isPreValidated = false;
                                isSkipButtonPressed = false;
                                isCurrentClientRegistered = true;
                                previousClientCount = 0;
                                previousFirstClientIndex = 0;
                                currentClientToken = '';
                                prevTransitionTime = null;
                              });
                            }

                            Future<void> validateRegClient() async {
                              if(widget.validateClientPermission == false) {
                                debugPrint('Your are not authorised to validate this client');
                                return;
                              }
                              String lineColor = '#ff6666';
                              String cancelButtonText = 'cancel';
                              bool isShowFlashIcon = true;
                              ScanMode scanMode = ScanMode.QR;
                              String scanResult;
                              try {
                                scanResult = await FlutterBarcodeScanner.scanBarcode(
                                    lineColor, cancelButtonText, isShowFlashIcon, scanMode);
                              } on PlatformException {
                                scanResult = 'failed to get platform version: ';
                              }
                              if (!mounted) return;
                              try {
                                if (currentClientId == scanResult) {
                                  await _db.runTransaction((transaction) async {
                                    var managerDocRef = _db.collection('manager_details').doc(id);
                                    var clientDocRef = managerDocRef.collection('subscribers').doc(currentClientId);
                                    var managerDoc = await transaction.get(managerDocRef);
                                    if(managerDoc.exists) {
                                      try{
                                        Timestamp prevValTime = managerDoc['prev_val_time'];
                                        List<dynamic>_timeData = [];
                                        try{
                                          _timeData = managerDoc['time_data'];
                                        }catch(e) {
                                          debugPrint('$e');
                                        }


                                        var currentValTime = DateTime.now();
                                        var duration = currentValTime.difference(prevValTime.toDate()).inSeconds; //TODO: LATER ON CHANGE ,THIS THING TO MINUTES
                                        _timeData.add(duration);  //update time data
                                        debugPrint('-------duration in seconds : $duration seconds------');

                                        transaction.set(clientDocRef, {
                                          'is_pre_validated' : true
                                        }, SetOptions(merge: true));
                                      }catch(e) {
                                        debugPrint('$e');
                                        debugPrint('----unable to set prevalidation to true-----');
                                      }
                                    } else {
                                      debugPrint('---the manager you are looking for does not exist-----');
                                    }
                                  });
                                  setState(() {
                                    isPreValidated = true;
                                  });
                                  Dialogs(context: context).success();
                                }else {
                                  await Dialogs(context: context).failureDialog();
                                }
                              } catch (e) {
                                final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).valErrorMsg), duration: Duration(seconds: 1));
                                ScaffoldMessenger.of(context).showSnackBar(msg);
                                debugPrint('----unable to validate this client----');
                              }
                            }

                            Future<void> validateUnregClient(BuildContext context) async {
                              if(widget.validateClientPermission == false) {
                                debugPrint('Your are not authorised to validate this client');
                                return;
                              }
                              bool result = await validateUnregisteredClient(currentClientToken, context);
                              try {
                                if (result != null && result == true) {
                                  await _db.runTransaction((transaction) async {
                                    ///set references for the manager and the client
                                    var managerDocRef = _db.collection('manager_details').doc(id);
                                    var clientDocRef = managerDocRef.collection('subscribers').doc(currentClientId);

                                    ///get the manager documents
                                    var managerDoc = await transaction.get(managerDocRef);
                                    if(managerDoc.exists) {
                                      try{

                                        transaction.set(clientDocRef, {
                                          'is_pre_validated' : true
                                        }, SetOptions(merge: true));
                                      }catch(e) {
                                        debugPrint('$e');
                                        debugPrint('----setting previous validation time-----');
                                      }
                                    } else {
                                      debugPrint('-----the manager you are looking for does not exist-----');
                                    }
                                  });
                                  setState(() {
                                    isPreValidated = true;
                                  });
                                }else{
                                  await Dialogs(context: context).failureDialog();
                                }
                              } catch (e) {
                                final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).valErrorMsg), duration: Duration(seconds: 1));
                                ScaffoldMessenger.of(context).showSnackBar(msg);
                                debugPrint('----unable to validate this client----');
                              }
                            }

                            Widget activeScreen() {
                              return SingleChildScrollView(
                                child: Container(
                                  //margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                  height:MediaQuery.of(context).size.height * 0.9,
                                  child: Column(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                              children: [
                                                vCard(onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => MyClientsScreen(managerId: id)));} ,child: Center(child: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      AutoSizeText('$clientCount',
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            fontSize: 100,
                                                            color: Colors.green,
                                                          )),
                                                      Text('${(clientCount == 1) ? AppLocalizations.of(context).clientWaiting
                                                          : AppLocalizations.of(context).clientsWaiting}')
                                                    ],
                                                  ),
                                                ))),
                                                vCard(onTap: () async {if (!isPreValidated && clientCount != 0) {
                                                  startLoading();
                                                  if(isCurrentClientRegistered) await validateRegClient();
                                                  else await validateUnregClient(context);
                                                  stopLoading();
                                                }else {
                                                  final SnackBar msg = SnackBar(content: Text(
                                                    AppLocalizations.of(context).alreadyValidated,
                                                  ), duration: Duration(seconds: 1));
                                                  ScaffoldMessenger.of(context).showSnackBar(msg);
                                                }}, child: Center(
                                                  child: SingleChildScrollView(
                                                    child: isPreValidated ? Icon(Icons.check,
                                                        size: 70,
                                                        color: Colors.green) : Text('?',
                                                        style: TextStyle(
                                                          color: Colors.orange,
                                                          fontSize: 70,
                                                          fontWeight: FontWeight.bold,
                                                        )),
                                                  ),
                                                ))
                                              ]
                                          ),
                                        ),
                                        hCard(context: context, flex: 2,
                                          child: (clientCount == 0)? Center(child: Text(AppLocalizations.of(context).noClients)) : SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                Center(
                                                    child: Text(
                                                        AppLocalizations.of(context).currentClient
                                                    )),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 30),
                                                  child: Divider(thickness: 2,
                                                      color: Colors.red),
                                                ),
                                                SizedBox(height: 20),
                                                Center(
                                                    child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text('${AppLocalizations.of(context).name}: ', style: TextStyle(color: Colors.blue)),
                                                          SizedBox(height: 5),
                                                          Text((currentClientName == null || currentClientName == '') ? (AppLocalizations.of(context).anonymous) :'${currentClientName.toUpperCase()}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))
                                                        ]
                                                    )),

                                                SizedBox(height: 10),
                                                Center(
                                                    child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text('Tel: ', style: TextStyle(color: Colors.blue)),
                                                          SizedBox(height: 5),
                                                          Text('${currentClientPhoneNumber.toUpperCase()}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,))
                                                        ]
                                                    )),
                                              ],
                                            ),
                                          ), ),
                                        hCard(context: context, flex: 2,
                                          child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                widget.validateClientPermission ? Center(
                                                  child: ElevatedButton(
                                                      style: ButtonStyle(
                                                        backgroundColor: MaterialStateProperty
                                                            .all(Colors.green),
                                                        elevation: MaterialStateProperty.all(5),
                                                      ),
                                                      onPressed: () async {
                                                        startLoading();
                                                        try {
                                                          if (!isPreValidated && clientCount != 0) {
                                                            if(isCurrentClientRegistered) await validateRegClient().timeout(Duration(seconds: 5));
                                                            else await validateUnregClient(context).timeout(Duration(seconds: 5));
                                                            stopLoading();
                                                          }else {
                                                            final SnackBar msg = SnackBar(content: Text(
                                                              AppLocalizations.of(context).alreadyValidated,
                                                            ), duration: Duration(seconds: 1));
                                                            ScaffoldMessenger.of(context).showSnackBar(msg);
                                                          }
                                                        } on TimeoutException catch (e) {
                                                          debugPrint('$e');
                                                          debugPrint('------Validation method has just timed out------');
                                                        }
                                                        stopLoading();
                                                      },
                                                      child: AutoSizeText(
                                                          AppLocalizations.of(context).validate,
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          )
                                                      )),
                                                ) : Container(child: null),
                                              ]
                                          ), ),
                                      ]
                                  ),
                                ),
                              );
                            }

                            return ModalProgressHUD(
                              inAsyncCall: isLoadingStreams,
                              child: Scaffold(
                                appBar: AppBar(
                                  backgroundColor: appColor,
                                  actions: [
                                    Center(child: (recentToken != null) ? Text('($recentToken)') : null),
                                    IconButton(icon: Icon(Icons.add),
                                      onPressed: ()async{
                                        var firstRecentToken = await AddUnregClient(managerId: widget.managerId).addUnregClient(context, startLoading, stopLoading);                                        if (firstRecentToken != null) {
                                          setState((){
                                            recentToken = firstRecentToken;
                                          });
                                        }
                                      },),
                                    profileImage(),
                                  ],
                                  title: SingleChildScrollView(
                                    child: AutoSizeText(AppLocalizations.of(context).dashBoard,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        )),
                                  ),
                                ),
                                body: activeScreen(),
                              ),
                            );
                          }
                      );
                    }
                )
            )
        )
    );
  }
}

class hCard extends StatelessWidget {
  const hCard({
    Key key, @required this.context, this.child, this.color = Colors.white, this.width, this.flex = 1, this.onTap}) : super(key: key);
  final Widget child;
  final Color color;
  final int flex;
  final Function onTap;
  final double width;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Material(
        elevation: 10,
        shadowColor: appColor,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              width: width ?? MediaQuery.of(context).size.width,
              color: color,
              child: child
          ),
        ),
      ),
    );
  }
}

class vCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double height;
  final int flex;
  final Function onTap;
  const vCard({Key key, this.child, this.color = Colors.white, this.height = 300, this.flex = 1, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Material(
        elevation: 10,
        shadowColor: appColor,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              height: height,
              color: color,
              child: child
          ),
        ),
      ),
    );
  }
}





