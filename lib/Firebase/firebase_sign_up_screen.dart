import 'package:flutter/material.dart';
import 'firebase_loggedin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
   bool isCodeSent = false;
   String userCode;
   String phoneNum;
   String _verificationId;
   bool isLoading = false;
   PhoneAuthCredential _phoneAuthCredential;
  FirebaseAuth _auth = FirebaseAuth.instance;


  @override
  Widget build(BuildContext context) {
    if(!isLoading){
    return !isCodeSent? logInScreen(): verificationScreen(); }
    else return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      )
    ) ;
  }

  Future<void> signInWithCredentials(PhoneAuthCredential credential)async{
    setState(() {
      isLoading = true;
    });
    try {
      final authCredential = await _auth.signInWithCredential(credential);
      if(authCredential.user != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LoggedInScreen()));
      }
    }catch(e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });



  }

Widget verificationScreen() {
  return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: ListView(
            children: [
              TextField(
                cursorColor: Colors.black,
                enabled: true,
                decoration: InputDecoration(
                  hintText: 'Enter SMS code',
                ),
                onChanged: (value) {
                  userCode = value;
                },
              ),
              FlatButton(
                  color: Colors.red,
                  onPressed: () async{
                    _phoneAuthCredential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: userCode);

                    signInWithCredentials(_phoneAuthCredential);
                    // Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
                    //   return LoggedInScreen();
                    // }));
                  },
                  child: Center(
                    child: Text('Confirm Code'),
                  ))
            ]
        ),
      )
  );
}


Widget logInScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: ListView(
          children: [
            TextField(
              cursorColor: Colors.black,
              enabled: true,
              decoration: InputDecoration(
                hintText: 'Enter Phone Number',
              ),
              onChanged: (value) {
                phoneNum = value;
              },
            ),
            FlatButton(
              color: Colors.red,
                onPressed: () async{
                setState(() {
                  isLoading = true;
                });
                  await _auth.verifyPhoneNumber(
                      phoneNumber: phoneNum,
                      verificationCompleted: (phoneAuthCredential) async{
                        setState(() {
                          isLoading = false;
                        });
                        await signInWithCredentials(phoneAuthCredential);
                      },
                      verificationFailed: (firebaseAuthException) async{
                            print(firebaseAuthException.message);
                            setState(() {
                              isLoading = false;
                            });
                      },
                      codeSent: (verificationId , resendingToken) async{
                        setState(() {
                          isLoading = false;
                        });
                        this._verificationId = verificationId;
                        print('message sent');
                        setState(() {
                          isCodeSent = true;
                        });
                      },
                      codeAutoRetrievalTimeout: (verificationId) async {

                      });


                },
                child: Center(
                  child: Text('Send Verification Code'),
                ))
          ]
        ),
      )
    );
  }
}

