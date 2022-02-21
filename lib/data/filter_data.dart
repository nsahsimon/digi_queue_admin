import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
List<DropdownMenuItem> genDDMenuItems (List<String> itemNames){
  List<DropdownMenuItem> result = [];
  debugPrint('-----$itemNames----');
  int count = itemNames.length;
  for(int i = 0; i < count; i++){
    result.add(
        DropdownMenuItem(
          child: Text(
            itemNames[i],
          ),
          value: i,
        )
    );
    print('-----${i}th dropdownItem was created--------w');
  }
  print('-------number of generated dropdowm menu items = ${result.length}-------');
  return result;
}

class FilterCat {

  List<String> _filterNames = [
    'Region',
    'Division',
    'Sub-Division',
    'Type of Service'
  ];

  List<String> get filterNames {
    return _filterNames;
  }

  List<DropdownMenuItem> get dropdownMenuItems {
    return genDDMenuItems(_filterNames);
  }

}

class Regions {
  final BuildContext context;
  Regions(this.context);
  List<String> _regions() => [
    AppLocalizations.of(context).nw,
    AppLocalizations.of(context).sw,
    AppLocalizations.of(context).we,
    AppLocalizations.of(context).es,
    AppLocalizations.of(context).fn,
    AppLocalizations.of(context).cn,
    AppLocalizations.of(context).lt,
    AppLocalizations.of(context).nt,
    AppLocalizations.of(context).ad,
    AppLocalizations.of(context).st,
  ];

  List<String> get regions {
    return _regions();
  }

  List<String> get regionsRef {
    return [
      "NORTH WEST",
      "SOUTH WEST",
       "WEST",
       "EAST",
      "FAR NORTH",
       "CENTER",
       "LITTORAL",
       "NORTH",
       "ADAMAWA",
        "SOUTH",
    ];
  }

  List<DropdownMenuItem> get dropdownMenuItems {
    return genDDMenuItems(_regions());
  }
}

class Divisions {
  Map<String, List<String>> _divisions = {
    'NORTH WEST' : ['NW-div1', 'NW-div2'],
    'SOUTH WEST' : ['SW-div1', 'SW-div2'],
    'WEST' : ['WE-div1', 'WE-div2'],
    'EAST' : ['ES-div1', 'ES-div2'],
    'FAR NORTH' : ['FN-div1', 'FN-div2'],
    'CENTER' : ['CE-div1', 'CE-div2'],
    'LITTORAL' : ['LT-div1', 'LT-div2'],
    'NORTH' : ['NT-div1', 'NT-div2'],
    'ADAMAWA' : ['AD-div1', 'AD-div2'],
    'SOUTH' : ['ST-div1', 'ST-div2'],
  };

  List<String> div(String key) {
    return _divisions[key];
  }

  List<DropdownMenuItem> dropdownMenuItems(String key) {
    return genDDMenuItems(_divisions[key]);
  }
}


class SubDivisions {
  Map<String, List<String>> subDivisions = {
    'NW-div1' : ['NW-div1-SD1', 'NW-div1-SD2'],
    'NW-div2' : ['NW-div2-SD1', 'NW-div2-SD2'],
    'WE-div1' : ['WE-div1-SD1', 'WE-div1-SD2'],
    'WE-div2' : ['WE-div2-SD1', 'WE-div2-SD2'],
    'FN-div1' : ['FN-div1-SD1', 'FN-div1-SD2'],
    'FN-div2' : ['FN-div2-SD1', 'FN-div2-SD2'],
    'CE-div1' : ['CE-div1-SD1', 'CE-div1-SD2'],
    'CE-div2' : ['CE-div2-SD1', 'CE-div2-SD2'],
    'AD-div1' : ['AD-div1-SD1', 'AD-div1-SD2'],
    'AD-div2' : ['AD-div2-SD1', 'AD-div2-SD2'],
    'SW-div1' : ['SW-div1-SD1', 'SW-div1-SD2'],
    'SW-div2' : ['SW-div2-SD1', 'SW-div2-SD2'],
    'ES-div1' : ['ES-div1-SD1', 'ES-div1-SD2'],
    'ES-div2' : ['ES-div2-SD1', 'ES-div2-SD2'],
    'LT-div1' : ['LT-div1-SD1', 'LT-div1-SD2'],
    'LT-div2' : ['LT-div2-SD1', 'LT-div2-SD2'],
    'NT-div1' : ['NT-div1-SD1', 'NT-div1-SD2'],
    'NT-div2' : ['NT-div2-SD1', 'NT-div2-SD2'],
    'ST-div1' : ['ST-div1-SD1', 'ST-div1-SD2'],
    'ST-div2' : ['ST-div2-SD1', 'ST-div2-SD2'],
  };

  List<String> subDiv(String key) {
    return subDivisions[key];
  }

  List<DropdownMenuItem> dropdownMenuItems(String key) {
    return genDDMenuItems(subDivisions[key]);
  }
}

class ServiceType {
  final BuildContext context;
  ServiceType(this.context);
  List<String> _serviceTypes() => [
    AppLocalizations.of(context).healthUnit,
    AppLocalizations.of(context).policeStation,
    AppLocalizations.of(context).pharmacy,
    AppLocalizations.of(context).bank,
    AppLocalizations.of(context).restaurant,
    AppLocalizations.of(context).shop,
    AppLocalizations.of(context).other,
  ];


  List<String> get serviceTypes {
    return _serviceTypes();
  }

  List<String> get serviceTypeRef {
    return [
      "HOSPITAL/HEALTH CENTER",
      "POLICE STATION",
      "PHARMACY",
      "BANK",
      "RESTAURANT",
      "SHOP",
      "OTHER"
    ];
  }

  List<DropdownMenuItem> get dropdownMenuItems {
    return genDDMenuItems(_serviceTypes());
  }
}