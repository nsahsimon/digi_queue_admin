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
                                  hintText: AppLocalizations.of(context).enterTerminalCode
                              ) ,

                            ),
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
    return name.trim();
  }

  Future<void> addTerminal() async{
    String terminalCode = await getTerminalCodeDialog();
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

          //deleting the terminal at the level of the manager document
          transaction.set(managerDocRef, {
            'terminals' : FieldValue.arrayUnion([{
              'terminal_id' : newTerminalId,
              'terminal_name' : newTerminalName
            }])
          },
              SetOptions(merge: true));

          //getting manager details

          //deleting the terminal at the level of the terminal's document
          var terminalDocRef = db.collection('terminal_details').doc('$newTerminalId');
          transaction.set(terminalDocRef, {
            'services' : FieldValue.arrayUnion([{
              'service_name' : managerName,
              'service_id' : auth.currentUser.uid
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

            //deleting the terminal at the level of the manager document
            transaction.set(managerDocRef, {
              'terminals' : FieldValue.arrayRemove([{
                'terminal_id' : terminalId,
                'terminal_name' : terminalName
              }])
            },
            SetOptions(merge: true));

            //deleting the terminal at the level of the terminal's document
            var terminalDocRef = db.collection('terminal_details').doc('$terminalId');
            transaction.set(terminalDocRef, {
              'services' : FieldValue.arrayRemove([{
                'service_name' : managerName,
                'service_id' : auth.currentUser.uid
              }])
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



