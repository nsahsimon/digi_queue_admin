import 'package:flutter/material.dart';


class ManagerDetails extends ChangeNotifier {
  String name;
  String location;
  String email;
  String startTime;
  String stopTime;
  String description;
  String password;
  String phone;


  String get getLocation {
    return location;
  }

  set setLocation(String newValue) {
    location = newValue;
    notifyListeners();
  }


    String get getName {
      return name;
    }

    void setName(String newValue) {
      name = newValue;
      notifyListeners();
    }


    String get getEmail {
      return email;
    }

    set setEmail(String newValue) {
      email = newValue;
      notifyListeners();
    }

    String get getDescription {
      return description;
    }

    set setDescription(String newValue) {
      description = newValue;
      notifyListeners();
    }

    String get getStartTime {
      return startTime;
    }

    set setStartTime(String newValue) {
      startTime = newValue;
      notifyListeners();
    }

    String get getStopTime {
      return stopTime;
    }

    set setStopTime(String newValue) {
      stopTime = newValue;
      notifyListeners();
    }

    String get getPassword {
      return password;
    }

    set setPassword(String newValue) {
      password = newValue;
      notifyListeners();
    }

    String get getPhone {
      return phone;
    }

    set setPhone(String newValue) {
      phone = newValue;
      notifyListeners();
    }






  }