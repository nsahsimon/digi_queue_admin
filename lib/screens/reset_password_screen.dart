import 'dart:async';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_manager/my_widgets/custom_text_field.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:no_queues_manager/my_widgets/dialogs.dart';



class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool noUserFoundForEmail = false;
  bool pwdSuccessfullyReset = false;

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

  String emailValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).requestValEmail;
    }else if (value.length < 8){
      return AppLocalizations.of(context).shortEmailMsg;
    }else if(noUserFoundForEmail) {
      return 'No user found for this email'; //todo: translate
    } else return null;
  }

  TextEditingController emailController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> ResetPwd() async{
    ///reset flags
    noUserFoundForEmail = false;
    bool isSignedInAnonymously = false;


    if(formKey.currentState.validate()) {
      startLoading();
      debugPrint('--email: ${emailController.text}');
      try {
        if(auth.currentUser != null) {
          await auth.signOut();
        }
        await auth.sendPasswordResetEmail(email: emailController.text.trim()).timeout(Duration(seconds: 5));
        await Dialogs(context: context).customDialog(text: 'Email sent. Check your email account for further instructions', icon: Icon(Icons.email, size: 70, color: Colors.yellow));

        Navigator.pop(context);

      }on TimeoutException catch(e) {
        debugPrint('$e');
        debugPrint('-----Login Timeout!!----');

      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          noUserFoundForEmail = true;
          debugPrint('No user found for that email.');
        }

        debugPrint('------password reset failed--------');
      }

      ///make sure to sign out if the the user was signed in anonymously

        ///revalidate
        formKey.currentState.validate();
      }
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText(
          'Reset Password',
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
          )
        ),
        backgroundColor: appColor,
      ),
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: ListView(
                children: [
                  SizedBox(
                    height: 60,
                  ),
                  // Center(child: AutoSizeText('Reset Password', //todo: translate
                  //   maxLines: 1,
                  //   style: TextStyle(
                  //     color: Colors.red,
                  //     fontSize: 30,
                  //   ),)),
                  MyTextField(controller: emailController, labelText: AppLocalizations.of(context).email, hintText: AppLocalizations.of(context).enterEmail, validator: emailValidation ,inputType: TextInputType.emailAddress,),
                  SizedBox(
                    height: 10,
                  ),
                  FlatButton(
                      minWidth: 400,
                      color: appColor,
                      onPressed: () async{
                        startLoading();
                        if(await Dialogs(context: context).checkUpdatesDialog() == false) {
                          stopLoading();
                          return;}
                        try {
                          await ResetPwd().timeout(Duration(seconds: 15));
                        } on TimeoutException  catch (e) {
                          debugPrint('$e');
                          debugPrint('-----Timeout------');
                        }
                        stopLoading();
                      },
                      child: Text('reset password', //todo: translate
                          style: TextStyle(
                              color: Colors.white
                          ))),
                  TextButton(
                      child: Text(
                          AppLocalizations.of(context).language,
                          style: TextStyle(
                            color: Colors.blue,
                          )
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/ModifiedSelectLangScreen');
                      }
                  )
                ]
            ),
          ),
        ),
      ),
    );
  }
}
