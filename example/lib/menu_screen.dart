import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:win_ble/win_ble.dart';

class MenuScreen extends StatefulWidget {
  final BleDevice device;
  const MenuScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final timeNotifier = ValueNotifier<int>(0);
  final countNotifier = ValueNotifier<double>(0);
  int time=0;
  bool timerStarted = false;
  late Timer timer;
  late BleDevice device;
  double count=0;
  bool connected = false;
  List<String> services = [];
  List<BleCharacteristic> characteristics = [];
  String result = "";
  String error = "none";
  late Future<List<int>> readData = Future.value([]);
  final _snackbarDuration = const Duration(milliseconds: 700);
  final service_ID="49535343-fe7d-4ae5-8fa9-9fafd205e455";
  final writeC="49535343-8841-43f4-a8d4-ecbe34729bb3";
  final readC="49535343-1e4d-4bd9-ba61-23c647249616";


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
          if (characteristic.uuid == writeC) {
            subsCribeToCharacteristic(
                widget.device.address,
                service_ID,
                writeC);
          }
        }
      }
      await writeCharacteristicWithDelays(
        widget.device.address,
        service_ID,
        writeC,
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
      _subandread();
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



    super.initState();
  }
  _subandread(){
    print(count);
    if (characteristics.isNotEmpty) {
      for (var characteristic in characteristics) {
        if (characteristic.uuid == readC) {
          subsCribeToCharacteristic(
              widget.device.address,
              service_ID,
              readC);
        }
      }
    }
    readCharacteristic(
        widget.device.address,
        service_ID,
        readC);
  }
  _reinitiated() async {

      try {
        await WinBle.unSubscribeFromCharacteristic(
            address: widget.device.address, serviceId: service_ID, characteristicId: readC);
        showSuccess("Unsubscribed Successfully");
        timeNotifier.value = time; // Update time
        countNotifier.value = count; // Update count

      } catch (e) {
        showError("UnSubscribeError : $e");
        setState(() {
          error = e.toString() + " Date ${DateTime.now()}";
        });
      }
  }

  _initiated(){
    device = widget.device;
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
          count = count+data.length;
          final str = data.map((e) => e.toRadixString(16).padLeft(2, "0")).toList();
          final flagsSet = Set.from(
              "c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,ca,cb,cc,cd,ce,cf,d0,d1".split(","));
          var bleData =
          str.map((s) => flagsSet.contains(s) ? '\n$s' : ' $s').join();
          iosink.write(bleData.toUpperCase());
          if (data.isNotEmpty) {
            if (!timerStarted) {
              // Start the timer only if it hasn't been started yet
              timerStarted = true;
              timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
                //print("Timer ticked");
                timeNotifier.value = time;
                time++;
              });
            }
          }
        });
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
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Center(child: Text("$count",style: TextStyle(fontWeight: FontWeight.bold,wordSpacing: 4,fontSize: 24),)),SizedBox(height: 50,width: 50,),Center(child: Text("$time",style: TextStyle(fontWeight: FontWeight.bold,wordSpacing: 4,fontSize: 18))),],),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: ElevatedButton(
                      onPressed: () {_initiated();},
                      child: Text("Connect"),
                    ),
                  ),
                  SizedBox(width: 20,),
                  Container(
                    child: ElevatedButton(
                      onPressed: () {
                        _reinitiated();
                      },
                      child: Text("unsubscribe"),
                    ),
                  ),
                  SizedBox(width: 20,),
                  Container(
                    child: ElevatedButton(
                      onPressed: () {
                        _subandread();
                      },
                      child: Text("re-read"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
