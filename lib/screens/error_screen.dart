import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class ErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child:Text(
          AppLocalizations.of(context).applicationCrashMsg,
          style: TextStyle(
            color: Colors.white,
          )
        )
      )
    );
  }
}
