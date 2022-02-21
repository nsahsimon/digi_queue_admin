import 'package:cloud_firestore/cloud_firestore.dart';

//A convenient datatype to hold information about a service
class ServiceData {
  final QueryDocumentSnapshot snapshot;
  final DocumentSnapshot dSnapshot;
  final bool isModified; // this variable tells us that this queue contains more information than usual e.g client index , initial position.

  //this initialization is so that the queue can accommodate a variety of dataTypes
  ServiceData({this.snapshot, this.dSnapshot, this.isModified = false});

  String get name {

    return (snapshot != null) ? snapshot['name'] : dSnapshot['name'];
  }


  String get location {
    return (snapshot != null) ? snapshot['location'] : dSnapshot['location'];
  }


  bool get open {
    return (snapshot != null) ? snapshot['open'] : dSnapshot['open'];
  }

  String get id {
    return (snapshot != null) ? snapshot['id'] : dSnapshot['id'];
  }

  String get openingTime {
    return (snapshot != null) ? snapshot['opening_time'] : dSnapshot['opening_time'];
  }

  String get closingTime {
    return (snapshot != null) ? snapshot['closing_time'] : dSnapshot['closing_time'];
  }


  int get clientIndex {
    if(isModified){
      return (snapshot != null) ? snapshot['client_index'] : dSnapshot['client_index'];
    }else return -1;
  }

  int get initialPosition {
    if(isModified) {
      return (snapshot != null) ? snapshot['initial_position'] : dSnapshot['initial_position'];
    }else return -1 ;
  }

// ModifiedQueue generateModQueue({Queue queue, int tclientIndex, int initialPosition}) {
//   return ModifiedQueue(tqueue: queue, tclientIndex: tclientIndex, tinitialPosition: initialPosition, generatedFromQueue: true);
// }
//add more properties if necessary
}

