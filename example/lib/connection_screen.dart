import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  int _countedData = 0;
  StreamController _countController = StreamController<int>();
  StreamController<bool> _connectController =
      StreamController<bool>.broadcast();
  StreamController<bool> _streamingDataController =
      StreamController<bool>.broadcast();
  bool _isStreaming = false;
  Future<void> establishConnection() async {
    device = widget.device;
    WinBle.connectionStreamOf(device.address).listen((connected) async {
      if (connected) {
        _connectController.sink.add(true);
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
            await _sendCommand([0x0B], 2);
            await _sendCommand([0xEB], 2);
            await _sendCommand([0x08], 2);
            await _sendCommand([0x00], 2);

          }
          final now = DateTime.now();
          var timeFormat = DateFormat("yyyyMMDDHHmmss");
          String timePortion = timeFormat.format(now);

          String dir = Directory.current.path;
          String folderPath =
              '$dir/received_data'; // Replace 'your_folder_name' with your desired folder name
          String filePath = '$folderPath/$timePortion.txt';

          Directory(folderPath)
              .create(recursive: true)
              .then((Directory directory) {
            File file = File(filePath);
            final iosink = file.openWrite();
            WinBle.characteristicValueStream.listen((event) {
              List<int> data = List<int>.from(event['value']);
              _countedData += data.length;
              final str =
                  data.map((e) => e.toRadixString(16).padLeft(2, "0")).toList();
              final flagsSet = Set.from(
                  // "c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,ca,cb,cc,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,da,db,dc"
                  "c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,ca,cb,cc,cd,ce,cf,d0,d1"
                      .split(","));
              var bleData =
                  str.map((s) => flagsSet.contains(s) ? '\n$s' : ' $s').join();
              iosink.write(bleData.toUpperCase());
            });
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
    await Future.delayed(Duration(seconds: delay));
  }

  @override
  void dispose() {
    _countController.close();
    WinBle.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Streaming : ".toUpperCase(),
                  style: TextStyle(fontSize: 39,fontWeight: FontWeight.bold),
                ),StreamBuilder<Object>(
                  stream: _streamingDataController.stream,
                  builder: (context, snapshot) {
                    if(snapshot.hasData){
                      return Text(
                        snapshot.data.toString().toUpperCase(),
                        style: TextStyle(fontSize: 39,fontWeight: FontWeight.bold,),
                      );
                    }
                    else
                      {
                        return Text(
                          false.toString(),
                          style: TextStyle(fontSize: 39,fontWeight: FontWeight.bold),
                        );
                      }
                  }
                )
              ],
            ),
            SizedBox(
              height: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder(
                    stream: _countController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.data.toString(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return Text(
                          "0",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    })
              ],
            ),
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (!connected) {
                      await establishConnection();
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      connected ? Colors.grey : Colors.blue[200],
                    ),
                  ),
                  child: StreamBuilder<bool>(
                    stream: _connectController.stream,
                    builder: (context, snapshot) {
                      return Text(
                          snapshot.data == true ? 'Connected' : 'Connect');
                    },
                  ),
                ),
                SizedBox(width: 10), // Add some space between buttons
                ElevatedButton(
                  onPressed: () async {
                    // Handle button tap
                    await Future.delayed(Duration(seconds: 10));
                    await WinBle.write(
                        address: device.address,
                        service: serviceID,
                        characteristic: writeC,
                        data: Uint8List.fromList([0xAA]),
                        writeWithResponse: true);
                    _streamingDataController.sink.add(true);
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
                    _countController.sink.add(_countedData);
                    _streamingDataController.sink.add(false);
                  },
                  child: Text('Stop Streaming'),
                ),

                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await WinBle.disconnect(widget.device.address);
                    _connectController.sink.add(false);
                  },
                  child: StreamBuilder<bool>(
                    stream: _connectController.stream,
                    builder: (context, snapshot) {
                      return Text(snapshot.data == true
                          ? 'Disconnect'
                          : 'disconnected');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
