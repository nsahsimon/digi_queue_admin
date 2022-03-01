import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:no_queues_manager/terminal/service_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:no_queues_manager/terminal/service_tile.dart';
import 'package:no_queues_manager/screens/add_unregistered_client_screen.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:no_queues_manager/terminal/manager_screen.dart';

class TerminalScreen extends StatefulWidget {
  @override
  _TerminalScreenState createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {

  List myServices = [];
  bool isLoading = false;
  String terminalName = 'N/A';
  String terminalCode = 'N/A';
  String recentToken;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore  db = FirebaseFirestore.instance;


  void startLoading() {
    setState(() {
      isLoading = true;
    });

  }

  void stopLoading() {
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getTerminalDetails() async{
    List terminalServices = [];
    startLoading();
    try {
      DocumentSnapshot terminalDoc = await db.collection('terminal_details').doc(auth.currentUser.uid).get();
      if(terminalDoc.exists) {
        myServices = [];
        terminalName = terminalDoc['name'];
        terminalServices = terminalDoc['services'];
        terminalCode = terminalDoc['terminal_code'];
        for(var service in terminalServices) {
          setState((){
            myServices.add(service);
          });
        }
      } else {
        terminalName = 'Failed to update name';
      }
    }catch (e) {
      print(e);
    }
    stopLoading();
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
                                      child: Text(initials(terminalName),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                          ))
                                  )
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              RichText (
                                  text: TextSpan(
                                      children: [
                                        TextSpan(text: '${locale.name}: ', style: TextStyle(color: Colors.blue)),
                                        TextSpan(text: terminalName.toUpperCase(), style: TextStyle(color: Colors.black))
                                      ]
                                  )
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              RichText (
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: 'code: ', style: TextStyle(color: Colors.blue)),
                                    TextSpan(text: terminalCode, style: TextStyle(color: Colors.black))
                                  ]
                                )
                              )
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
                  child: Text(initials(terminalName),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ))
              )
          )
      ),
    );
  }

  Future<void> onTapCallback(String managerId) async{
    ///Declaring some boolean flags to hold the privileges of this terminal
    bool addClientPermission = true;
    bool validateClientPermission = false;
    bool skipClientPermission = false;
    bool nextPermission = false;
    bool serviceFound =false;

    ///get the terminal privileges from the my services list
    for (Map service in myServices) {
       if(service['service_id'] == '$managerId') {
         try {
           addClientPermission = service['add_client_permission'];
           debugPrint('add client permission: $addClientPermission');
           validateClientPermission = service['add_client_permission'];

           ///service found flag is set to true iff 'addClientPermission' flag is not null
           if(addClientPermission != null) serviceFound = true;

         }catch(e){
           debugPrint('$e');
           debugPrint('Could not extract the privilege flags from firebase');
           serviceFound =false;
           addClientPermission = true;
           validateClientPermission = false;
           skipClientPermission = false;
           nextPermission = false;
         }
         break;
       }
    }


    ///if service found, just proceed to the manager screen
    if(serviceFound == true) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ManagerScr(addClientPermission: addClientPermission, skipPermission: skipClientPermission, validateClientPermission: validateClientPermission, managerId: managerId, nextPermission: nextPermission) ));
    }
  }

  Future<void> saveAccountType(String accountType) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastAccountType', accountType);
  }

  Future<void> logout() async{
    await auth.signOut();
    await saveAccountType('void');
    Navigator.pushNamed(context,'/LogInScreen');
  }

  @override
  void initState() {
    super.initState();
    Future(() async{
      await getTerminalDetails();
      //await loadServices();
    });
  }


  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: appColor,
            title: Row(
              children: [
                profileImage(),
                SizedBox(
                  width: 10
                ),
                AutoSizeText(locale.queues, maxLines: 1),
              ],
            ),
            actions: [
              Center(child: (recentToken != null) ? Text('($recentToken)') : null),
              IconButton(
                tooltip: 'refresh',
                icon: Icon(Icons.refresh,
                    color: Colors.white),
                onPressed: getTerminalDetails,
              ),
              IconButton(
                icon: Icon(Icons.logout,
                color: Colors.white),
                onPressed: logout,
              )
            ]
          ),
          body: ModalProgressHUD (
            inAsyncCall: isLoading,
            child: (myServices == [] || myServices.length == 0) ? Center(
                child: Text(locale.noServiceFound,
                  style: TextStyle(
                    color: Colors.black,
                  ),)
            ) : ListView.builder(
                itemCount: myServices.length,
                itemBuilder: (context, index) {
                  print('-------number of sevices = ${myServices.length}-------');
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          border: Border.all(
                              color: appColor,
                              width: 2
                          )
                      ),
                      child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(myServices[index]['service_name']),
                            ],
                          ),
                          onTap: () async{
                            await onTapCallback(myServices[index]['service_id']);
                          }
                      ),
                    ),
                  );
                }
            ),
          )
        ),
    );
  }
}



