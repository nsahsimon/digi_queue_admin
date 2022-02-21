import 'dart:convert';

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:no_queues_manager/models/messaging.dart';
import 'dart:io';



class PushNotificationService {
  String _tokenId;
  static const String kAppId = '732561ee-1357-4eff-ae41-cad0a7bcbfa4';

  ///Get the device token id
  ///this is a unique identifier for your device
  Future<String> getTokenId() async {
    try {
      var status = await OneSignal.shared.getPermissionSubscriptionState();
      _tokenId = status.subscriptionStatus.userId;
    }catch(e) {
      debugPrint('Could not retrieve the one signal token id');
      debugPrint('$e');
    }
    return _tokenId ?? '';
  }


  void initialize() {
    OneSignal.shared.init(kAppId);
  }

  String get tokenId {
    return _tokenId;
  }

  Future<Response> sendNotification({List<String> tokenIdList, String contents, String heading, String lang = 'en'}) async{

    try {
      debugPrint('----Sending Notification to ${tokenIdList[0]}-------');
      return await post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>
        {
          "app_id": kAppId,//kAppId is the App Id that one get from the OneSignal When the application is registered.

          "include_player_ids": tokenIdList,//tokenIdList Is the List of All the Token Id to to Whom notification must be sent.

          // android_accent_color reprsent the color of the heading text in the notifiction
          "android_accent_color":"FF9976D2",

          "small_icon":"ic_stat_onesignal_default",

          "large_icon":"https://www.filepicker.io/api/file/zPloHSmnQsix82nlj9Aj?filename=name.jpg", //todo: place the link of custom image linkg

          "headings": {lang: heading},

          "contents": {lang: contents},


        }),
      );
    } catch(e) {
      debugPrint('-----Something went wrong; Unable to send the notification index-------');
    }

    }

}
