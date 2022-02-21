import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoggedInScreen extends StatelessWidget {
  final String userName = 'user 1';
  final _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Text(
          'logged in as ${_auth.currentUser.toString()})'
        ),
      ),
         floatingActionButton: FloatingActionButton(
           onPressed: () async{
             await _auth.signOut();
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>LoggedInScreen() ));
           },
           child: Icon(Icons.logout),
         )
         ,
    );
  }
}
