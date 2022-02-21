import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:no_queues_manager/constants.dart';

class HelpScreen extends StatefulWidget {
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {

  bool isLoading = false;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> launchPrivacyPolicyUrl() async {
    String _privacyPolicyUrl;
    ///get the privacy policy url from firebase
    try {
      _privacyPolicyUrl =(await  _db.collection('global_info').doc('admin_app_info').get())['privacy_policy_url'];
    }catch(e){
      debugPrint('$e');
      debugPrint('Unable to get the privacy policy url');
      return;
    }

    ///Abort the process if the privacy policy is null (absent)
    if(_privacyPolicyUrl == null) return;

    ///lauch the privacy policy url
    try {
      if(await canLaunch('$_privacyPolicyUrl')) {
        await launch('$_privacyPolicyUrl');
      }else debugPrint('----Unable to launch privacy policy webpage-----');
    }catch(e) {
      debugPrint('$e');
      debugPrint('Unable to launch privacy policy url----');
    }

    return;

  }

  Future<void> launchAboutUrl() async {
    String _aboutUrl;
    ///get the about url from firebase
    try {
      _aboutUrl =(await  _db.collection('global_info').doc('admin_app_info').get())['about_url'];
    }catch(e){
      debugPrint('$e');
      debugPrint('Unable to get the about url');
      return;
    }

    ///Abort the process if the about url is null (absent)
    if(_aboutUrl == null) return;

    ///lauch the about url
    try {
      if(await canLaunch('$_aboutUrl')) {
        await launch('$_aboutUrl');
      }else debugPrint('----Unable to launch about webpage-----');
    }catch(e) {
      debugPrint('$e');
      debugPrint('Unable to launch about url----');
    }

    return;
  }

  Future<void> launchContactUrl() async {
    String _contactUrl;
    ///get the contact url from firebase
    try {
      _contactUrl =(await  _db.collection('global_info').doc('admin_app_info').get())['contact_url'];
    }catch(e){
      debugPrint('$e');
      debugPrint('Unable to get the contact url');
      return;
    }

    ///Abort the process if the contact url is null (absent)
    if(_contactUrl == null) return;

    ///lauch the contact url
    try {
      if(await canLaunch('$_contactUrl')) {
        await launch('$_contactUrl');
      }else debugPrint('----Unable to launch contact webpage-----');
    }catch(e) {
      debugPrint('$e');
      debugPrint('Unable to launch the contact url----');
    }

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'), //todo: translate
      ),
      body: ModalProgressHUD (
        inAsyncCall: isLoading,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(child: Text(
              'Privacy Policy', //todo: translate,
              style: TextStyle(
            color: Colors.black,
        )
            ),
            onPressed: () async{
              startLoading();
              await launchPrivacyPolicyUrl();
              stopLoading();

            }),
            TextButton(child: Text(
                'About', //todo: translate,
              style: TextStyle(
                color: Colors.black
              )

            ),
                onPressed: () async{
                  startLoading();
                  await launchAboutUrl();
                  stopLoading();
                }),
            TextButton(child: Text(
                'Contact Us', //todo: translate,
                style: TextStyle(
                    color: Colors.black
                )

            ),
                onPressed: () async{
                  startLoading();
                  await launchContactUrl();
                  stopLoading();
                }),
            Text(
                'Version: ${adminAppVersion}', //todo: translate,
                style: TextStyle(
                    color: Colors.black
                )

            ),
          ]
        )
      )
    );
  }
}
