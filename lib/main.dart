import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:no_queues_manager/screens/editing_screen.dart';
import 'package:no_queues_manager/screens/loading_page.dart';
import 'package:no_queues_manager/data/settings_data.dart';
import 'package:no_queues_manager/screens/my_clients_screen.dart';
import 'package:no_queues_manager/screens/my_terminals_screen.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_manager/screens/settings_screens.dart';
import 'package:no_queues_manager/screens/dashboard_screen.dart';
import 'package:no_queues_manager/screens/log_in_screen.dart';
import 'package:no_queues_manager/screens/sign_up_screen.dart';
import 'package:no_queues_manager/terminal/terminal_screen.dart';
import 'package:no_queues_manager/screens/select_language_screen.dart';
import 'package:no_queues_manager/l10n/l10n.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_manager/screens/my_routes_screen.dart';
import 'package:no_queues_manager/push_notification.dart';
import 'package:no_queues_manager/screens/help_screen.dart';
import 'package:no_queues_manager/screens/account_balance_screen.dart';
import 'package:upgrader/upgrader.dart';



String firebaseServerKey = 'AAAACKen0OE:APA91bFRtVLgOSvaJGwsGHRjEb9nYIIjm0VkdWO7Ft2Oie0swrSKNCuFWa2VAi_-NCHR23fBIIyoDUO8gq0RMC6tzXp2acVFkixywNE6epin_I0jH-DYjPRRV1e3F6CvZiAOOBZshISF';

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}

const bool isProduction = bool.fromEnvironment('dart.vm.product');

void main() async{

  ///this block is to disable debugPrint logs
  if(isProduction) {
    debugPrint = (String message, {int wrapWidth}) {};
  }

  HttpOverrides.global = new MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    PushNotificationService().initialize();
  }


  @override
  Widget build(BuildContext context) {
      return ChangeNotifierProvider<SettingsData>(
        create: (context) => SettingsData(),
        builder: (context, data) => MaterialApp(
          title: 'Digi-Q Client',
          theme: ThemeData(
            primarySwatch: appColor,
            primaryColor: appColor,
            backgroundColor: appColor,
          ),
          locale: Locale(Provider.of<SettingsData>(context).getAppLang),
          supportedLocales: L10n.all,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          routes: {
            '/' : (context) => LoadPage(),
            '/DashBoardScreen/MyClientsScreen' : (context) => MyClientsScreen(),
            '/DashBoardScreen/SettingsScreen' : (context) => SettingsScreen(),
            '/DashBoardScreen/MyTerminalsScreen' : (context) => MyTerminalsScreen(),
            '/DashBoardScreen' : (context) => DashBoard(),
            '/LogInScreen/SignUpScreen' : (context) => SignUpScreen(),
            '/LogInScreen' : (context) => LogInScreen(),
            '/TerminalScreen' : (context) => TerminalScreen(),
            '/ModifiedSelectLangScreen' : (context) => ModSelectLangScr(),
            '/SelectLangScreen' : (context) => SelectLangScr(),
            '/DashBoardScreen/MyRoutes' : (context) => MyRoutes(),
            '/DashBoardScreen/EditingScreen' : (context) => EditingScreen(),
            '/DashBoardScreen/HelpScreen' : (context) => HelpScreen(),
            '/DashBoardScreen/AccountBalanceScreen' : (context) => AccountBalanceScreen()

          },
          initialRoute: '/',
        ),
      );
  }
}
