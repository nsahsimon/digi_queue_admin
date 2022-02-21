import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';


class SettingsTile extends StatefulWidget {
  final String name;
  final Function onChanged;
  final DropdownButton dropdownButton;
  final bool switchState;
  final bool useDropDB;
  final bool useSwitch;
  final Function onTap;

  SettingsTile({@required this.name, this.onChanged, this.switchState = false, this.dropdownButton, this.useDropDB = false, this.useSwitch = false, this.onTap});


  @override
  _SettingsTileState createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _switchState;

  @override
  void initState()
  {
    super.initState();
    _switchState  = widget.switchState;
  }
  void toggleSwitchState(bool value) {
    setState(() {
      _switchState = value;
    });
    widget.onChanged(value);
  }

  Widget trailing () {
    if(widget.useSwitch) {
      return Switch(
        value: _switchState,
        activeColor: appColor,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey,
        onChanged: toggleSwitchState,

      );
    }else if(widget.useDropDB) {
      return widget.dropdownButton;
    }else return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${widget.name}'),
      trailing: trailing(),
    );
  }
}
