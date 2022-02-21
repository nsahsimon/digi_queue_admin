import 'package:flutter/material.dart';


class PausedQueueScreen extends StatelessWidget {
  final Function toggleQueueStateCallback;
  PausedQueueScreen({@required this.toggleQueueStateCallback});
  
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 1,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: OutlinedButton.icon(
              icon: Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () async{
                await toggleQueueStateCallback();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.green
                )
              ),
              label: Text(
                'Resume',
                style: TextStyle(
                  color: Colors.green
                )
              )
            )
          )
        )
    );
  }
}
