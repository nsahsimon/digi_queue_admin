import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:auto_size_text/auto_size_text.dart';

Future<bool> validateUnregisteredClient(String token, BuildContext context) async{
  bool success = false;
    await showDialog(
        context: context,
        builder: (context) {
          String enteredToken;
          return AlertDialog(
            title: Center(
                child: AutoSizeText('Enter the client\'s token', maxLines: 1)), //todo: translate
              content: Container(
                  height: 100,
                  color: Colors.white,
                  child: SingleChildScrollView(
                      child: Column(
                          children: [
                            TextField(
                              onChanged: (newText) {
                                enteredToken = newText;
                              },
                              decoration: InputDecoration(
                                  hintText: 'Enter Token' //todo: translate
                              ) ,

                            ),
                            FlatButton(
                              color: appColor,
                              child: AutoSizeText(
                                  'OK',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                  )
                              ),
                              onPressed: () async{
                                if(enteredToken != null && enteredToken.trim() != '') {
                                  if(enteredToken == token){
                                    success = true;
                                  }else {
                                    success = false;
                                    Navigator.pop(context);
                                  }
                                  if(success){
                                    Navigator.pop(context);
                                  }
                                }
                                else {
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

    return success;
}
