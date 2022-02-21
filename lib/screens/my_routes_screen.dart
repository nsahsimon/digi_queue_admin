import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'add_unregistered_client_screen.dart';
import 'package:no_queues_manager/my_widgets/dialogs.dart';
import 'package:no_queues_manager/my_widgets/my_tile.dart';


class MyRoutes extends StatefulWidget {

  final String title;
  final bool addClient;
  final bool isClientRegistered; // variable is used only if addClient is set to true
  final String regClientId;//this variable is used only if the isClientRegistered is set to true
  final String regClientPhone; //this variable is use only if the isClientRegistered is set to true
  final String regClientLang;
  final String unRegClientName;
  MyRoutes({this.title = "My Routes", this.addClient = false, this.isClientRegistered =false,this.regClientId = '',this.unRegClientName = '', this.regClientPhone = '', this.regClientLang = 'en'});

  @override
  _MyRoutesState createState() => _MyRoutesState();
}

class _MyRoutesState extends State<MyRoutes> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> routeDocs;
  List routes= [];
  List routeIds = [];
  bool isLoading = false;
  int initialPosition = 0;


  @override
  void initState() {
    super.initState();
    Future(() async{
      await getRoutes();
    });
  }

  void startLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void stopLoading (){
    setState(() {
      isLoading = false;
    });
  }

  ///Function to pass clients from one queue to the next
  Future<void> addClientToRoute({String routeId, String routeName}) async{

    ///callback to add a registered client
    Future<void> addRegisteredClientToRoute() async{
      ///this function checks if the current client is already a member of the queue relevant route
      Future<bool> alreadyJoinedThisQueue() async{
        startLoading();
        if (await Dialogs(context: context).checkConnectionDialog()) {
          print('----there is internet connection----');

          QuerySnapshot  doc =  await db.collection('manager_details').doc(routeId).collection('subscribers').where('client_id', isEqualTo: widget.regClientId).get();

          try {
            if(doc.docs.isNotEmpty) {
              print('-----you\'ve already joined this queue ---');
              final SnackBar msg = SnackBar(content: Text('Already joined this queue'), duration: Duration(seconds: 1));
              ScaffoldMessenger.of(context).showSnackBar(msg);
            }
            stopLoading();
            return doc.docs.isNotEmpty;
          } catch(e) {
            return false;
          }
        }else {
          print('-----there is no internet connection------');
          stopLoading();
          return true;
        }

      }

      ///this function adds the registered Client's details to the database
      Future<void> joinQueue() async{
        debugPrint('-----my id ${widget.regClientId}-----');
        int clientIndex;

        //add this client to the list of clients subscribed to this queue;
        startLoading();
        try {
          await db.runTransaction((transaction) async{

            DocumentReference clientReference = FirebaseFirestore.instance.collection('client_details').doc('${widget.regClientId}');
            DocumentSnapshot clientDetails = await transaction.get(clientReference);
            String firebaseNotificationToken = '';
            String clientName = clientDetails['name'];

            DocumentReference managerReference = db.collection('manager_details').doc(routeId);
            DocumentSnapshot managerDetails = await transaction.get(managerReference);

            int firstClientIndex = managerDetails['first_client_index'];
            int clientCount = managerDetails['client_count'];

            /// if this client is the first subscriber of this service,
            clientIndex = firstClientIndex + clientCount;
            initialPosition = clientCount + 1;

            DocumentReference subsSummaryDoc = db.collection('manager_details').doc(routeId).collection('subscribers').doc('summary');
            transaction.set(subsSummaryDoc, {
              'subscribers' : FieldValue.arrayUnion(
                  [
                    { 'id': widget.regClientId,
                      'name': clientName,
                    }
                  ]
              )
            },
                SetOptions(merge: true));

            DocumentReference subscriberReference = db.collection('manager_details').doc(routeId).collection('subscribers').doc(widget.regClientId);
            transaction.set(subscriberReference, {
              'skip_count' : 0,
              'client_id' : widget.regClientId,
              'lang' : widget.regClientLang, //forget maintain the client's language
              'timestamp' : FieldValue.serverTimestamp(),
              'initial_position' : initialPosition,
              'client_index' : clientIndex,
              'registered' : true,
              'name': clientName,
              'phone': widget.regClientPhone,
              'firebaseDeviceToken' : firebaseNotificationToken,
              'first_notification_index' : -1, //client won't receive any notification
              'second_notification_index' : -1 //client won't receive any notification
            },);

            transaction.set(clientReference, {
              'paid_for' : [], ///once a client joins a queue, his payment status is reset
              'my_queues' : FieldValue.arrayUnion([{
                'id' : routeId,
                'name' : routeName
              }]) },
              SetOptions(merge: true),);

            managerReference = db.collection('manager_details').doc(routeId);
            transaction.update(managerReference, {
              'client_count': FieldValue.increment(1),
            });

          },
            timeout: Duration(seconds: 10),
          );

          stopLoading();
          //TODO: Display a dialog box when client successfully joins the queue.
        } catch(e) {
          stopLoading();
          debugPrint('--------failed to join queue---------');
          debugPrint('$e');
          await Dialogs(context: context).failureDialog();
          Navigator.pop(context);
          return;
        }
        stopLoading();
        debugPrint('-------successfully joined Queue--------');
        await Dialogs(context: context).success();
        Navigator.pop(context);
      }
      debugPrint('----joining the queue---');

      if(!(await alreadyJoinedThisQueue())) {
        debugPrint('----This client hasn\'t yet joined the queue----');
        startLoading();
        await joinQueue();
        stopLoading();
      }
    }

    ///callback to add an unregistered client
    Future<void> addUnregisteredClientToRoute() async {
      //todo:completely  Delete unregistered client information form the previous queue before pushing the client to the next queue
      await AddUnregClient(managerId: routeId,inputClientName: widget.unRegClientName).addUnregClient(context, startLoading, stopLoading);
      return;
    }

    startLoading();
    if(await Dialogs(context: context).checkUpdatesDialog() == false) {
      stopLoading();
      return;}
    (widget.isClientRegistered) ? await addRegisteredClientToRoute() : await addUnregisteredClientToRoute() ;
    stopLoading();

  }

  ///Get the list of all routes
  Future<void> getRoutes() async {
    try {
      var managerDoc = await db.collection('manager_details').doc(auth.currentUser.uid).get();
      if(managerDoc.exists) {
        setState((){
          routes = managerDoc['exit_routes']; // this is a map containing terminal ids and their corresponding terminal names.
        });
      }else {
        setState(() {
          routes =[];
        });
      }
    }catch(e) {
      print(e);
      setState(() {
        routes = [];
      });
    }

  }

  Future<String> getRouteCodeDialog() async{
    String name;
    await showDialog(
        context: context,
        builder: (context) {
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
                                  hintText: 'Enter service code' //todo: translate this line
                              ) ,

                            ),
                            FlatButton(
                              color: appColor,
                              child: Text(
                                  'Add route', //todo: translate
                                  style: TextStyle(
                                    color: Colors.white,
                                  )
                              ),
                              onPressed: () async{
                                if(name.trim() != null) {
                                  Navigator.pop(context);
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
    return name.trim();
  }

  Future<void> addRoute() async{
    String routeCode = await getRouteCodeDialog();  
    String newRouteId ;
    String newRouteName ;
    List existingRouteIds = [];
    Map existingRouteNames = {};
    startLoading();
    try {
      var routeDocs = await db.collection('manager_details').where('service_code', isEqualTo: routeCode).get(); //todo: search using another criteria using the service code is not secure
      if(routeDocs.docs.isNotEmpty) {
        newRouteId = routeDocs.docs[0]['id'];
        if(newRouteId == auth.currentUser.uid) {
          await Dialogs(context: context).failureDialog();
          return;
        }
        newRouteName = routeDocs.docs[0]['name'];
        await db.runTransaction((transaction) async {

          ///getting manager details(name and id)
          var managerDocRef = db.collection('manager_details').doc(auth.currentUser.uid);
          var managerDoc = await transaction.get(managerDocRef);
          String managerName = managerDoc['name'];

          ///add the route to the manager document
          transaction.set(managerDocRef, {
            'entry_routes' : FieldValue.arrayUnion([{
              'id' : newRouteId,
              'name' : newRouteName
            }])
          },
              SetOptions(merge: true));


          ///adding the route to the route's document
          var terminalDocRef = db.collection('manager_details').doc('$newRouteId');
          transaction.set(terminalDocRef, {
            'exit_routes' : FieldValue.arrayUnion([{
              'name' : managerName,
              'id' : auth.currentUser.uid
            }])
          },
              SetOptions(merge: true));
        });

        print('-----successfully added the route------');
        final SnackBar msg = SnackBar(content: Text('Route successfully added'), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);
        await getRoutes();
      }
      
    }catch(e) {
      stopLoading();
      print(e);
      return;
    }
    stopLoading();
  }

  Future<void> deleteRoute({String routeId, String routeName}) async{
    List existingRouteIds = [];
    Map existingRouteNames = {};
    startLoading();
    try {
      await db.runTransaction((transaction) async {
        ///getting manager details
        var managerDocRef = db.collection('manager_details').doc(auth.currentUser.uid);
        var managerDoc = await transaction.get(managerDocRef);
        String managerName = managerDoc['name'];

        ///deleting the route at the level of the manager document
        transaction.set(managerDocRef, {
          'exit_routes' : FieldValue.arrayRemove([{
            'id' : routeId,
            'name' : routeName
          }])
        },
            SetOptions(merge: true));

        ///deleting the route at the level of the routes documents
        var routeDocRef = db.collection('manager_details').doc('$routeId');
        transaction.set(routeDocRef, {
          'entry_routes' : FieldValue.arrayRemove([{
            'name' : managerName,
            'id' : auth.currentUser.uid
          }])
        },
            SetOptions(merge: true));
      });

      debugPrint('-----successfully deleted the routes------');
      await getRoutes();

    }catch(e) {
      stopLoading();
      debugPrint('$e');
      return;
    }
    stopLoading();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: appColor,
            title: Text('${widget.title} (${routes.length})'), //todo: translate
            actions: [
              IconButton(icon: Icon(Icons.refresh, color: Colors.white),
                  tooltip: AppLocalizations.of(context).refresh ,
                  onPressed: getRoutes
              ),
              IconButton(icon: Icon(Icons.add, color: Colors.white),
                  tooltip: 'add a route', //todo: translate
                  onPressed: addRoute
              )
            ],
          ),
          body: (routes.length == 0) ?
          Center(child: Container(child: Text('No routes found', //todo: translation
              style: TextStyle(
                color: Colors.black,
              ))))
              :
          ListView.builder(
              itemCount: routes.length,
              itemBuilder: (context, index) {
                String routeId = routes[index]['id'];
                String routeName = routes[index]['name'];
                String routeCode = routes[index]['service_code'] ?? 'n/a' ;
                return MyTile(
                    title: routeName,
                    onTapCallback: () async{
                      ///add client to this route's queue
                      if(widget.addClient) await addClientToRoute(routeId: routeId, routeName: routeName);
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete,
                          color: Colors.blue),
                      onPressed: () async{
                        ///delete this route from this managers's route list
                        if(!widget.addClient) await deleteRoute(routeId: routeId, routeName: routeName);
                      },
                    )
                );
              }
          )
      ),
    );
  }
}





