import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';

class MyTile extends StatelessWidget {
  final String title;
 final Function onTapCallback;
 final Widget trailing;
  MyTile({@required this.title, @required this.onTapCallback, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.all(
                color: appColor,
                width: 2
            )
        ),
        child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
              ],
            ),
            onTap: () async{
              await onTapCallback();
            },
          trailing: trailing ?? Container(child: Text(' ')),
        ),
      ),
    );
  }
}
