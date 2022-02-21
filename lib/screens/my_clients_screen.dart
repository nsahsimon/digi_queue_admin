import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:no_queues_manager/my_widgets/my_tile.dart';

class MyClientsScreen extends StatefulWidget {

  @override
  _MyClientsScreenState createState() => _MyClientsScreenState();
}


class _MyClientsScreenState extends State<MyClientsScreen> {
  List clients = [];
  bool isLoading = false;
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

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

  bool isClientRegistered(QueryDocumentSnapshot clientDoc) {
    bool result = false;
    try {
      bool isRegistered = clientDoc['registered'];
      if (isRegistered == false) result = false;
      else if(isRegistered == true) result = true;
    }catch(e){
      debugPrint('$e');
      result = true;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    Future((){
      getClients();
    });
  }

  Future<void> getClients() async {
    startLoading();
    try {
      var subscriberDocs = await db.collection('manager_details').doc(auth.currentUser.uid).collection('subscribers').doc('summary').get();
      List subscriberList = subscriberDocs['subscribers'];
      setState(() {
        clients = subscriberList;
      });
    }catch(e) {
      debugPrint('$e');
      debugPrint('________failed to load clients _________');
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
          title: AutoSizeText('${AppLocalizations.of(context).activeClients} (${clients.length})', maxLines: 1),
        ),
      body: (clients.length == 0)? Container(
        child: Center(child: Text(AppLocalizations.of(context).noClients))
      ) : ListView.builder(
        itemCount: clients.length,
          itemBuilder: (context, index) {
          return MyTile(
          title: '${index + 1}. '+clients[index]['name'], onTapCallback: (){},
           );
      }
      )
      ),
    );
  }
}
