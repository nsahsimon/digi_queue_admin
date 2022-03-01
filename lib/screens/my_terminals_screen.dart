import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:no_queues_manager/my_widgets/my_tile.dart';

class MyTerminalsScreen extends StatefulWidget {

  @override
  _MyTerminalsScreenState createState() => _MyTerminalsScreenState();
}


class _MyTerminalsScreenState extends State<MyTerminalsScreen> {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  QuerySnapshot skippedClients;
  List<QueryDocumentSnapshot> terminalDocs;
  List terminals= [];
  List<String> skippedClientNumbers = [];
  List terminalIds = [];
  bool isLoading = false;

  ///some useful permissions that may be granted when creating the terminal
  bool addClientPermission = true;
  bool validateClientPermission = false;
  bool skipClientPermission = false;
  bool nextPermission = false;


  @override
  void initState() {
    super.initState();
    Future(() async{
      await getTerminals();
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

  Future<void> getTerminals() async {
    try {
      var managerDoc = await db.collection('manager_details').doc(auth.currentUser.uid).get();
      if(managerDoc.exists) {
        setState((){
          terminals = managerDoc['terminals']; // this is a map containing terminal ids and their corresponding terminal names.
        });
      }else {
        setState(() {
          terminals =[];
        });
      }
    }catch(e) {
      print(e);
      setState(() {
       terminals = [];
      });
    }

  }

  Future<String> getTerminalCodeDialog() async{
    String name;
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: Container(
                  height: 300,
                  color: Colors.white,
                  child: SingleChildScrollView(
                      child: Column(
                          children: [
                            TextField(
                              onChanged: (newText) {
                                name = newText;
                              },
                              decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context).enterTerminalCode
                              ) ,

                            ),
                            SizedBox(height: 10),
                            selectTerminalPermissions(),
                            FlatButton(
                              color: appColor,
                              child: Text(
                                  AppLocalizations.of(context).addTerminal,
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
    return name != null ? name.trim() : null;
  }

  ///this widget allows the queue administrator to select the terminal's permissions, such as validation , skip ,next and add permissions
  Widget selectTerminalPermissions() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: 200,
            color: Colors.white,
            child: Column(
                children: [
                  AutoSizeText('Select Permissions', maxLines: 1, style: TextStyle(fontWeight: FontWeight.bold)), //todo: translate
                  Expanded(
                    child: ListTile(
                        title: AutoSizeText('Can Add Client', maxLines: 1), //todo: translate
                        trailing: Checkbox(
                            value: addClientPermission,
                            onChanged: (bool newValue) {
                              setState((){
                                addClientPermission = newValue;
                              });
                            }
                        )
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                        title: Text('Can validate Client', maxLines: 1), //todo: translate
                        trailing: Checkbox(
                            value: validateClientPermission,
                            onChanged: (bool newValue) {
                              setState((){
                                validateClientPermission = newValue;
                              });
                            }
                        )
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                        title: Text('Can Skip Client', maxLines: 1), //todo: translate
                        trailing: Checkbox(
                            value: skipClientPermission,
                            onChanged: (bool newValue) {
                              setState((){
                                skipClientPermission = newValue;
                              });
                            }
                        )
                    ),
                  ),
                ]
            )
        );
      }
    );
  }


  Future<void> addTerminal() async{
    String terminalCode = await getTerminalCodeDialog();
    if(terminalCode == null) {
      debugPrint('Terminal code field cannot be empty');
      return;
    }else if (terminalCode.trim() == ''){
      debugPrint('Terminal code field cannot be empty');
      return;
    }else if( (addClientPermission == true) || (validateClientPermission == true)) {

    }else {
      return;
    }
    String newTerminalId ;
    String newTerminalName ;
    List existingTerminalIds = [];
    Map existingTerminalNames = {};
    startLoading();
    try {
      var terminalDocs = await db.collection('terminal_details').where('terminal_code', isEqualTo: terminalCode).get();
      if(terminalDocs.docs.isNotEmpty) {
        newTerminalId = terminalDocs.docs[0]['id'];
        newTerminalName = terminalDocs.docs[0]['name'];
        await db.runTransaction((transaction) async {
          //getting manager details
          var managerDocRef = db.collection('manager_details').doc(auth.currentUser.uid);
          var managerDoc = await transaction.get(managerDocRef);
          String managerName = managerDoc['name'];

          //adding the terminal at the level of the manager document
          transaction.set(managerDocRef, {
            'terminals' : FieldValue.arrayUnion([{
              'terminal_id' : newTerminalId,
              'terminal_name' : newTerminalName
            }])
          },
              SetOptions(merge: true));

          //getting manager details

          //adding the terminal at the level of the terminal's document
          var terminalDocRef = db.collection('terminal_details').doc('$newTerminalId');
          transaction.set(terminalDocRef, {
            ///'services' is a list containing the details of all the services for which the current user is a terminal
            ///Each service in the list contains a map which carrying info about the various properties of the
            'services' : FieldValue.arrayUnion([{
              'service_name' : managerName,
              'service_id' : auth.currentUser.uid,
              'add_client_permission' : addClientPermission,
              'validate_client_permission': validateClientPermission
            }])
          },
              SetOptions(merge: true));
        });

        debugPrint('-----successfully added the terminal------');
        await getTerminals();
      }


    }catch(e) {
      stopLoading();
      debugPrint('$e');
      return;
    }
    stopLoading();
  }

  Future<void> deleteTerminal(terminalId, terminalName) async{
    List existingTerminalIds = [];
    Map existingTerminalNames = {};
    startLoading();
    try {
          await db.runTransaction((transaction) async {
            //getting manager details
            var managerDocRef = db.collection('manager_details').doc(auth.currentUser.uid);
            var managerDoc = await transaction.get(managerDocRef);
            String managerName = managerDoc['name'];

            var terminalDocRef = db.collection('terminal_details').doc('$terminalId');
            var terminalDocs = await transaction.get(terminalDocRef);

            //deleting the terminal at the level of the manager document
            transaction.set(managerDocRef, {
              'terminals' : FieldValue.arrayRemove([{
                'terminal_id' : terminalId,
                'terminal_name' : terminalName
              }])
            },
            SetOptions(merge: true));

            ///deleting the terminal at the level of the terminal's document

            List services = terminalDocs['services'];
            var newServiceList = [];
            for(var service in services) {
              if (service['service_id'] != auth.currentUser.uid){
                newServiceList.add(service);
              }
            }
            transaction.set(terminalDocRef, {
              'services' : newServiceList
            },
                SetOptions(merge: true));
          });

          debugPrint('-----successfully deleted the terminal------');
          await getTerminals();

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
            title: AutoSizeText('${AppLocalizations.of(context).myTerminals} (${terminals.length})', maxLines: 1,),
            actions: [
              IconButton(icon: Icon(Icons.refresh, color: Colors.white),
                  tooltip: AppLocalizations.of(context).refresh ,
                  onPressed: getTerminals
              ),
              IconButton(icon: Icon(Icons.add, color: Colors.white),
                  tooltip: AppLocalizations.of(context).addTerminal,
                  onPressed: addTerminal
              )
            ],
          ),
          body: (terminals.length == 0) ?
          Center(child: Container(child: Text(AppLocalizations.of(context).noTerminalsFound,
          style: TextStyle(
            color: Colors.black,
          ))))
              :
          ListView.builder(
              itemCount: terminals.length,
              itemBuilder: (context, index) {
                String terminalId = terminals[index]['terminal_id'];
                String terminalName = terminals[index]['terminal_name'];
                return MyTile(
                  title: terminalName,
                  trailing: IconButton(
                    icon: Icon(Icons.delete,
                    color: Colors.blue),
                    onPressed: () async{
                      await deleteTerminal(terminalId, terminalName);
                    },
                  )
                );
              }
          )
      ),
    );
  }
}



