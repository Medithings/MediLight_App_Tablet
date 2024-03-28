import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultTile extends StatefulWidget {
  const ScanResultTile({Key? key, required this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback? onTap;

  @override
  State<ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<ScanResultTile> {
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.result.device.connectionState.listen((state) {
      _connectionState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]';
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    return data.entries
        .map((entry) => '${entry.key.toRadixString(16)}: ${getNiceHexArray(entry.value)}')
        .join(', ')
        .toUpperCase();
  }

  String getNiceServiceData(Map<Guid, List<int>> data) {
    return data.entries.map((v) => '${v.key}: ${getNiceHexArray(v.value)}').join(', ').toUpperCase();
  }

  String getNiceServiceUuids(List<Guid> serviceUuids) {
    return serviceUuids.join(', ').toUpperCase();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.result.device.platformName.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.result.device.platformName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 25,),
          ),
          // before:
          // Text(
          //   widget.result.device.remoteId.toString(),
          //   style: Theme.of(context).textTheme.bodySmall,
          // )
          // after: eliminate unnecessary info
        ],
      );
    } else {
      return Text(widget.result.device.remoteId.toString());
    }
  }

  // before: connect button exist
  // Widget _buildConnectButton(BuildContext context) {
  //   return ElevatedButton(
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Colors.black,
  //       foregroundColor: Colors.white,
  //     ),
  //     onPressed: (widget.result.advertisementData.connectable) ? widget.onTap : null,
  //     child: isConnected ? const Text('OPEN') : const Text('CONNECT'),
  //   );
  // }
  // after: eliminate

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var adv = widget.result.advertisementData;
    // before: no InkWell
    // after: wrap with InkWell
    return InkWell(
      onTap: (widget.result.advertisementData.connectable) ? widget.onTap : null,
      child: ListTile(
        title: _buildTitle(context),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20,),
          child: Text(widget.result.rssi.toString(), style: TextStyle(fontSize: 25,),),
        ),
        // before: trailing: _buildConnectButton(context),
        // after: no _buildConnectButton

        // before:
        // children: <Widget>[
        //   if (adv.advName.isNotEmpty) _buildAdvRow(context, 'Name', adv.advName),
        //   // before :
        //   // if (adv.txPowerLevel != null) _buildAdvRow(context, 'Tx Power Level', '${adv.txPowerLevel}'),
        //   // if (adv.manufacturerData.isNotEmpty)
        //   //   _buildAdvRow(context, 'Manufacturer Data', getNiceManufacturerData(adv.manufacturerData)),
        //   // if (adv.serviceUuids.isNotEmpty) _buildAdvRow(context, 'Service UUIDs', getNiceServiceUuids(adv.serviceUuids)),
        //   // if (adv.serviceData.isNotEmpty) _buildAdvRow(context, 'Service Data', getNiceServiceData(adv.serviceData)),
        //   // after : eliminate all the unnecessary info
        // ],
        // after: eliminate
      ),
    );
  }
}
