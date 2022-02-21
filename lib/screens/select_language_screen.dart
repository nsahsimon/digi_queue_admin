import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:no_queues_manager/data/settings_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class SelectLangScr extends StatefulWidget {
  @override
  SelectLangScrState createState() => SelectLangScrState();
}

class SelectLangScrState extends State<SelectLangScr> {


  List<String> langCodes = ['en', 'fr'];
  Map<String, String> languages = {
    'en' : 'English',
    'fr' : 'Francais'
  };
  int selectedIndex = 0;
  FirebaseAuth auth = FirebaseAuth.instance;
  bool automaticallyImplyLeading = false;


  Future<void> storeLang (String lang) async{
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    await _preferences.setString('lang', lang);
  }

  Future<void> onCBChangedCallback(bool newValue, int index) async{
    if(newValue){
      if(await Provider.of<SettingsData>(context, listen: false).setAppLangTo(langCodes[index])) {
        setState(() {
          selectedIndex = index;
        });
      }
    }
  }

  Widget myContainer(){
    return Container(
      height: 30,
      color: Colors.white,
      child: FlatButton(
          color: appColor,
          onPressed: () {
            if (auth.currentUser != null) {
              Navigator.pushNamed(context, '/SelectedQueuesScreen');
            } else {
              Navigator.pushNamed(context, '/LogInScreen');
            }
          },
          child: Text('OK',
              style: TextStyle(
                color: Colors.white,
              ))
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future(() async{
      setState((){
        selectedIndex = langCodes.indexOf(Provider.of<SettingsData>(context, listen: false).getAppLang);
      });

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        title: Text(
AppLocalizations.of(context).language        )
      ),
      backgroundColor: appColor,
      body: Center(
        child: Container(
        color: Colors.white,
          child: Column(
            children: [
              Flexible(
                fit: FlexFit.loose,
                flex: 9,
                child: Container(
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: languages.length,
                      itemBuilder: (BuildContext context, int index){
                        return ListTile(
                          title: Text(languages['${langCodes[index]}']),
                          trailing: Checkbox(
                            value: (selectedIndex == index),
                            onChanged: (newValue) async{
                              await onCBChangedCallback(newValue, index);
    }
                          )
                        );
                      }
                      )
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                flex: 1,
                  child: myContainer())
            ],
          ),
        )
      )
    );
  }
}

class ModSelectLangScr extends SelectLangScr {
  @override
  ModSelectLangScrState createState() => ModSelectLangScrState();
}

class ModSelectLangScrState extends SelectLangScrState {
  @override
  bool automaticallyImplyLeading = true;

  @override
  Widget myContainer(){
    return Text(' ');
  }
}


