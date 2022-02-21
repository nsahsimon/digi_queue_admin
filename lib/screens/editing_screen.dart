import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:no_queues_manager/my_widgets/custom_text_field.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:no_queues_manager/data/settings_data.dart';
import 'package:no_queues_manager/data/manager_details.dart';
import 'package:provider/provider.dart';



class EditingScreen extends StatefulWidget {
  @override
  _EditingScreenState createState() => _EditingScreenState();
}

class _EditingScreenState extends State<EditingScreen> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool obscureText = true;
  TimeOfDay selectedOpeningTime = TimeOfDay.now();
  TimeOfDay selectedClosingTime = TimeOfDay.now();
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  int durationValue = 1;

  List<DropdownMenuItem> durations(int count) {
    List<DropdownMenuItem> durationList= [];
    for(var i = 1; i<=count; i++) {
      var ddmi = DropdownMenuItem(
        child: Text('$i ${(i==1) ? 'minute' : 'minutes'}'),
        value: i,
      );
      durationList.add(ddmi);
    }
    return durationList;
  }

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

  String timeInLocaleFormat(TimeOfDay time)  {
    if('en' == Provider.of<SettingsData>(context, listen: false).getAppLang) {
      return DateFormat('hh:mm a').format(DateFormat('H:m').parse('${time.hour}:${time.minute}'));
    }else {
      return DateFormat('HH:mm').format(DateFormat('H:m').parse('${time.hour}:${time.minute}'));
    }
  }


  Widget timeField() {
    var locale = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(locale.availPeriod,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 17,
            )),
        Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.from),
                Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(timeInLocaleFormat(selectedOpeningTime),
                      style: TextStyle()),
                      GestureDetector(
                        onTap: () async{
                          final TimeOfDay time = await showTimePicker(
                              context: context,
                              initialTime: selectedOpeningTime,
                              initialEntryMode: TimePickerEntryMode.input,
                              builder: (context, child) {
                                return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: ('en' == Provider.of<SettingsData>(context, listen: false).getAppLang) ? false : true),
                                    child: child
                                );
                              }
                          );
                          if(time != null && time != selectedOpeningTime) {
                            setState(() {
                              selectedOpeningTime = time;
                            });
                          }
    },
                        child: Text(locale.change,
                            style: TextStyle(
                                color: Colors.blue
                            )),
                      )]
                ),
                Text(locale.to),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(timeInLocaleFormat(selectedClosingTime)),
                      GestureDetector(
                        onTap: () async{
                          final TimeOfDay time = await showTimePicker(
                              context: context,
                              initialTime: selectedClosingTime,
                              initialEntryMode: TimePickerEntryMode.input,
                              builder: (context, child) {
                                return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: ('en' == Provider.of<SettingsData>(context, listen: false).getAppLang) ? false : true),
                                    child: child
                                );
                              }
                          );
                          if(time != null && time != selectedClosingTime) {
                            setState(() {
                              selectedClosingTime = time;
                            });
                          }
                        },
                        child: Text(locale.change,
                            style: TextStyle(
                                color: Colors.blue
                            )),
                      )]
                ),
              ]
          ),
        ),
        Divider(
          thickness: 1,
          color: Colors.black54,
        )
      ],
    );
  }

  //puts the time in the right format for storage in the database
  String formattedTime(TimeOfDay time) {
    return DateFormat('H:m').format(DateFormat('H:m').parse('${time.hour}:${time.minute}'));
  }


  String emailValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidEmailMsg;
    }else if (value.length < 8){
      return AppLocalizations.of(context).shortEmailMsg;
    } else return null;
  }

  String nameValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidName;
    }else return null;
  }

  String pwdValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidePwdMsg;
    }else if (value.length < 8){
      return AppLocalizations.of(context).shortPwdMsg;
    }else return null;
  }

  String timeValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidTime;
    }else return null;
  }

  String descriptionValidation(var value) {
    if (value.length > 100){
      return 'Description is too long'; //todo: translate
    } else return null;
  }

  String phoneValidation(var value) {
    if(value == null || value.isEmpty){
      return 'Invalid';
    }else if (value.replaceAll(' ','').trim().length != 9) {
      return 'Invalid';
    }else if(value.replaceAll(' ','').trim()[0] != '6') {
      return 'Invalid';
    }
  }

  String locationValidation(var value) {
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).invalidLocation;
    }else return null;
  }


  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  TimeOfDay stringToTimeOfDay(String time){
    return TimeOfDay(hour: int.parse(time.split(':')[0]), minute: int.parse(time.split(':')[1]));
  }

  ///loading the details from firestore
  Future<void>  loadingDetails() async{
    debugPrint('----loading the the previous client details---');
    stopLoading();
    try {

      DocumentSnapshot manDetails = await FirebaseFirestore.instance.collection('manager_details').doc(_auth.currentUser.uid).get();
      var userDoc = manDetails;

      setState((){
        try {
          descriptionController.text = userDoc['description'];
        }catch(e) {
          descriptionController.text = '';
        }
        phoneController.text = userDoc['phone'];
        locationController.text = userDoc['location'];
        emailController.text = userDoc['email'];
        nameController.text = userDoc['name'];
        String _openingTime = userDoc['opening_time'];
        String _closingTime = userDoc['closing_time'];
        selectedOpeningTime = TimeOfDay(hour: int.parse(_openingTime.split(':')[0]), minute: int.parse(_openingTime.split(':')[1]));
        selectedClosingTime = TimeOfDay(hour: int.parse(_closingTime.split(':')[0]), minute: int.parse(_closingTime.split(':')[1]));
        int timePeriod = userDoc['time_period']; //gets time period in seconds
        if(timePeriod > 3600) durationValue = 60;
        else if (timePeriod <60) durationValue = 1;
        else durationValue = (timePeriod / 60).floor();
      });


    } catch(e){
      debugPrint('$e');
      // TODO
    }
    stopLoading();
  }

  Future<void> addManagerDetails() async{
    if(formKey.currentState.validate()) {
      startLoading();
      try {
        var docRef = FirebaseFirestore.instance.collection('manager_details');
        String id = FirebaseAuth.instance.currentUser.uid;
        await docRef.doc(id).set({
          'phone': phoneController.text.replaceAll(' ', '').trim(),
          'location' : locationController.text,
          'description': descriptionController.text.trim(),
          'opening_time' : formattedTime(selectedOpeningTime),
          'closing_time' : formattedTime(selectedClosingTime),
          'open' : true,
          'time_period' : durationValue * 60
          //'id' : id,
        },
        SetOptions(merge: true));
        final SnackBar msg = SnackBar(content: Text('Success'), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }catch (e) {
        final SnackBar msg = SnackBar(content: Text('Failure'), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
      Navigator.pop(context);
      stopLoading();
    }
  }

  @override
  void initState() {
    super.initState();
    Future(() async {
      await loadingDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: appColor,
          title: Text(
          AppLocalizations.of(context).editAccount,
              style: TextStyle (
                color: Colors.white,
              )
          )
      ),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ListView(
                children: [
                  MyTextField(controller: phoneController, labelText: 'Tel', validator: phoneValidation,hintText: 'Ex. 675749781', inputType: TextInputType.phone,),
                  MyTextField(controller: descriptionController, labelText: 'Description', hintText: '', validator: descriptionValidation),
                  //MyTextField(controller: nameController, labelText: AppLocalizations.of(context).name, validator: nameValidation,),
                 // MyTextField(controller: emailController, labelText: AppLocalizations.of(context).email, hintText: AppLocalizations.of(context).enterValEmail, validator: emailValidation),
                  MyTextField(controller: locationController, labelText: AppLocalizations.of(context).location, hintText: AppLocalizations.of(context).preciseLocation , validator: locationValidation, inputType: TextInputType.text,),
                  timeField(),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                      AppLocalizations.of(context).clientDuration,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 17,
                      )
                  ),
                  Container(
                    child: DropdownButton(
                      items: durations(60),
                      value: durationValue,
                      onChanged: (newVal) {
                        if(durationValue != newVal){
                          setState((){
                            durationValue = newVal;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  FlatButton(
                      minWidth: MediaQuery.of(context).size.width,
                      color: appColor,
                      onPressed: () {
                        //TODO: Add some authentication logic
                        addManagerDetails();
                      },
                      child: Text(
                          AppLocalizations.of(context).submit,
                          style: TextStyle(
                            color: Colors.white,
                          )
                      )),
                  SizedBox(
                    height: 20,
                  )
                ]
            ),
          ),
        ),
      ),
    );
  }
}


class MyTimeField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('From'),
        Column(
          children: [
          Text('12:00 AM'),
          TextButton(
            child: Text('change',
                style: TextStyle(
                    color: Colors.blue
                ))
          )]
        ),
        Text('To'),
        Column(
            children: [
              Text('06:00 PM'),
              TextButton(
                  child: Text('change',
                  style: TextStyle(
                    color: Colors.blue
                  ))
              )]
        ),
      ]
    );
  }
}

