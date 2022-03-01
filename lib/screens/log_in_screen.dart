import 'dart:async';

import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:no_queues_manager/my_widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_manager/my_widgets/dialogs.dart';
import 'package:auto_size_text/auto_size_text.dart';


class LogInScreen extends StatefulWidget {
  const LogInScreen({Key key}) : super(key: key);

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isManagerAccount = true;
  bool isTerminalAccount = false;
  bool noUserFoundForEmail = false;
  bool wrongPassword = false;

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

  ///validation callbacks
  String emailValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).requestValEmail;
    }else if (value.length < 8){
      return AppLocalizations.of(context).shortEmailMsg;
    }else if(value.trim() == ""){
      return "cannot contain empty spaces";
    }else if(noUserFoundForEmail) {
      return 'No user found for this email'; //todo: translate
  } else return null;
  }

  String pwdValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).requestValPwd;
    }else if(value.trim() == ""){
      return "cannot contain empty spaces";
    }
    else if(wrongPassword) {
      return 'Wrong password'; //todo: translate
    }
    else return null;
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  bool skipToDashBoard = false;


  Future<void> saveAccountType(String accountType) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastAccountType', accountType);
  }

 Widget selectAccountType() {
  return Container(
      color: Colors.white,
      child: Column(
          children: [
            AutoSizeText(AppLocalizations.of(context).selectAccountType, maxLines: 1),
            Row(
                children: [
                  Expanded(
                    child: ListTile(
                        title: AutoSizeText(AppLocalizations.of(context).manager, maxLines: 1),
                        trailing: Checkbox(
                            value: isManagerAccount,
                            onChanged: (bool newValue) {
                              setState((){
                                isManagerAccount = newValue;
                                isTerminalAccount =!newValue;
                              });
                            }
                        )
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                        title: AutoSizeText(AppLocalizations.of(context).terminal, maxLines: 1),
                        trailing: Checkbox(
                            value: isTerminalAccount,
                            onChanged: (bool newValue) {
                              setState((){
                                isTerminalAccount = newValue;
                                isManagerAccount = !newValue;
                              });
                            }
                        )
                    ),
                  )
                ]
            )
          ]
      )
  );
}

  Future<bool> isATerminal() async {
      try {
        var snapshots = await FirebaseFirestore.instance.collection('terminal_details').where('id',isEqualTo: FirebaseAuth.instance.currentUser.uid).get().timeout(Duration(seconds:5));
        if(snapshots.docs.isEmpty) return false;
        return true;
      } catch (e) {
        return false;
      }
  }

  Future<bool> isAManager() async{
    try {
      var snapshots = await FirebaseFirestore.instance.collection('manager_details').where('id',isEqualTo: FirebaseAuth.instance.currentUser.uid).get().timeout(Duration(seconds: 5));
      if(snapshots.docs.isEmpty) return false;
      return true;
    }catch (e) {
      return false;
    }
  }

  Future<void> managerLogin() async{
    ///reset flags
    wrongPassword = false;
    noUserFoundForEmail = false;

     if(formKey.currentState.validate()) {
       startLoading();
       debugPrint('--email: ${emailController.text}');
       debugPrint('---password: ${passwordController.text}');
       try {
         UserCredential user = await auth.signInWithEmailAndPassword(
             email: emailController.text.trim(),
             password: passwordController.text).timeout(Duration(seconds: 5));

         if(user != null && await isAManager()) {
           await saveAccountType('manager');
           Navigator.pushNamed(context, '/DashBoardScreen');
         }else {
           await FirebaseAuth.instance.signOut();
         }
       }on TimeoutException catch(e) {
         debugPrint('$e');
          debugPrint('-----Login Timeout!!----');
       } on FirebaseAuthException catch (e) {
         if (e.code == 'user-not-found') {
           noUserFoundForEmail = true;
           debugPrint('No user found for that email.');
         } else if (e.code == 'wrong-password') {
           wrongPassword = true;
           debugPrint('Wrong password provided for that user.');}

         ///revalidate
         formKey.currentState.validate();
       }
     }

  }

  Future<void> terminalLogin() async{
    ///reset flags
    wrongPassword = false;
    noUserFoundForEmail = false;

  if(formKey.currentState.validate()) {
    startLoading();
    debugPrint('--email: ${emailController.text}');
    debugPrint('password: ${passwordController.text}');
    try {
      UserCredential user = await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text).timeout(Duration(seconds: 5));

      if(user != null && await isATerminal()) {
        await saveAccountType('terminal');
        Navigator.pushNamed(context, '/TerminalScreen');
      }else {
        await FirebaseAuth.instance.signOut();
      }
    }on TimeoutException catch(e) {
      debugPrint('$e');
      debugPrint('------login timeout!!!!------');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        noUserFoundForEmail = true;
        debugPrint('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        wrongPassword = true;
        debugPrint('Wrong password provided for that user.');
      }
      ///revalidate
      formKey.currentState.validate();
    }
    stopLoading();
  }

}


  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: ()async => false,
      child: Scaffold(
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
                      height: 50,
                    ),
                    Center(child: AutoSizeText(AppLocalizations.of(context).login,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 30,
                    ),)),
                    SizedBox(
                      height: 10,
                    ),
                    selectAccountType(),
                    SizedBox(
                      height: 10,
                    ),
                    MyTextField(controller: emailController, labelText: AppLocalizations.of(context).email, hintText: AppLocalizations.of(context).enterEmail, validator: emailValidation ,inputType: TextInputType.emailAddress,),
                    MyTextField(controller: passwordController, labelText: AppLocalizations.of(context).pwd, hintText: AppLocalizations.of(context).enterPwd, obscureText: true, validator: pwdValidation,),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/ResetPasswordScreen');
                        },
                        child: AutoSizeText('Forgot password?',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.lightBlue,
                            )),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                            AppLocalizations.of(context).noAccount,
                                style: TextStyle(
                                  color: appColor,
                                )),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/LogInScreen/SignUpScreen');
                              },
                              child: AutoSizeText(AppLocalizations.of(context).register,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.lightBlue,
                                  )),
                            )
                          ],
                        ),
                      ],
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
                            isManagerAccount ? await managerLogin().timeout(Duration(seconds: 15)) : await terminalLogin().timeout(Duration(seconds: 15));
                          } on TimeoutException  catch (e) {
                            debugPrint('$e');
                            debugPrint('-----Timeout------');
                          }
                          stopLoading();
                        },
                        child: Text(AppLocalizations.of(context).login,
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
      ),
    );
  }
}
