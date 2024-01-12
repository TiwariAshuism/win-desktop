import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:win_ble/win_ble.dart';

import 'logger.dart';

class ConnectionScreen extends StatefulWidget {
  final BleDevice device;
  const ConnectionScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late BleDevice device;
  bool connected = false;
  List<BleCharacteristic> characteristics = [];
  final serviceID = "49535343-fe7d-4ae5-8fa9-9fafd205e455";
  final writeC = "49535343-8841-43f4-a8d4-ecbe34729bb3";
  final readC = "49535343-1e4d-4bd9-ba61-23c647249616";

  Future<void> establishConnection() async {
    device = widget.device;

    WinBle.connectionStreamOf(device.address).listen((connected) async {
      if (connected) {
        try {
          var services = await WinBle.discoverServices(device.address);
          Logger.info("message");
          for (var serviceID in services) {
            List<BleCharacteristic> bleCharacteristics =
                await WinBle.discoverCharacteristics(
                    address: device.address, serviceId: serviceID);
            characteristics.addAll(bleCharacteristics);
          }
          Logger.info("message");
          if (characteristics.isNotEmpty) {
            if (characteristics
                .any((characteristic) => (characteristic.uuid == writeC))) {
               WinBle.subscribeToCharacteristic(
                  address: device.address,
                  serviceId: serviceID,
                  characteristicId: writeC);
            }
            Logger.info("message");
            await _sendCommand([0x0B], 2);
            await _sendCommand([0xEB], 2);
            await _sendCommand([0x08], 2);
            await _sendCommand([0x00], 2);
          }

          String dir = Directory.current.path;
          String filePath = '$dir/values.txt';

          File file = File(filePath);
          final iosink = file.openWrite();
          final now = DateTime.now();
          var timeFormat = DateFormat("HH:mm:ss");
          String timePortion = timeFormat.format(now);
          iosink.write("${timePortion.toUpperCase()}\n");
          WinBle.characteristicValueStream.listen((event) {
            List<int> data = List<int>.from(event['value']);

            final str =
                data.map((e) => e.toRadixString(16).padLeft(2, "0")).toList();
            final flagsSet = Set.from(
                "c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,ca,cb,cc,cd,ce,cf,d0,d1,d2,d3,d4"
                    .split(","));
            var bleData =
                str.map((s) => flagsSet.contains(s) ? '\n$s' : ' $s').join();
            iosink.write(bleData.toUpperCase());
          });

          await WinBle.subscribeToCharacteristic(
              address: widget.device.address,
              serviceId: serviceID,
              characteristicId: readC);
        } catch (e) {
          print("Error discovering services/characteristics: $e");
        }
      }
    });
    await WinBle.connect(device.address);
  }

  Future<void> _sendCommand(List<int> data, int delay) async {
    await WinBle.write(
        address: device.address,
        service: serviceID,
        characteristic: writeC,
        data: Uint8List.fromList(data),
        writeWithResponse: true);
    Future.delayed(Duration(seconds: delay));
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: connected ? null : () async {
                establishConnection();
              },
              style: connected
                  ? ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.grey),
              )
                  : ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue[200]),

              ),
              child: Text(connected?'Connected':"Connect"),
            ),
            SizedBox(width: 10), // Add some space between buttons
            ElevatedButton(
              onPressed: () async {
                // Handle button tap
                Future.delayed(Duration(seconds: 10));
                await WinBle.write(
                    address: device.address,
                    service: serviceID,
                    characteristic: writeC,
                    data: Uint8List.fromList([0xAA]),
                    writeWithResponse: true);
              },
              child: Text('Start Streaming'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                await WinBle.write(
                    address: device.address,
                    service: serviceID,
                    characteristic: writeC,
                    data: Uint8List.fromList([0xFF]),
                    writeWithResponse: true);
              },
              child: Text('Stop Streaming'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                await WinBle.disconnect(widget.device.address);
              },
              child: Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
