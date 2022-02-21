
class MsgData {
  final String senderName;
  final String receiverName;
  final String receiverPhoneNumber;
  final String receiverDeviceToken;
  final int receiverInitialPosition;
  final double completionPercentage;
  final String receiverLanguage;
  final String receiverId;



  MsgData({this.senderName, this.receiverId, this.receiverName, this.receiverPhoneNumber,this.receiverDeviceToken, this.receiverInitialPosition, this.receiverLanguage, this.completionPercentage});


  String get body {
    if(receiverLanguage == 'en') return "From ${title.toUpperCase()}. \n\nDear $receiverName, \nYour completion percentage is ${100 * completionPercentage}% \nYour current Position is $currentPosition \n\n\nPlease Check the Digi-Q Client App for more details. Thanks ";
    else return "De ${title.toUpperCase()}. \n\n Cher $receiverName, \nVotre pourcentage d'achevement est de ${100 * completionPercentage}% \nVotre position actuel est le $currentPosition \n\n\nOuvrer l'application Digi-Q Client pour plus d'info. Merci";

  }

  String get title {
    return senderName;
  }


  int get currentPosition{
    return (receiverInitialPosition - completionPercentage * (receiverInitialPosition - 1)).ceil();
  }
}