import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsData extends ChangeNotifier {
  bool ring = true;
  int notificationInterval = 5;
  String userName;
  String _language = 'en';

  bool get getRingState {
    return ring;
  }

  //set the value of the ring settings
  void setRingTo(bool newValue) {
    ring = newValue;
    notifyListeners();
  }

  void setNotificationIntervalTo(int notificationInterval) {
    this.notificationInterval = notificationInterval;
    notifyListeners();
  }


  Future<bool> setAppLangTo(String lang) async{  //make sure lang is the country code not the entire language name
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try{
      await prefs.setString('lang',lang);
      _language = lang;
      print('------Language set to : $lang-------');
      notifyListeners();
      return true;
    }catch(e){
      print('-----could not set the notification interval-------');
      return false;
    }
  }


  String get getAppLang {
    return _language;
  }


}