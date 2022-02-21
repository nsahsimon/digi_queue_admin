import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:no_queues_manager/my_widgets/custom_text_field.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:no_queues_manager/data/filter_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_manager/data/settings_data.dart';
import 'package:intl/intl.dart';
import 'package:no_queues_manager/my_widgets/dialogs.dart';
import 'package:auto_size_text/auto_size_text.dart';

class SignUpScreen extends StatefulWidget {
     @override
     _SignUpScreenState createState() => _SignUpScreenState();
}
 
class _SignUpScreenState extends State<SignUpScreen> {


  String serviceCode;
  String terminalCode;
  bool isProcessing = false;
  List<int> emptyList = []; //this list will hold time periods for the last 10 clients
  bool emailAlreadyInUse = false;
  bool weakPassword = false;
  bool passwordsDontMatch = false;

  int regionValue = 0;
  int divisionValue = 0;
  int subDivisionValue = 0;
  int serviceTypeValue = 0;
  int durationValue = 1;
  TimeOfDay selectedOpeningTime = TimeOfDay(hour: 7, minute: 00);
  TimeOfDay selectedClosingTime = TimeOfDay(hour: 17, minute: 00);

  Map<String , String> genFilters() {
    String region = Regions(context).regionsRef[regionValue];
    String division = Divisions().div(region)[divisionValue];
    String subDivision = SubDivisions().subDiv(division)[subDivisionValue];
    String serviceType = ServiceType(context).serviceTypeRef[serviceTypeValue];

    debugPrint('------selected filters: region: $region \n division: $division \n subdivision: $subDivision \n serviceType: $serviceType-------');

    return {
      'region' : region,
      'division' : division,
      'sub-division' : subDivision,
      'service-type' : serviceType,
    };
  }


  //puts the time a format compatible with the language locale in use
  String timeInLocaleFormat(TimeOfDay time)  {
    if('en' == Provider.of<SettingsData>(context, listen: false).getAppLang) {
      return DateFormat('hh:mm a').format(DateFormat('H:m').parse('${time.hour}:${time.minute}'));
    }else {
      return DateFormat('HH:mm').format(DateFormat('H:m').parse('${time.hour}:${time.minute}'));
    }
  }

  //puts the time in the right format for storage in the database
  String formattedTime(TimeOfDay time) {
      return DateFormat('H:m').format(DateFormat('H:m').parse('${time.hour}:${time.minute}'));
  }

  Widget timeField() {
    var locale = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(locale.availPeriod,
            maxLines: 1,
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
                        child: AutoSizeText(locale.change,
                            maxLines: 1,
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
                        child: AutoSizeText(locale.change,
                            maxLines: 1,
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

  final formKey = GlobalKey<FormState>();
     bool isLoading = false;
     bool obscureText = true;
     bool isManagerAccount = true;
     bool isTerminalAccount = false;

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
        }else if(emailAlreadyInUse) {
         return 'This email taken. Try another'; //todo: translate
       }
       else return null;
        }

        String descriptionValidation(var value) {
       if (value.length > 100){
      return 'Description is too long'; //todo: translate
    } else return null;
  }


     String pwdValidation(var value) {
       if(value == null || value.isEmpty){
         return AppLocalizations.of(context).requestValPwd;
       }else if (value.length < 6) {
         return AppLocalizations.of(context).shortPwdMsg;
       } else if (weakPassword) {
         return 'weak password'; //todo: translate
       }else if (passwordsDontMatch) {
         return 'passwords don\'t match'; //todo: translate
       }
       else return null;
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

     String nameValidation(var value) {
       if(value == null || value.isEmpty){
         return AppLocalizations.of(context).invalidName;
       }else return null;
     }

     String locationValidation(var value) {
       if (isManagerAccount) {
         if(value == null || value.isEmpty){
           return AppLocalizations.of(context).invalidLocation;
         }else return null;
       }
     }

     TextEditingController nameController = TextEditingController();
     TextEditingController phoneController = TextEditingController();
     TextEditingController emailController = TextEditingController();
     TextEditingController passwordController = TextEditingController();
     TextEditingController confirmPasswordController = TextEditingController();
     TextEditingController locationController = TextEditingController();
     TextEditingController descriptionController = TextEditingController();
     FirebaseFirestore db = FirebaseFirestore.instance;
     FirebaseAuth auth = FirebaseAuth.instance;


///widget for the confirmation screen items
  Widget kfirmItem({String label, String value, bool inUCase = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 15,
        ),
        Text('${label.trim()}',),
        SizedBox(
          height: 5,
        ),
        Text('${(inUCase) ? value.trim().toUpperCase() : value.trim()}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
            ))
      ]
    );

  }

///Function to add the manager details
  Future<bool> addManagerDetails() async{
       bool result = true;
       int totalClientCount = 0;
       int firstClientIndex = 1;
       int filterServiceCount; //the number of services registered for this Filter
       int maxServices = 50; //TODO: need to increase (to 50) this number later on. This is the length of the service map per document in the services collection.
       int docNum; //the number of the service set in the filter document to which to add this new service
       bool firstInMap; //tells me whether this service is the first to be added to the service map
       int filterCount; //the total number of filters registered in the system
       String thisFilterId; //the document id of the document containing the current filter.
       debugPrint('---started creation of account-----');
       try {

         debugPrint('_________trying to get the filter docs ________');
         var filterDocs = await db.collection('filter_docs').where('filter',isEqualTo: genFilters()).get();

         ///check if the current filter already exists.
         ///if it does, just add the new filter
         if(filterDocs.docs.isNotEmpty) { //if this filter already exists do this
           debugPrint('_________filter docs exist_________');
            filterServiceCount = filterDocs.docs[0]['service_count']; //
            thisFilterId = filterDocs.docs[0]['id'];
            docNum = (filterServiceCount / maxServices).floor() + 1;
            firstInMap = (filterServiceCount % maxServices == 0);
         }

         ///if the current filter does'nt exist yet, create a new document for it
         else { //if this filter doesn't yet exist, create a document for it
           debugPrint('________filter docs don\'t exist_________');

           ///transaction for the creation of a new filter document
           await db.runTransaction((transaction) async {
             //if the exists no document containing this filter, create one
             var filterInfoRef = db.collection('global_info').doc('filter_info'); //this document contains general information about all the saved filters
             var filterInfo = await transaction.get(filterInfoRef);

             try {
               filterCount = filterInfo['filter_count'];
             } catch (e) {
               debugPrint('$e');
               debugPrint('----filter info collection is not yet created------');
               debugPrint('-----creating filter info document------');
               transaction.set(filterInfoRef,{
                 'filter_count' : 0,
               });
               filterCount = 0;
               debugPrint('----filter info document was created--------');
             }


             debugPrint('-----filter Count: $filterCount ------');
             //creating a new filter document
             var thisFilterRef = db.collection('filter_docs').doc('${filterCount + 1}');
             transaction.set(thisFilterRef, {
               'id' : '${filterCount + 1}',
               'filter' : genFilters(),
               'service_count' : 0,
             });

             debugPrint('----successfully created filter document-------');
             thisFilterId = "${filterCount + 1}";

             //incrementing the global filter count
             transaction.update(filterInfoRef, {
               'filter_count' : FieldValue.increment(1),
             });
             debugPrint('_______successfully created a new filter________');

           },
           timeout: Duration(seconds: 10));

           docNum = 1;
           firstInMap = true;
         }



         ///transaction for the actual addition of a new admin or manger
         await db.runTransaction( (transaction) async{
           int _initialBonus = 0; //amount received when account is created
           int _costPerClient = 0; //amount to be paid per client inorder to receive the service
           debugPrint('______I just got into the next transaction______');
           String id = FirebaseAuth.instance.currentUser.uid;

           DocumentReference managerInfoRef = db.collection('global_info').doc('manager_info');
           var managerCountDoc = await transaction.get(managerInfoRef);

           _initialBonus = managerCountDoc['initial_bonus'];
           _costPerClient = managerCountDoc['cost_per_client'];

           var filterRef = db.collection('filter_docs').doc(thisFilterId).collection("services").doc('set_$docNum');
           if(!firstInMap) {
             Map serviceMap = (await transaction.get(filterRef))['services'];
             serviceMap.putIfAbsent(auth.currentUser.uid, () => nameController.text);
             transaction.update(filterRef, {
               'services' : serviceMap,
             });
             debugPrint('______filter service added successfully________');

           }else {
             transaction.set(filterRef, {
               'services' : {auth.currentUser.uid : nameController.text}
             });
             debugPrint('_______filter service added successfully _______');
           }
           if(managerCountDoc.exists) {
               serviceCode = '${managerCountDoc['manager_count'] + 1}';
           }else {
             transaction.set(managerInfoRef, {
               'manager_count' : 0,
             });
             serviceCode = '1';
           }

           debugPrint('_______Got the manager details successfuly______');

           //add filter details
           //increment the service count for this filter
           var filterDocInfoRef = db.collection('filter_docs').doc(thisFilterId);
           transaction.set(filterDocInfoRef, {
             'service_count' : FieldValue.increment(1),
           },SetOptions(merge: true));

           print('_______adding manager details______');

           DocumentReference docRef = FirebaseFirestore.instance.collection('manager_details').doc(id);
           transaction.set(docRef, {
             'name' : nameController.text,
             'email' : emailController.text,
             'phone' : phoneController.text,
             'location' : locationController.text,
             'opening_time' : formattedTime(selectedOpeningTime),
             'closing_time' : formattedTime(selectedClosingTime),
             'open' : true,
             'id' : id,
             'description' : descriptionController.text ?? 'No description',
             'client_count': totalClientCount,
             'first_client_index': firstClientIndex,
             'service_code': serviceCode,
             'time_data' : emptyList,
             'time_period' : durationValue * 60, //multiply by 60 to convert it to seconds
             //'prev_transition_time' : FieldValue.serverTimestamp(),
             ///this is the account creation bonus
             'account_balance' : _initialBonus ?? 0, //todo: might need to change it later
             'cost_per_client' : _costPerClient ?? 100 //todo: might need to change it later
           });
           debugPrint('_____successfully added manager details_______');

           transaction.update(managerInfoRef, {
             'manager_count': FieldValue.increment(1),
           });
           debugPrint('________transaction successfully completed___________');
         },
         timeout: Duration(seconds: 10));

       } catch (e) {
         debugPrint('$e');
         result = false;
       }
      return result;
     }

///Function to add the terminal details
  Future<bool> addTerminalDetails() async{
    bool result = false;
    try {
      await db.runTransaction( (transaction) async{
        String id = FirebaseAuth.instance.currentUser.uid;

        DocumentReference terminalInfoRef = db.collection('global_info').doc('terminal_info');
        var terminalCountDoc = await transaction.get(terminalInfoRef);
        if(terminalCountDoc.exists) {
          terminalCode = '${terminalCountDoc['terminal_count'] + 1}';
        }else {
          transaction.set(terminalInfoRef, {
            'terminal_count' : 0,
          });
          terminalCode = '1';
        }

        DocumentReference docRef = FirebaseFirestore.instance.collection('terminal_details').doc(id);
        transaction.set(docRef, {
          'name' : nameController.text,
          'id' : id,
          'terminal_code': terminalCode,
        });

        transaction.update(terminalInfoRef, {
          'terminal_count': FieldValue.increment(1),
        });

        result = true;
      },
      timeout: Duration(seconds: 10));
    }catch (e) {
      debugPrint('$e');
      result = false;
    }
return result;
  }

///function to select the account type there are two types of accounts the terminal and the manager account
  Widget selectAccountType() {
       return Container(
         color: Colors.white,
         child: Column(
           children: [
             Text(AppLocalizations.of(context).selectAccountType),
             Row(
               children: [
                 Expanded(
                   child: ListTile(
                     title: Text(AppLocalizations.of(context).manager),
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
                       title: Text(AppLocalizations.of(context).terminal),
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

///General function for the creation of an account
  Future<void> createManagerAccount() async{

    ///reset flags
    emailAlreadyInUse = false;
    weakPassword = false;
    passwordsDontMatch  = false;

       isProcessing = true;
      if(formKey.currentState.validate()) {
        if(passwordController.text == confirmPasswordController.text) {

          ///First check if the user has confirmed the information he has provided before proceeding
          var result = confirmDetails();
          if ((await result != null && await result == true) ) {

            try {

              ///try creating a account with a
              UserCredential userCredential = await FirebaseAuth.instance
                  .createUserWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text
              ).timeout(Duration(seconds: 10));

              if(await addManagerDetails()) {
                await Dialogs(context: context).createAccountSuccess(code: serviceCode);
                Navigator.pop(context);
              } else {
                final SnackBar msg = SnackBar(content: Text('Failed to Create account'), duration: Duration(seconds: 1)); //todo: translate
                ScaffoldMessenger.of(context).showSnackBar(msg);
                debugPrint('----unable to create account----');
              }
            } on TimeoutException catch(e) {
              debugPrint('$e');
              debugPrint('-----Timeout--------');
            } on FirebaseAuthException catch (e) {
              if (e.code == 'weak-password'){
                weakPassword = true;
                debugPrint('the password provided is too weak.');}
              else if (e.code == 'email-already-in-use') {
                emailAlreadyInUse = true;
                debugPrint('the account already exists for that email.');}
              ///revalidate
              formKey.currentState.validate();
            } catch (e) {
              debugPrint('$e');
            }

            var user = auth.currentUser;
            debugPrint('the user is: $user ');
            if(user != null) debugPrint('$user.email');
            if ( auth.currentUser != null) {
            }
          }
        } else {
          passwordsDontMatch = true;
          debugPrint('Passwords don\'t match');
          ///revalidate the form
          formKey.currentState.validate();
        }
      }
       isProcessing = false;
     }

  ///General function for the creation of a terminal account
  Future<void> createTerminalAccount() async{
    isProcessing = true;

    ///Reset the flags
    weakPassword = false;
    emailAlreadyInUse = false;

    if(formKey.currentState.validate()) {
      if(passwordController.text == confirmPasswordController.text) {
        isProcessing = true;
        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text
          ).timeout(Duration(seconds: 5));

          if(await addTerminalDetails()) {
            debugPrint('----successfully added the terminal details-----');
            await Dialogs(context: context).createAccountSuccess(code: terminalCode, isTerminal: true);
            Navigator.pop(context);
          }

        }on TimeoutException catch(e) {
          debugPrint('$e');
          debugPrint('----Login Timeout!!-----');

        } on FirebaseAuthException catch (e) {
          if (e.code == 'weak-password'){
            weakPassword = true;
            debugPrint('the password provided is too weak.');
          } else if (e.code == 'email-already-in-use') {
            emailAlreadyInUse = true;
            debugPrint('the account already exists for that email.');
          }

          formKey.currentState.validate();
        } catch (e) {
          debugPrint('$e');
        }

        var user = auth.currentUser;
        debugPrint('the user is: $user ');
        if(user != null) print(user.email);
        if ( auth.currentUser != null) {
        }
      } else debugPrint('Passwords don\'t match');
    }
    isProcessing = false;
  }

  ///Generate a scree that allows the user to confirm entries
  Future<bool> confirmDetails() async{
    var locale = AppLocalizations.of(context);
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Center(
              child: AutoSizeText('Please confirm the information you have provided', //todo: translate
                  maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue,
              )),
            ),
              content: Container(
                height: 0.7 * MediaQuery.of(context).size.height,
                width: 0.9 * MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        kfirmItem(label: locale.name, value: nameController.text, inUCase: true),
                        kfirmItem(label: locale.email, value: emailController.text),
                        kfirmItem(label: locale.password, value: passwordController.text),
                        kfirmItem(label: 'Tel',  value: phoneController.text),
                        kfirmItem(label: 'Description', value: descriptionController.text),
                        kfirmItem(label: locale.location, value: locationController.text),
                        kfirmItem(label: 'Starts at', value: timeInLocaleFormat(selectedOpeningTime) ),
                        kfirmItem(label: 'Ends at', value: timeInLocaleFormat(selectedClosingTime) ),
                        kfirmItem(label: 'Duration Per Client' , value: '${durationValue}  minutes'),
                        kfirmItem(label: 'Region', value: Regions(context).regionsRef[regionValue], inUCase: true),
                        kfirmItem(label: 'Division', value: Divisions().div(Regions(context).regionsRef[regionValue])[divisionValue], inUCase: true),
                        kfirmItem(label: 'Sub Division', value: SubDivisions().subDiv(Divisions().div(Regions(context).regionsRef[regionValue])[divisionValue])[subDivisionValue], inUCase: true),
                        kfirmItem(label: 'serviceType', value: ServiceType(context).serviceTypeRef[serviceTypeValue]),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                                child: AutoSizeText('Back', //todo: translate
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.blue,
                                    )),
                                onPressed: () {
                                  Navigator.pop(context);
                                }
                            ),
                            TextButton(
                                child: AutoSizeText('Continue', //todo: Translate
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.blue,
                                    )),
                                onPressed: () {
                                  Navigator.pop(context, true);
                                }
                            )
                          ]
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ]
                    )
                  ),
                ),
              ),

          );
        }
    );
  }

     @override
     Widget build(BuildContext context) {
          return WillPopScope(
            onWillPop: ()async => (isProcessing) ? false : true,
            child: Scaffold(
                 appBar: AppBar(
                     backgroundColor: appColor,
                     title: AutoSizeText(AppLocalizations.of(context).createAccount,
                         maxLines: 1,
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
                             child: isManagerAccount ? SingleChildScrollView(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                        selectAccountType(),
                                        MyTextField(controller: nameController, labelText: AppLocalizations.of(context).name, validator: nameValidation, inputType: TextInputType.name),
                                        MyTextField(controller: emailController, labelText: AppLocalizations.of(context).email, hintText: AppLocalizations.of(context).enterValEmail, validator: emailValidation, inputType: TextInputType.emailAddress),
                                        MyTextField(controller: phoneController, labelText: 'Tel', validator: phoneValidation, hintText: 'Ex. 675749781', inputType: TextInputType.phone),
                                        MyTextField(controller: passwordController, labelText: AppLocalizations.of(context).pwd, hintText: AppLocalizations.of(context).enterPwd, obscureText: obscureText, validator: pwdValidation),
                                        MyTextField(controller: confirmPasswordController, labelText: AppLocalizations.of(context).confirmPwd, hintText: AppLocalizations.of(context).enterPwd, obscureText: obscureText,validator: pwdValidation),
                                        MyTextField(controller: locationController, labelText: AppLocalizations.of(context).location, hintText: AppLocalizations.of(context).preciseLocation, validator: locationValidation),
                                        MyTextField(controller: descriptionController, labelText: 'Description', hintText: '', validator: descriptionValidation),

                                     SizedBox(
                                           height: 10,
                                         ),
                                     timeField(),
                                     SizedBox(
                                       height: 20,
                                     ),
                                         AutoSizeText(
                                             AppLocalizations.of(context).clientDuration,
                                             maxLines: 1,
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
                                         AutoSizeText(
                                            AppLocalizations.of(context).selectRegion,
                                             maxLines: 1,
                                             style: TextStyle(
                                               color: Colors.black54,
                                               fontSize: 17
                                             )
                                         ),
                                         DropdownButton(
                                             items: Regions(context).dropdownMenuItems,
                                             value: regionValue,
                                             onChanged: (newVal) {
                                               if(regionValue != newVal){
                                                 setState((){
                                                   regionValue = newVal;
                                                   divisionValue = 0;
                                                   subDivisionValue = 0;
                                                 });
                                               }

                                             },
                                             hint: Text(AppLocalizations.of(context).selectRegion)
                                         ),
                                         SizedBox(
                                           height: 10,
                                         ),
                                         AutoSizeText(
                                             AppLocalizations.of(context).selectDiv,
                                             maxLines: 1,
                                             style: TextStyle(
                                               color: Colors.black54,
                                               fontSize: 17,
                                             )
                                         ),
                                         DropdownButton(
                                             items: Divisions().dropdownMenuItems(Regions(context).regionsRef[regionValue]) ,
                                             value: divisionValue,
                                             onChanged: (newVal) {
                                               if(divisionValue != newVal){
                                                 setState((){
                                                   divisionValue = newVal;
                                                   subDivisionValue = 0;
                                                 });
                                               }

                                             },
                                             hint: Text(AppLocalizations.of(context).selectDiv),
                                         ),
                                         SizedBox(
                                           height: 10,
                                         ),
                                         AutoSizeText(
                                             AppLocalizations.of(context).selectSubDiv,
                                             maxLines: 1,
                                             style: TextStyle(
                                               color: Colors.black54,
                                               fontSize: 17,
                                             )
                                         ),
                                         DropdownButton(
                                             items: SubDivisions().dropdownMenuItems(Divisions().div(Regions(context).regionsRef[regionValue])[divisionValue]),
                                             value: subDivisionValue,
                                             onChanged: (newVal) {
                                               if(subDivisionValue != newVal){
                                                 setState((){
                                                   subDivisionValue = newVal;
                                                 });
                                               }
                                             },
                                             hint: Text(AppLocalizations.of(context).selectSubDiv)
                                         ),
                                         SizedBox(
                                           height: 10,
                                         ),
                                         AutoSizeText(
                                             AppLocalizations.of(context).selectServiceType,
                                             maxLines: 1,
                                             style: TextStyle(
                                               color: Colors.black54,
                                               fontSize: 17,
                                             )
                                         ),
                                         DropdownButton(
                                             items: ServiceType(context).dropdownMenuItems,
                                             value: serviceTypeValue,
                                             onChanged: (newVal) {
                                               if(serviceTypeValue != newVal){
                                                 setState((){
                                                   serviceTypeValue = newVal;
                                                 });
                                               }
                                             },
                                             hint: Text(AppLocalizations.of(context).selectServiceType)
                                         ),
                                         SizedBox(
                                           height: 10,
                                         ),
                                          FlatButton(
                                            minWidth: MediaQuery.of(context).size.width,
                                            color: appColor,
                                            onPressed: () async{
                                              startLoading();
                                              ///make sure the app is up to date before proceeding
                                              if(await Dialogs(context: context).checkUpdatesDialog() == false) {
                                                stopLoading();
                                                return;
                                              }
                                                 //TODO: Add some authentication logic
                                                 await createManagerAccount();
                                              stopLoading();
                                            },
                                            child: Text(
                                                AppLocalizations.of(context).register,
                                                style: TextStyle(
                                                     color: Colors.white,
                                                )
                                            )),
                                        SizedBox(
                                             height: 20,
                                        )
                                   ]
                               ),
                             )
                          : ListView(
                                 children: [
                                   selectAccountType(),
                                   MyTextField(controller: nameController, labelText: AppLocalizations.of(context).name, validator: nameValidation,inputType: TextInputType.name),
                                   MyTextField(controller: emailController, labelText: AppLocalizations.of(context).email, hintText: AppLocalizations.of(context).enterValEmail, validator: emailValidation, inputType: TextInputType.emailAddress),
                                   MyTextField(controller: passwordController, labelText: AppLocalizations.of(context).pwd, hintText: AppLocalizations.of(context).enterPwd, obscureText: obscureText, validator: pwdValidation),
                                   MyTextField(controller: confirmPasswordController, labelText: AppLocalizations.of(context).confirmPwd, hintText: AppLocalizations.of(context).enterPwd, obscureText: obscureText,validator: pwdValidation),
                                   FlatButton(
                                       minWidth: MediaQuery.of(context).size.width,
                                       color: appColor,
                                       onPressed: () async{
                                         startLoading();
                                         ///make sure the app is up to date before proceeding
                                         if(await Dialogs(context: context).checkUpdatesDialog() == false) {
                                           stopLoading();
                                           return;}

                                         //TODO: Add some authentication logic
                                         ///Choose account creation callback based on the type of account selected
                                         isManagerAccount ? await createManagerAccount() : await createTerminalAccount();
                                         stopLoading();
                                       },
                                       child: AutoSizeText(
                                           AppLocalizations.of(context).register,
                                           maxLines: 1,
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
            ),
          );
     }
}
