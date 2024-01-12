import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:win_ble/win_ble.dart';

class DeviceConnected extends StatefulWidget {
  final BleDevice device;
  const DeviceConnected({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceConnected> createState() => _DeviceConnectedState();
}

class _DeviceConnectedState extends State<DeviceConnected> {
  late BleDevice device;

  bool connected = false;
  List<String> services = [];
  List<BleCharacteristic> characteristics = [];
  String result = "";
  String error = "none";
  late Future<List<int>> readData = Future.value([]);
  final _snackbarDuration = const Duration(milliseconds: 700);

  void showSuccess(String value) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value),
          backgroundColor: Colors.green,
          duration: _snackbarDuration));

  void showError(String value) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value),
          backgroundColor: Colors.red,
          duration: _snackbarDuration));

  void showNotification(String value) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value),
          backgroundColor: Colors.blue,
          duration: _snackbarDuration));

  connect(String address) async {
    try {
      await WinBle.connect(address);
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  disconnect(address) async {
    try {
      await WinBle.disconnect(address);
      showSuccess("Disconnected");
    } catch (e) {
      if (!mounted) return;
      showError(e.toString());
    }
  }

  discoverServices(address) async {
    try {
      var data = await WinBle.discoverServices(address);
      setState(() {
        services = data;
      });
      if (services.isNotEmpty) {
        for (var service in services) {
          discoverCharacteristic(device.address, service);
        }
      }
      if (characteristics.isNotEmpty) {
        for (var characteristic in characteristics) {
          if (characteristic.uuid == "49535343-8841-43f4-a8d4-ecbe34729bb3") {
            subsCribeToCharacteristic(
                widget.device.address,
                "49535343-fe7d-4ae5-8fa9-9fafd205e455",
                "49535343-8841-43f4-a8d4-ecbe34729bb3");
          }
        }
      }
      await writeCharacteristicWithDelays(
        widget.device.address,
        "49535343-fe7d-4ae5-8fa9-9fafd205e455",
        "49535343-8841-43f4-a8d4-ecbe34729bb3",
        [
          [0x0B],
          [0xEB],
          [0x08],
          [0x00],
          [0xAA],
        ],
        [
          Duration(seconds: 2),
          Duration(seconds: 2),
          Duration(seconds: 2),
          Duration(seconds: 2),
          Duration(seconds: 10),
        ],
      );
    } catch (e) {
      showError("DiscoverServiceError : $e");
      setState(() {
        error = e.toString();
      });
    }
  }

  discoverCharacteristic(address, serviceID) async {
    try {
      List<BleCharacteristic> bleChar = await WinBle.discoverCharacteristics(
          address: address, serviceId: serviceID);

      setState(() {
        characteristics = bleChar;
      });
    } catch (e) {
      showError("DiscoverCharError : $e");
      setState(() {
        error = e.toString();
      });
    }
  }

  readCharacteristic(address, serviceID, charID) async {
    try {
      List<int> data = await WinBle.read(
          address: address, serviceId: serviceID, characteristicId: charID);

    } catch (e) {
      showError("ReadCharError : $e");
      setState(() {
        error = e.toString();
      });
      return [];
    }
  }

  writeCharacteristicWithDelays(String address, String serviceID, String charID,
      List<List<int>> dataList, List<Duration> delays) async {
    try {
      for (int i = 0; i < dataList.length; i++) {
        await WinBle.write(
          address: address,
          service: serviceID,
          characteristic: charID,
          data: Uint8List.fromList(dataList[i]),
          writeWithResponse: true,
        );
        await Future.delayed(delays[i]);
      }
      if (characteristics.isNotEmpty) {
        for (var characteristic in characteristics) {
          if (characteristic.uuid == "49535343-1e4d-4bd9-ba61-23c647249616") {
            subsCribeToCharacteristic(
                widget.device.address,
                "49535343-fe7d-4ae5-8fa9-9fafd205e455",
                "49535343-1e4d-4bd9-ba61-23c647249616");
          }
        }
      }
      readCharacteristic(
          widget.device.address,
          "49535343-fe7d-4ae5-8fa9-9fafd205e455",
          "49535343-1e4d-4bd9-ba61-23c647249616");
    } catch (e) {
      showError("writeCharError : $e");
      setState(() {
        error = e.toString();
      });
    }
  }

  subsCribeToCharacteristic(address, serviceID, charID) async {
    try {
      await WinBle.subscribeToCharacteristic(
          address: address, serviceId: serviceID, characteristicId: charID);
      showSuccess("Subscribe Successfully");
    } catch (e) {
      showError("SubscribeCharError : $e");
      setState(() {
        error = e.toString() + " Date ${DateTime.now()}";
      });
    }
  }

  StreamSubscription? _connectionStream;
  StreamSubscription? _characteristicValueStream;
  @override
  void initState() {
    device = widget.device;

    _connectionStream =
        WinBle.connectionStreamOf(device.address).listen((event) {
      setState(() {
        connected = event;
      });
      showSuccess("Connected : $event");

      if (connected) {
        discoverServices(device.address);
      }
    });

    connect(device.address);

    String dir = Directory.current.path;

    String filePath = '$dir/values.txt';

    File file = File(filePath);
    final iosink = file.openWrite();
    final now = DateTime.now();
    var timeFormat = DateFormat("HH:mm:ss");
    String timePortion = timeFormat.format(now);
    iosink.write("${timePortion.toUpperCase()}\n");

    _characteristicValueStream =
        WinBle.characteristicValueStream.listen((event) {
          List<int> data = List<int>.from(event['value']);
          final str = data.map((e) => e.toRadixString(16).padLeft(2, "0")).toList();
          final flagsSet = Set.from("c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,ca,cb,cc,cd,ce,cf,d0,d1".split(","));
          var bleData = str.map((s) => flagsSet.contains(s) ? '\n$s' : ' $s').join();
          iosink.write(bleData.toUpperCase());
        });

    super.initState();
  }

  @override
  void dispose() {
    _connectionStream?.cancel();
    _characteristicValueStream?.cancel();
    disconnect(device.address);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<int>>(
        future: readData,
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const CircularProgressIndicator();

            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}"),
                );
              }

              List<int> data = snapshot.data ?? [];

              return Column(
                children: [
                  const Text("Read Data:"),
                  for (int value in data) Text(value.toString()),
                ],
              );

            default:
              return Container();
          }
        },
      ),
    );
  }
}
