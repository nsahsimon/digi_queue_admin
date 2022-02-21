import 'package:flutter/material.dart';
import 'package:no_queues_manager/constants.dart';
import 'package:no_queues_manager/terminal/service_tile.dart';
import 'package:no_queues_manager/terminal/service_data.dart';


class ServiceTile extends StatefulWidget {
  final ServiceData serviceData;
  final Function onTapCallback;
      ServiceTile({this.serviceData, this.onTapCallback});
  @override
  _ServiceTileState createState() => _ServiceTileState();
}

class _ServiceTileState extends State<ServiceTile> {
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
              Text(widget.serviceData.name),
            ],
          ),
          onTap: () async{
            await widget.onTapCallback(widget.serviceData.id);
          }
        ),
      ),
    );
  }
}

