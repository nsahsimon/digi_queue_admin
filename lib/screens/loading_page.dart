import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_manager/data/settings_data.dart';


class LoadPage extends StatefulWidget {
  @override
  _LoadPageState createState() => _LoadPageState();
}



class _LoadPageState extends State<LoadPage> {

  bool gotoSelectLangScr = false;
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), ()async { await initialize();});
  }

  Future<String> lastAccountType() async {
      var prefs = await SharedPreferences.getInstance();
      var result;
      try {
        result = prefs.getString('lastAccountType');
      }catch(e) {
    }
    return result ?? 'void';
  }



  Future<void> loadLang() async{
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    try {
      String lang = _preferences.getString('lang') ?? 'no_lang_on_disk';
      //TODO: add code here to load the language locale
      (lang == 'no_lang_on_disk') ?
      await Provider.of<SettingsData>(context,listen: false).setAppLangTo('en') :
      await Provider.of<SettingsData>(context,listen: false).setAppLangTo(lang);
      print('-------the selected language is: $lang-------');
      gotoSelectLangScr = (lang == 'no_lang_on_disk');
    }catch(e) {
      print(e);
      print('-----could not load languages--------');
      gotoSelectLangScr = false;
    }

  }

  Future<void> initialize() async{
    await loadLang();
    if (!gotoSelectLangScr) {
      if (auth.currentUser != null) {
        Future(() async{
          if('manager' == await lastAccountType()) {
            Navigator.pushNamed(context, '/DashBoardScreen');
          } else if ('terminal' == await lastAccountType()) {
            Navigator.pushNamed(context, '/TerminalScreen');
          } else {
            Navigator.pushNamed(context, '/LogInScreen');
          }

        });
      } else {
        Future(() {
          Navigator.pushNamed(context, '/LogInScreen');
        });
      }
    } else {
      Navigator.pushNamed(context, '/SelectLangScreen');
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.red,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Image.asset('assets/images/admin_logo.png',height: 100, width: 100),
              ),
            ]
        )
      ),
    );
  }
}

