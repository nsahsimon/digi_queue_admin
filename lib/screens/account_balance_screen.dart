import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';


class AccountBalanceScreen extends StatefulWidget {
  @override
  _AccountBalanceScreenState createState() => _AccountBalanceScreenState();
}

class _AccountBalanceScreenState extends State<AccountBalanceScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  DocumentSnapshot _managerDoc;
  int _accountBalance = 0;
  int _costPerClient = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    Future(() async {
      await getAccountDetails();
    });
  }

  void startLoading() {
    if(!mounted) return;
    setState((){
      isLoading = true;
    });
  }

  void stopLoading() {
    if(!mounted) return;
    setState((){
      isLoading = false;
    });
  }


  Future<void> launchRechargeAccountUrl() async {
    String rechargeAccountUrl;
    ///get the privacy policy url from firebase
    try {
      rechargeAccountUrl =(await  _db.collection('global_info').doc('admin_app_info').get())['recharge_account_url'];
    }catch(e){
      debugPrint('$e');
      debugPrint('Unable to get the recharge policy url');
      return;
    }

    ///Abort the process if the privacy policy is null (absent)
    if(rechargeAccountUrl == null) return;

    ///lauch the privacy policy url
    try {
      if(await canLaunch('$rechargeAccountUrl')) {
        await launch('$rechargeAccountUrl');
      }else debugPrint('----Unable to launch about webpage-----');
    }catch(e) {
      debugPrint('$e');
      debugPrint('Unable to launch about url----');
    }

    return;
  }

  Future<void> getAccountDetails() async {
      try {
        _managerDoc = await _db.collection('manager_details').doc('${_auth.currentUser.uid}').get();
        setState((){
          _accountBalance = _managerDoc['account_balance'];
          _costPerClient = _managerDoc['cost_per_client'];
        });
      }catch(e) {
        debugPrint('$e');
        debugPrint('----was unable to get the account balancee details');
        return;
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText(
          'Account Balance', //todo: translate,
          maxLines: 1,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async{
              startLoading();
              await getAccountDetails();
              stopLoading();
            },
          )
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: SingleChildScrollView(
          child: Container(
            child: Column (
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20
                ),
                Center(
                  child: Text('BALANCE', //todo: translate
                  style: TextStyle(
                    color: Colors.lightGreen,
                  ),),
                ),
                Center(
                  child: Text('$_accountBalance' + ' XAF',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold
                    ),),
                ),
                SizedBox(
                  height: 20
                ),
                Center(
                  child: Text('COST PER CLIENT', //todo: translate
                    style: TextStyle(
                      color: Colors.lightGreen
                    ),),
                ),
                Center(
                  child: Text('$_costPerClient' + ' XAF',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold
                    ),),
                ),
                SizedBox(
                    height: 20
                ),
                Center(
                  child: Text('CLIENTS COVERED', //todo: translate
                    style: TextStyle(
                        color: Colors.lightGreen
                    ),),
                ),
                Center(
                  child: Text('${(_accountBalance/_costPerClient)}',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.bold
                    ),),

                ),
                SizedBox(
                    height: 20
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: AutoSizeText('Note*: Your clients will be charged a sum of 100 XAF as soon as your funds are exhausted', //todo: translate
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.red
                      ),),
                  ),
                ),
                SizedBox(
                  height: 10
                ),
                FlatButton(
                    onPressed: ()async => await launchRechargeAccountUrl(),
                    color: Colors.redAccent,
                    child: AutoSizeText(
                      'Recharge', //todo: translate
                        maxLines: 1,
                      style: TextStyle(
                        color: Colors.white
                      )
                    ))
              ],
            ),
          ),
        )
      )

    );
  }
}
