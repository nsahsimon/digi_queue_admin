import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:no_queues_manager/models/messaging.dart';
import 'sms_api_key.dart' as SmsKey;

class SMSService {
  String _apiKey = SmsKey.apiKey;
  String _id;
  String get _sendUrl {
    return 'https://api.avlytext.com/v1/sms?api_key=$_apiKey';
  }

  String get _getStatusUrl{
    return 'https://api.avlytext.com/v1/sms/$_id?api_key=$_apiKey';
  }


  String suffix(String position){
    int _postion = int.parse(position);
    int lastDigit = _postion%10;
    switch (lastDigit) {
      case 1: return 'st';
      break;

      case 2: return 'nd';
      break;

      case 3: return 'rd';
      break;

      default:  return 'th';
      break;
    }
  }

  Future<bool> smsStatus() async{
    var request = http.Request('GET', Uri.parse(_getStatusUrl));


    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    }
    else {
    print(response.reasonPhrase);
    }
  }

  Future<bool> send(MsgData msgData) async{

    var headers = {
      'Content-Type': 'application/json'
    };
    var request = http.Request('POST', Uri.parse(_sendUrl));
    request.body = convert.json.encode({
      "sender": 'I-QUEUE-UP',
      "recipient":  '+237' + '${msgData.receiverPhoneNumber}',
      "text" : '${msgData.body}'    });
    request.headers.addAll(headers);

    try{
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String result = await response.stream.bytesToString();
        print(result);
        _id = convert.json.decode(result)['id'];

        print('-------message was sent-------');
        return true;
      }
      else {
        print(response.reasonPhrase);
        print('-------message was not sent-------');
        return false;
      }
    }catch(e) {
      print(e);
      print('-------message was not sent-------');
      return false;
    }
  }
}