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
  ///Booliean flags to hold some of the terminal privileges
  final bool canValidateClient;
  final bool canAddClient;
  final String managerId;
  final bool canProceedToNextClient;
  final bool canSkipClient;

  ManagerScr({@required this.canValidateClient, @required this.canAddClient, @required this.managerId, @required this.canSkipClient, @required this.canProceedToNextClient});

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
  bool isValidated = false;
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

  Future<void> sendSMSReminders({List firstMessages, List secondMessages}) async {

    PushNotificationService _pushNotificationService = PushNotificationService();

    Future<void> firstReminder() async{
      if(firstMessages == [] || firstMessages == null) {
        debugPrint('-----There are no available first notification messages------');
        return;
      }
      try {
        for(MsgData msgData in firstMessages) {
          debugPrint('-----sending a first notification message to: ${msgData.receiverName}------');
          await SMSService().send(msgData);
          await _pushNotificationService.sendNotification(
              tokenIdList: [msgData.receiverDeviceToken],
              contents: msgData.body,
              heading: msgData.title
          );
          debugPrint('-----successful transmission of message to: ${msgData.receiverName}------');
        }
      } catch (e) {
        debugPrint('-----Failed to send the first notification messages-----');
      }
    }

    Future<void> secondReminder() async{
      if(secondMessages == [] || secondMessages == null) {
        debugPrint('-----There are no available seconds notification messages------');
        return;
      }
      try {
        for(MsgData msgData in secondMessages) {
          debugPrint('-----sending a second notification message to: ${msgData.receiverName}------');
          await SMSService().send(msgData);
          await _pushNotificationService.sendNotification(
              tokenIdList: [msgData.receiverDeviceToken],
              contents: msgData.body,
              heading: msgData.title
          );
          debugPrint('-----successful transmission of message to: ${msgData.receiverName}------');
        }
      }catch (e) {
        debugPrint('-----failed to send the second notification messages------');
      }
    }


    try {
      debugPrint('---sending first notification messages------');
      await firstReminder();
    } catch (e) {
      debugPrint('-----could not send the first notification messages-----');
    }
    ///This delay is extremely important
    ///without this dealy it wourl be impossible to send the notification to more than one client at the same time
    await Future.delayed(Duration(seconds: 5), (){});

    try {
      debugPrint('-----sending second notification messages--------');
      await secondReminder();
    } catch (e) {
      debugPrint('-----could not send the second notification messages-----');
    }




  }

  Future<int> newTimePeriod() async{
    return  await DataAnalysis(timeDataInSeconds: timeData.cast<int>()).trueMeanInSeconds(); //TODO: CHANGE THIS TO MINUTES LATER ON
  }

  void showSnackBar({String text, int duration}) {
    final SnackBar msg = SnackBar(content: Text(
      text,
    ), duration: Duration(seconds: duration));
    ScaffoldMessenger.of(context).showSnackBar(msg);
  }

  List<dynamic> swapItemsInList({List myList, Map item1, Map item2}) {
    for(var item in myList) print(item.toString());
    debugPrint('----search for the following------');
    int item1Index;
    int item2Index;
    debugPrint('$item1');
    debugPrint('$item2');
    List list = myList;
    for(int i =0; i<list.length; i++) {
      if(list[i]['id'] == item1['id'] && list[i]['name'] == item1['name']){
        debugPrint('-----found item1-----');
        item1Index = i;
      }
    }
    for(int i =0; i<list.length; i++) {
      if(list[i]['id'] == item2['id'] && list[i]['name'] == item2['name']){
        debugPrint('---found item2----');
        item2Index = i;
      }
    }
    debugPrint('----new list items----');
    for(var item in list) print(item.toString());

    list[item1Index] = item2;
    list[item2Index] = item1;
    return list;
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

      QuerySnapshot clientDetailsSnapshot =  await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers')
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
          isValidated = clientDoc['is_validated'];
          debugPrint('-----validation state: $isValidated------');
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
          QuerySnapshot clientsForFirstNotificationSnapshot =  await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers')
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
          QuerySnapshot clientsForSecondNotificationSnapshot =  await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers')
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
    return WillPopScope(
      onWillPop: ()async => false,
      child: ChangeNotifierProvider(
          create: (context) => ManagerDetails(),
          builder: (context, child) =>  SafeArea(
              child: ModalProgressHUD(
                  inAsyncCall: isLoadingActions,
                  child: StreamBuilder<DocumentSnapshot>(
                      stream: _db.collection('manager_details').doc(_auth.currentUser.uid).snapshots(),
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
                                  isValidated = false;
                                  isSkipButtonPressed = false;
                                  isCurrentClientRegistered = true;
                                  previousClientCount = 0;
                                  previousFirstClientIndex = 0;
                                  currentClientToken = '';
                                  prevTransitionTime = null;
                                });
                              }

                              ///Here is how the skip function works
                              ///0. If the current client is validated then do this,
                              ///1. If the current client is registered then,
                              ///1.1. If the skip count of this client is less than the max skip count then,
                              ///1.1.1. If there exists an unregistered client : it Swaps the user details of the current client with the first unregistered client.
                              ///1.1.2. else (if there is no unregistered client): Places this client at the last position in the queue
                              ///1.2. if the skip count of this client >= the max skip count then
                              /// 1.2.1 go to the next client in the queue
                              ///2. if the current client is unregistered then,
                              ///2.1 go to the next client in the queue



                              ///This function contains all the operations required to transistion from the current client to the next
                              ///this function can be use inside the next and the skip functions


                              ///this method makes use of the nextOperations callback to transition from the current client to the next
                              Future<void> skip() async {
                                ///Declare useful variables to be used
                                ///these variaables will be intialised from the database
                                String _currentClientName;
                                String _currentClientId;
                                var _currentClientIndex;
                                bool _isClientRegistered;
                                int _skipCount;
                                bool _sendSMSFlag = false;
                                bool _resetVarFlag = false;
                                bool _isValidated = false;
                                bool result = false;
                                bool _refreshFlag = false;

                                startLoading();

                                ///If the current client is validated then abort the skiping process
                                ///Can only skip an unvalidated client
                                if(isValidated) {
                                  stopLoading();
                                  return;
                                }

                                ///If client is not validated, continue the process
                                try {
                                  await _db.runTransaction((transaction) async {
                                    ///Create relevant functions to be used within this transaction
                                    Future<QueryDocumentSnapshot> getClientDoc(var clientIndex) async {
                                      try{
                                        QuerySnapshot doc = await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').where('client_index',isEqualTo: clientIndex).limit(1).get();
                                        String id = doc.docs[0]['client_id'];
                                        return (id == null) ? null : doc.docs[0];
                                      }catch(e) {
                                        debugPrint('$e');
                                        return null;
                                      }
                                    }

                                    ///Gets a list of documents containing all the unregistered clients information
                                    Future<QuerySnapshot> getUnregisteredClientDocs() async {
                                      try {
                                        QuerySnapshot unregisteredClientDocs = await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers')
                                            .where('registered', isEqualTo: false)
                                            .orderBy('timestamp')
                                            .limit(1)
                                            .get();
                                        //checking for available unregistered clients
                                        return (unregisteredClientDocs.docs.isNotEmpty) ? unregisteredClientDocs : null;
                                      } catch (e) {
                                        debugPrint('$e');
                                        return null;
                                      }
                                    }

                                    ///Swaps the details of two clients in the following scenarios
                                    ///Swapping a registered client with an unregistered client
                                    Future<void> swapClientDetails(var unregisteredClientDocs) async{
                                      try {
                                        var firstUnregClientDoc = unregisteredClientDocs.docs[0];

                                        debugPrint('------trying to delete registered client --------');
                                        DocumentReference subsSummaryDoc = _db.collection('manager_details').doc(FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
                                        //get the list of subscribers from the summary document
                                        List oldSubsList = (await transaction.get(subsSummaryDoc))['subscribers'];
                                        debugPrint('----Old docs length: ${oldSubsList.length} ----');

                                        ///swap client details in the subscriber list
                                        List newSubsList = swapItemsInList(myList: oldSubsList, item1: {'name' : currentClientName,'id' : currentClientId }, item2: {'name' : firstUnregClientDoc['name'],'id' : firstUnregClientDoc['client_id']});
                                        transaction.set(subsSummaryDoc, {
                                          'subscribers' : newSubsList,
                                        }, SetOptions(merge: true));


                                        DocumentReference regSubscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(currentClientId);
                                        transaction.set(regSubscriberReference, {
                                          'skip_count' : FieldValue.increment(1),
                                          'timestamp' : firstUnregClientDoc['timestamp'],
                                          'initial_position' : firstUnregClientDoc['initial_position'],
                                          'client_index' : firstUnregClientDoc['client_index'],
                                          'first_notification_index' : -1, //A skipped client can no longer receive sms notifications
                                          'second_notification_index' : -1 //A skipped client can no longer receive sms notifications
                                        }, SetOptions(merge: true));

                                        DocumentReference unRegSubscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(firstUnregClientDoc['client_id']);
                                        transaction.set(unRegSubscriberReference, {
                                          'timestamp' : currentClientTimestamp,
                                          'initial_position' : currentClientInitialPosition,
                                          'client_index' : currentClientIndex,
                                          'first_notification_index' : -1, //A skipped client can no longer receive sms notifications
                                          'second_notification_index' : -1 //A skipped client can no longer receive sms notifications
                                        },SetOptions(merge: true));

                                        result = true;
                                      } catch (e) {
                                        debugPrint("$e");
                                      }
                                    }

                                    ///appends the client to the end of the list
                                    Future<void> setToLastPosition() async{
                                      try {
                                        DocumentReference managerReference = _db.collection('manager_details').doc(_auth.currentUser.uid);
                                        DocumentSnapshot managerDetails = await transaction.get(managerReference);

                                        int _firstClientIndex = managerDetails['first_client_index'];
                                        int _clientCount = managerDetails['client_count'];

                                        var _clientIndex = _firstClientIndex + _clientCount;
                                        var _initialPosition = _clientCount;

                                        //remove client from the subscriber list
                                        DocumentReference subsSummaryDoc = _db.collection('manager_details').doc(FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
                                        transaction.set(subsSummaryDoc, {
                                          'subscribers' : FieldValue.arrayRemove(
                                              [
                                                { 'id': currentClientId,
                                                  'name': currentClientName,
                                                }
                                              ]
                                          )
                                        }, SetOptions(merge: true));

                                        //add client to the subscriber list
                                        transaction.set(subsSummaryDoc, {
                                          'subscribers' : FieldValue.arrayUnion(
                                              [
                                                { 'id': currentClientId,
                                                  'name': currentClientName,
                                                }
                                              ]
                                          )
                                        }, SetOptions(merge: true));

                                        DocumentReference subscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(currentClientId);
                                        transaction.set(subscriberReference, {
                                          'skip_count' : FieldValue.increment(1),
                                          'timestamp' : FieldValue.serverTimestamp(),
                                          'initial_position' : _initialPosition,
                                          'client_index' : _clientIndex,
                                          'first_notification_index' : -1, //the first client index at which the current client is to be firstly notified
                                          'second_notification_index' : -1 //the first client index at which the current client is to be secondly notified.
                                        }, SetOptions(merge: true));

                                        DocumentReference queueReference = _db.collection('manager_details').doc(_auth.currentUser.uid);
                                        transaction.set(queueReference, {
                                          'first_client_index': FieldValue.increment(1),
                                          'prev_transition_time' : FieldValue.serverTimestamp(),
                                        }, SetOptions(merge: true));
                                      } catch (e) {
                                        debugPrint('$e');
                                      }
                                      result = true;
                                    }

                                    ///Defines the actual client transition logic
                                    Future<void> nextOperations(var _currentClientId, _currentClientName) async{
                                      try {
                                        bool success = false;
                                        int _clientCount;
                                        int _firstClientIndex;

                                        DocumentReference subscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(_currentClientId);

                                        DocumentReference queueReference = _db.collection('manager_details').doc(_auth.currentUser.uid);
                                        var queueDoc = await transaction.get(queueReference);
                                        _clientCount = queueDoc['client_count'];
                                        _firstClientIndex = queueDoc['first_client_index'];

                                        DocumentReference docRef = _db.collection('client_details').doc(_currentClientId).collection('my_queues').doc(_auth.currentUser.uid);
                                        transaction.delete(docRef);

                                        transaction.delete(subscriberReference);

                                        DocumentReference clientQueueDoc = _db.collection('client_details').doc(_currentClientId);
                                        transaction.set(clientQueueDoc, {
                                          'my_queues' : FieldValue.arrayRemove([{
                                            'id' : _auth.currentUser.uid,
                                            'name' : managerName,
                                          }])
                                        }, SetOptions(merge: true));

                                        DocumentReference subsSummaryDoc = _db.collection('manager_details').doc(FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
                                        transaction.set(subsSummaryDoc, {
                                          'subscribers' : FieldValue.arrayRemove(
                                              [
                                                { 'id': _currentClientId,
                                                  'name': _currentClientName,
                                                }
                                              ]
                                          )
                                        }, SetOptions(merge: true));


                                        ///make sure the number of time samples in the time data field is less than the threshold(10)
                                        if(currentSampleCount >= 10){
                                          int _newTimePeriod = await newTimePeriod();
                                          transaction.set(queueReference, {
                                            'client_count': FieldValue.increment(-1),
                                            'first_client_index': FieldValue.increment(1),
                                            'prev_transition_time': FieldValue.serverTimestamp(),
                                            'time_data' : [],
                                            'time_period' : _newTimePeriod
                                          },
                                              SetOptions(merge: true));
                                        }else {
                                          transaction.set(queueReference, {
                                            'client_count': FieldValue.increment(-1),
                                            'first_client_index': FieldValue.increment(1),
                                            'prev_transition_time': FieldValue.serverTimestamp(),
                                          }, SetOptions(merge: true));
                                        }
                                        result = true;
                                        print('------successful transition to the next client-----');
                                      } catch (e) {
                                        debugPrint('$e');
                                      }
                                    }

                                    ///Declaring and initializing the manager references to be used
                                    DocumentReference managerRef = _db.collection('manager_details').doc(_auth.currentUser.uid);


                                    ///get the manager doc
                                    var managerDoc = await transaction.get(managerRef);

                                    ///Get the first client index
                                    var _firstClientIndex = managerDoc['first_client_index'];

                                    ///Get the latest time Period and prev transition index
                                    ///Enclose inside a try and catch blokc because the 'prev_transition_time' field might not yet exist
                                    timePeriod = managerDoc['time_period'];
                                    try {
                                      prevTransitionTime = managerDoc['prev_transition_time'];
                                    }catch(e) {
                                      debugPrint('----\'prev_transition_time\' field doesn\'t yet exist');
                                    }


                                    ///Get the first client's docs
                                    var firstClientDoc = await getClientDoc(_firstClientIndex);

                                    ///Get the client's validation state
                                    var validationState;
                                    try {
                                      validationState = firstClientDoc['is_validated'];
                                    }catch(e) {
                                      debugPrint('$e');
                                      validationState = false;
                                    }

                                    ///Verify that truly the current client is not yet validated (verfication from firebase)
                                    if(validationState == true && firstClientDoc['client_id'] == currentClientId) {
                                      stopLoading();
                                      return;
                                    }

                                    ///Intializing the variables
                                    _currentClientId = firstClientDoc['client_id'];
                                    _currentClientName = firstClientDoc['name'];
                                    _currentClientIndex = firstClientDoc['client_index'];
                                    _isClientRegistered = firstClientDoc['registered'];
                                    _skipCount = firstClientDoc['skip_count'];


                                    ///check if this client is registered
                                    if(_isClientRegistered) {

                                      ///ensure skip count is less than the max skip count
                                      if(_skipCount < maxSkipCount) {
                                        ///try to get the list of unregistered clients
                                        var unregisteredClientDocs = await getUnregisteredClientDocs();

                                        ///if there exist unregistered clients, swap the current client with the first unregistred client
                                        ///else if there exist no unregistered clients, just add the current client to the tail of the queue
                                        if(unregisteredClientDocs != null) {
                                          await swapClientDetails(unregisteredClientDocs);
                                          _refreshFlag = true;
                                          _resetVarFlag = true;
                                        } else{
                                          ///make sure the client delay period is exhausted
                                          if(clientDelayPeriodIsExhausted() == true) {
                                            await setToLastPosition();
                                            _resetVarFlag = true;
                                          }


                                        }
                                      }
                                      ///do this if the client skip count is greater than or equal to the maximiun skip count
                                      else {
                                        ///check if the client delay period is exhausted
                                        if(clientDelayPeriodIsExhausted() == true) {
                                          ///Transition to the next client
                                          await nextOperations(_currentClientId, _currentClientName);
                                          ///notify the clients
                                          _sendSMSFlag = true;
                                          _isValidated = false;
                                          _resetVarFlag = true;
                                        }


                                      }
                                    }
                                    ///do this if the current client is not registered ( for unregistered clients)
                                    else {
                                      ///Transition to the next client
                                      await nextOperations(_currentClientId, _currentClientName);
                                      ///notify the clients
                                      _sendSMSFlag = true;
                                      _isValidated = false;
                                      _resetVarFlag = true;
                                    }

                                  },
                                      timeout: Duration(seconds: 10));
                                } catch (e) {
                                  debugPrint('$e');
                                }


                                ///execute the following blocks of the code depending on the state of the flag variables
                                if(_isValidated != null) {
                                  setState(() {
                                    isValidated = _isValidated;
                                  });
                                }

                                ///if the result is true, show snackbard msg
                                if(!result) {
                                  final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).skipClientFailureMsg), duration: Duration(seconds: 1));
                                  ScaffoldMessenger.of(context).showSnackBar(msg);
                                }else {
                                  final SnackBar msg = SnackBar(content: Text('Success'), duration: Duration(seconds: 1));
                                  ScaffoldMessenger.of(context).showSnackBar(msg);
                                }

                                ///send sms reminders asynchronously
                                if(_sendSMSFlag) sendSMSReminders(firstMessages: firstMessages, secondMessages: secondMessages);

                                ///reset all the variables
                                if(_resetVarFlag) resetVariables();

                                ///refresh this screen
                                ///get updated queue info from firebase
                                refresh();
                                stopLoading();
                              }

                              Future<void> next() async {
                                var _currentClientId;
                                var _currentClientName;
                                var _currentClientIndex;
                                var _isClientRegistered;
                                var _skipCount;
                                bool _sendSMSFlag = false;
                                bool _resetVarFlag = false;
                                bool _isValidated =false;
                                bool result = false;

                                Future<QueryDocumentSnapshot> getClientDoc(String clientIndex) async {
                                  try{
                                    QuerySnapshot doc = await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').where('client_index',isEqualTo: clientIndex).limit(1).get();
                                    String id = doc.docs[0]['client_id'];
                                    return (id == null) ? null : doc.docs[0];
                                  }catch(e) {
                                    debugPrint('$e');
                                    return null;
                                  }
                                }

                                if (isValidated) {
                                  print('---next was pressed-----');

                                  try {
                                    await _db.runTransaction((transaction) async{

                                      ///Creating the relevant functions to be used within this transaction
                                      Future<QueryDocumentSnapshot> getClientDoc(var clientIndex) async {
                                        try{
                                          QuerySnapshot doc = await _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').where('client_index',isEqualTo: clientIndex).limit(1).get();
                                          String id = doc.docs[0]['client_id'];
                                          return (id == null) ? null : doc.docs[0];
                                        }catch(e) {
                                          debugPrint('$e');
                                          return null;
                                        }
                                      }

                                      ///Defines the actual client transition logic
                                      Future<void> nextOperations(var _currentClientId, _currentClientName) async{
                                        bool success = false;
                                        int _clientCount;
                                        int _firstClientIndex;

                                        DocumentReference subscriberReference = _db.collection('manager_details').doc(_auth.currentUser.uid).collection('subscribers').doc(_currentClientId);

                                        DocumentReference queueReference = _db.collection('manager_details').doc(_auth.currentUser.uid);
                                        var queueDoc = await transaction.get(queueReference);
                                        _clientCount = queueDoc['client_count'];
                                        _firstClientIndex = queueDoc['first_client_index'];

                                        DocumentReference docRef = _db.collection('client_details').doc(_currentClientId).collection('my_queues').doc(_auth.currentUser.uid);
                                        transaction.delete(docRef);

                                        transaction.delete(subscriberReference);

                                        DocumentReference clientQueueDoc = _db.collection('client_details').doc(_currentClientId);
                                        transaction.set(clientQueueDoc, {
                                          'my_queues' : FieldValue.arrayRemove([{
                                            'id' : _auth.currentUser.uid,
                                            'name' : managerName,
                                          }])
                                        }, SetOptions(merge: true));

                                        DocumentReference subsSummaryDoc = _db.collection('manager_details').doc(FirebaseAuth.instance.currentUser.uid).collection('subscribers').doc('summary');
                                        transaction.set(subsSummaryDoc, {
                                          'subscribers' : FieldValue.arrayRemove(
                                              [
                                                { 'id': _currentClientId,
                                                  'name': _currentClientName,
                                                }
                                              ]
                                          )
                                        }, SetOptions(merge: true));

                                        if(currentSampleCount >= 10){//todo: change the threshold time to 10 minutes
                                          int _newTimePeriod = await newTimePeriod();
                                          transaction.set(queueReference, {
                                            'client_count': FieldValue.increment(-1),
                                            'first_client_index': FieldValue.increment(1),
                                            'prev_transition_time': FieldValue.serverTimestamp(),
                                            'time_data' : [],
                                            'time_period' : _newTimePeriod
                                          }, SetOptions(merge: true));
                                        }else {
                                          transaction.set(queueReference, {
                                            'client_count': FieldValue.increment(-1),
                                            'first_client_index': FieldValue.increment(1),
                                            'prev_transition_time': FieldValue.serverTimestamp(),
                                          }, SetOptions(merge: true));
                                        }
                                        result = true;
                                        debugPrint('------successful transition to the next client-----');
                                      }

                                      ///Declaring and initializing the manager references to be used
                                      DocumentReference managerRef = _db.collection('manager_details').doc(_auth.currentUser.uid);

                                      ///Get the first client index
                                      var _firstClientIndex = (await transaction.get(managerRef))['first_client_index'];

                                      ///Get the first client's docs
                                      var firstClientDoc = await getClientDoc(_firstClientIndex);

                                      ///Get the client validation state
                                      var validationState;
                                      try {
                                        validationState = firstClientDoc['is_validated'];
                                      }catch(e) {
                                        debugPrint('$e');
                                        validationState = false;
                                      }


                                      ///Verify that truly the current client is not yet validated (verfication from firebase)
                                      ///Verify that the client displayed on the dashboard is the true first client before proceeding to the next client
                                      if(validationState == false && firstClientDoc['client_id'] == currentClientId) {
                                        stopLoading();
                                        return;
                                      }

                                      ///Initializing the variables
                                      _currentClientId = firstClientDoc['client_id'];
                                      _currentClientName = firstClientDoc['name'];
                                      _currentClientIndex = firstClientDoc['client_index'];
                                      _isClientRegistered = firstClientDoc['registered'];
                                      _skipCount = firstClientDoc['skip_count'];


                                      ///Transition to the next client
                                      await nextOperations(_currentClientId, _currentClientName);
                                      print('------successful transition to the next client-----');

                                      /// set the flag variables when if the transaction successfully comes to an end
                                      _isValidated = false;
                                      _sendSMSFlag = true;
                                      _resetVarFlag = true;

                                    },
                                        timeout: Duration(seconds: 5));
                                  } catch (e) {
                                    debugPrint('$e');
                                    final SnackBar msg = SnackBar(content: Text('$e'), duration: Duration(seconds: 10));
                                    ScaffoldMessenger.of(context).showSnackBar(msg);
                                  }
                                }

                                ///execute the following blocks of the code depending on the state of the flag variables
                                if(_isValidated != null) {
                                  setState(() {
                                    isValidated = _isValidated;
                                  });
                                }

                                ///Display msg based on success of failure
                                if(!result) {
                                  final SnackBar msg = SnackBar(content: Text('failed'), duration: Duration(seconds: 1));
                                  ScaffoldMessenger.of(context).showSnackBar(msg);
                                }else {
                                  final SnackBar msg = SnackBar(content: Text('Success'), duration: Duration(seconds: 1));
                                  ScaffoldMessenger.of(context).showSnackBar(msg);
                                }

                                ///sends sms reminders asynchronously
                                if(_sendSMSFlag) sendSMSReminders(firstMessages: firstMessages, secondMessages: secondMessages);

                                ///reset he variable
                                if(_resetVarFlag) resetVariables();

                                ///refresh
                                refresh();

                                stopLoading();
                              }

                              Future<void> pauseQueueCallback(int pauseDuration) async{
                                ///Pause queue only if the queue is currently open
                                if(isOpen == false) return;
                                startLoading();
                                bool _newQueueState = isOpen;
                                try {
                                  debugPrint('----Changing the queueState------');
                                  await _db.runTransaction((transaction) async{
                                    ///get the current queue state from firebase
                                    DocumentReference manRef = _db.collection('manager_details').doc(_auth.currentUser.uid);
                                    bool _queueState = (await transaction.get(manRef))['open'];
                                    debugPrint('-----OldQueueState: ${(_queueState ? 'open' : 'closed')}');

                                    ///if the current queue state is true, set it false
                                    if(_queueState == true) {
                                      transaction.set(manRef, {
                                        'open': false,
                                        'pause_time' : FieldValue.serverTimestamp(),
                                        'pause_duration' : pauseDuration,
                                      },
                                          SetOptions(merge: true));

                                      _newQueueState = !_queueState;
                                      debugPrint('----NewQuueState: $_newQueueState');
                                    }

                                  },
                                      timeout: Duration(seconds: 10));
                                }catch(e) {
                                  ///On failure to pause the queue
                                  await Dialogs(context: context).customDialog(text: 'Something went wrong');
                                  stopLoading();
                                  return;
                                }
                                setState((){
                                  isOpen = _newQueueState;
                                });
                                stopLoading();
                              }

                              Future<void> resumeQueueCallback() async {
                                ///Resume queue only if the queue is currently closed
                                if(isOpen == true) return;

                                startLoading();
                                bool _newQueueState = isOpen;
                                try {
                                  debugPrint('----Changing the queueState------');
                                  await _db.runTransaction((transaction) async{
                                    ///get the current queue state from firebase
                                    DocumentReference manRef = _db.collection('manager_details').doc(_auth.currentUser.uid);
                                    bool _queueState = (await transaction.get(manRef))['open'];
                                    debugPrint('-----OldQueueState: ${(_queueState ? 'open' : 'closed')}');

                                    ///if the current queue state is true, set it false
                                    if(_queueState == false) {
                                      transaction.set(manRef, {
                                        'open': true
                                      },
                                          SetOptions(merge: true));

                                      _newQueueState = !_queueState;
                                      debugPrint('----NewQuueState: $_newQueueState');
                                    }

                                  });
                                }catch(e) {
                                  ///On failure to pause the queue
                                  await Dialogs(context: context).customDialog(text: 'Something went wrong');
                                  stopLoading();
                                  return;
                                }
                                setState((){
                                  isOpen = _newQueueState;
                                });
                                stopLoading();
                              }

                              Widget skipAlertDialog() {
                                return AlertDialog(
                                    title: Center(child: Text('${AppLocalizations.of(context).warning} !', style: TextStyle(color: Colors.red))),
                                    content: Container(
                                        height: 50,
                                        child: Center(child: Text(AppLocalizations.of(context).skipClientWarning))),
                                    actions: [
                                      TextButton(child: Text(AppLocalizations.of(context).yes,
                                          style: TextStyle(color: Colors.blue)),
                                        onPressed: () {
                                          setState(() {
                                            isSkipButtonPressed = false;
                                          });
                                          skip();
                                          Navigator.pop(context);
                                        },),
                                      TextButton(child: Text(AppLocalizations.of(context).no, style: TextStyle(color: Colors.blue)),
                                        onPressed: () {
                                          setState(() {
                                            isSkipButtonPressed = false;
                                          });
                                          Navigator.pop(context);
                                        },),
                                    ]
                                );
                              }

                              Future<void> validateRegClient() async {
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
                                      var managerDocRef = _db.collection('manager_details').doc(_auth.currentUser.uid);
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
                                          debugPrint('----setting previous validation time-----');
                                        }
                                      } else {
                                        debugPrint('---the manager you are looking for does not exist-----');
                                      }
                                    });
                                    setState(() {
                                      isValidated = true;
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
                                bool result = await validateUnregisteredClient(currentClientToken, context);
                                try {
                                  if (result != null && result == true) {
                                    await _db.runTransaction((transaction) async {
                                      ///set references for the manager and the client
                                      var managerDocRef = _db.collection('manager_details').doc(_auth.currentUser.uid);
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
                                      isValidated = true;
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
                                                  vCard(onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => MyClientsScreen()));} ,child: Center(child: SingleChildScrollView(
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
                                                  vCard(onTap: () async {if (!isValidated && clientCount != 0) {
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
                                                      child: isValidated ? Icon(Icons.check,
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
                                                  widget.canSkipClient ? Center(
                                                    child: ElevatedButton(
                                                        style: ButtonStyle(
                                                          backgroundColor: MaterialStateProperty
                                                              .all(Colors.red),
                                                          elevation: MaterialStateProperty.all(5),
                                                        ),
                                                        onPressed: () async{
                                                          startLoading();
                                                          ///make sure app is up to date
                                                          if(await Dialogs(context: context).checkUpdatesDialog() == false) {
                                                            stopLoading();
                                                            return;}

                                                          ///Cannot skip a validated client
                                                          if(isValidated == true) {
                                                            stopLoading();
                                                            return;}

                                                          if (clientCount != 0) {
                                                            showDialog(context: context,
                                                                builder: (context) {
                                                                  return skipAlertDialog();
                                                                });
                                                          }
                                                          stopLoading();
                                                        },

                                                        child: AutoSizeText(
                                                            AppLocalizations.of(context).skip,
                                                            maxLines: 1,
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                            )
                                                        )),
                                                  ) : Container(child: null),
                                                  widget.canValidateClient ? Center(
                                                    child: ElevatedButton(
                                                        style: ButtonStyle(
                                                          backgroundColor: MaterialStateProperty
                                                              .all(Colors.green),
                                                          elevation: MaterialStateProperty.all(5),
                                                        ),
                                                        onPressed: () async {
                                                          startLoading();
                                                          try {
                                                            if (!isValidated && clientCount != 0) {
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
                                                  widget.canProceedToNextClient ? Center(
                                                    child: ElevatedButton(
                                                        style: ButtonStyle(
                                                          backgroundColor: MaterialStateProperty
                                                              .all(Colors.blue),
                                                          elevation: MaterialStateProperty.all(5),
                                                        ),
                                                        onPressed: () async {
                                                          startLoading();

                                                          ///make sure app is up to date
                                                          if(await Dialogs(context: context).checkUpdatesDialog() == false) {
                                                            stopLoading();
                                                            return;}

                                                          ///Make sure the client count isn't equal to zero, the client is validated and the current client is registered
                                                          if (clientCount != 0 && isValidated && isCurrentClientRegistered) {
                                                            bool result = await Dialogs(context: context).confirmationDialog(
                                                                text: 'Would you like to push this Client to another queue ?'); //todo: translate
                                                            if(result == null) {
                                                              stopLoading();
                                                              return;}

                                                            ///if the confirmation result is true, push the client to the next queue, then proceed as usual to the next client
                                                            if(result) {
                                                              bool wasPushSuccessful = await Navigator.push(context, MaterialPageRoute(builder: (context) => MyRoutes(
                                                                title: 'Select a route', //todo: translation
                                                                addClient: true,
                                                                isClientRegistered: isCurrentClientRegistered,
                                                                regClientId: currentClientId ?? '',
                                                                regClientPhone: currentClientPhoneNumber ?? '',
                                                                regClientLang: currentClientLanguage ?? '',
                                                                unRegClientName: !isCurrentClientRegistered ? currentClientName : null,
                                                              )));

                                                              //todo: Might need to check the value of the wasPushSuccessful var before deciding whether or not to make the transition to the next client
                                                              try {
                                                                await next().timeout(Duration(seconds: 5));
                                                              } on TimeoutException catch (e) {
                                                                debugPrint('------Next Method has timed out------');
                                                              }
                                                            }

                                                            ///if confirmation result is false, proceed as usual to the next client
                                                            else {
                                                              await next();
                                                            }

                                                          }else if (clientCount != 0 && isValidated && !isCurrentClientRegistered) {
                                                            await next();
                                                          }

                                                          stopLoading();
                                                        },
                                                        child: AutoSizeText(
                                                            AppLocalizations.of(context).next,
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
                                          var firstRecentToken = await AddUnregClient().addUnregClient(context, startLoading, stopLoading);
                                          if (firstRecentToken != null) {
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
                                  body: Stack(
                                      children: [
                                        activeScreen(),
                                        /// Show the paused queue screen if the queue is not open
                                        (isOpen == true) ? Container() : PausedQueueScreen(toggleQueueStateCallback: resumeQueueCallback),
                                      ]
                                  ),//Container(child: Text('hello'))//
                                ),
                              );
                            }
                        );
                      }
                  )
              )
          )
      ),
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





