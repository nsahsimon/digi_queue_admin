import 'package:flutter/cupertino.dart';
import 'package:no_queues_manager/my_widgets/settings_tile.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_manager/data/settings_data.dart';

  List<SettingsTile> options(BuildContext context) {
    List<SettingsTile> optionsToOutput = [];
    List<int> indexesToRemove = [];
    //this list contains all the settings options including those that would not be used always,
    List<Widget> _optionList = [
      SettingsTile(
        name: 'Send SMS',
        useSwitch: true,
        switchState: Provider.of<SettingsData>(context).getRingState,
        onChanged: (bool newValue) {
          Provider.of<SettingsData>(context, listen: false).setRingTo(newValue);
        },
      ),
      SettingsTile(
        name: 'Language',),
      // SettingsTile(
      //   name: 'Change Name',
      // ),
    ];

  // add the conditions for certain settings to appear
  //   if (!Provider.of<SettingsData>(context).getRingState)
  //     {
  //       indexesToRemove.add(1); //we add 1 since 1 is the index of the widget containing the 'Ring' setting option
  //     }

    for(var index = 0; index < _optionList.length; index++ ) {
      if(!(indexesToRemove.contains(index))) {
        optionsToOutput.add(_optionList[index]);
      }
    }
    return optionsToOutput;
  }
