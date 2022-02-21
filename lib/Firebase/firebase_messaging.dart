// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'dart:io' show Platform;
//
// final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//
// Future<void> _handleNotification (Map<dynamic, dynamic> message, bool dialog) async {
//   var data = message['data'] ?? message;
//   String expectedAttribute = data['expectedAttribute'];
//   /// [...]
// }
//
// // Replace with server token from firebase console settings.
// final String serverToken = '<Server-Token>';
// final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
//
// Future<Map<String, dynamic>> sendAndRetrieveMessage() async {
//   // await firebaseMessaging.requestNotificationPermissions(
//   //   const IosNotificationSettings(sound: true, badge: true, alert: true, provisional: false),
//   // );
//   if (Platform.isIOS) {
//     _firebaseMessaging.requestPermission(sound: true, badge: true, alert: true, provisional: false);
//   }
//
//
// //   await http.post(
// //     'https://fcm.googleapis.com/fcm/send',
// //     headers: <String, String>{
// //       'Content-Type': 'application/json',
// //       'Authorization': 'key=$serverToken',
// //     },
// //     body: jsonEncode(
// //       <String, dynamic>{
// //         'notification': <String, dynamic>{
// //           'body': 'this is a body',
// //           'title': 'this is a title'
// //         },
// //         'priority': 'high',
// //         'data': <String, dynamic>{
// //           'click_action': 'FLUTTER_NOTIFICATION_CLICK',
// //           'id': '1',
// //           'status': 'done'
// //         },
// //         'to': await firebaseMessaging.getToken(),
// //       },
// //     ),
// //   );
// //
// //   final Completer<Map<String, dynamic>> completer =
// //   Completer<Map<String, dynamic>>();
// //
// //   firebaseMessaging.configure(
// //     onMessage: (Map<String, dynamic> message) async {
// //       completer.complete(message);
// //     },
// //   );
// //
// //   return completer.future;
// // }