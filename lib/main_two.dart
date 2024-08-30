import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usb_serial_for_android/transaction.dart';
import 'package:usb_serial_for_android/usb_device.dart';
import 'package:usb_serial_for_android/usb_event.dart';
import 'package:usb_serial_for_android/usb_port.dart';
import 'package:usb_serial_for_android/usb_serial_for_android.dart';
import 'package:collection/collection.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UsbPort? _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  final List<Widget> _serialData = [];

  StreamSubscription<Uint8List>? _subscription;
  Transaction<Uint8List>? _transaction;
  UsbDevice? _device;
  final List<String> _hexCodeSent = [];
  late TextEditingController _textController;
  WriteCommandType commandType = WriteCommandType.speed;

  //final TextEditingController _textController = TextEditingController();

  Future<bool> _connectTo(UsbDevice? device) async {
    _serialData.clear();

    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction!.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port!.close();
      _port = null;
    }

    if (device == null) {
      _device = null;
      setState(() {
        _status = "Disconnected";
      });
      return true;
    }

    //_port = await device.create();
    // You can customize your driver and the port number
    _port = await device.create(UsbSerial.CH34x, 0);
    if (await (_port!.open()) != true) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }
    _device = device;

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
        9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    await _port!.connect();

    _transaction = Transaction.terminated(
        _port?.inputStream as Stream<Uint8List>, Uint8List.fromList([0xf4]));

    _subscription = _transaction!.stream.listen((Uint8List line) {
      final List<String> hexLine = [];
      for (var num in line) {
        hexLine.add(num.toRadixString(16));
      }
      print('aqui: $hexLine');
      setState(() {
        _serialData.add(Text('${hexLine.toString()}\n'));
      });
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  void _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (!devices.contains(_device)) {
      _connectTo(null);
    }

    for (var device in devices) {
      _ports.add(ListTile(
          leading: const Icon(Icons.usb),
          title: Text(device.productName ?? 'no ProductName specified'),
          subtitle: Text(device.manufacturerName ?? 'no ManufactureName specified'),
          trailing: ElevatedButton(
            child: Text(_device == device ? "Disconnect" : "Connect"),
            onPressed: () {
              _connectTo(_device == device ? null : device).then((res) {
                _getPorts();
              });
            },
          )));
    }
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    UsbSerial.usbEventStream!.listen((UsbEvent event) {
      _getPorts();
    });

    _getPorts();
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
    _connectTo(null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('USB Serial Plugin example app'),
          ),
          body: Center(
              child: SingleChildScrollView(
                child: Column(
                    children: <Widget>[
                      Text(
                          _ports.isNotEmpty
                              ? "Available Serial Ports"
                              : "No serial devices available",
                          style: Theme.of(context).textTheme.headline6),
                      ..._ports,
                      Text('Status: $_status\n'),
                      Text('info: ${_port.toString()}\n'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Initiate Treadmill'),
                                onPressed: () async {
                                  final List<int> startTreadmill = [0xf6, 0xa0, 0x80, 0x10, 0x78, 0xf4];
                                  await _port?.write(Uint8List.fromList(startTreadmill));
                                  _dealWithHexSent(startTreadmill);
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Verify Error'),
                                onPressed: () async {
                                  final List<int> startTreadmill = [0xf6, 0x1a, 0x8b, 0x3e, 0xf4];
                                  await _port?.write(Uint8List.fromList(startTreadmill));
                                  _dealWithHexSent(startTreadmill);
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Choose Speed Command'),
                                onPressed: () async {
                                  commandType = WriteCommandType.speed;
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Choose Inclination Command'),
                                onPressed: () async {
                                  commandType = WriteCommandType.inclination;
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Read Speed'),
                                onPressed: () async {
                                  final List<int> readSpeed = [0xf6, 0x10, 0x8c, 0xbe, 0xf4];
                                  await _port?.write(Uint8List.fromList(readSpeed));
                                  _dealWithHexSent(readSpeed);
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Illegal command'),
                                onPressed: () async {
                                  final List<int> readSpeed = [0xf6, 0x00, 0x00, 0x00, 0xf4];
                                  await _port?.write(Uint8List.fromList(readSpeed));
                                  _dealWithHexSent(readSpeed);
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Stop command 0xff'),
                                onPressed: () async {
                                  final List<int> startTreadmill = [0xf6, 0xa0, 0xff, 0xf7, 0x00, 0x39, 0xf4];
                                  await _port?.write(Uint8List.fromList(startTreadmill));
                                  _dealWithHexSent(startTreadmill);
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Stop command 0xc0'),
                                onPressed: () async {
                                  final List<int> startTreadmill = [0xf6, 0xa0, 0xc0, 0xe0, 0x79, 0xf4];
                                  await _port?.write(Uint8List.fromList(startTreadmill));
                                  _dealWithHexSent(startTreadmill);
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('Stop command 0x00'),
                                onPressed: () async {
                                  final List<int> startTreadmill = [0xf6, 0xa0, 0x00, 0xb0, 0x79, 0xf4];
                                  await _port?.write(Uint8List.fromList(startTreadmill));
                                  _dealWithHexSent(startTreadmill);
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ElevatedButton(
                                child: const Text('zerado'),
                                onPressed: () async {
                                  final List<int> startTreadmill = [0xf6, 0x90, 0x00, 0x01, 0x2d, 0xb0, 0xf4];
                                  await _port?.write(Uint8List.fromList(startTreadmill));
                                  _dealWithHexSent(startTreadmill);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: ListTile(
                          title: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Text To Send',
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: _port == null
                                ? null
                                : () async {
                              if (_port == null) {
                                return;
                              }

                              int data = int.parse(_textController.text);
                              List<int>? dataToSend =
                              writeDataToInverter(value: data, type: commandType);


                              await _port!.write(Uint8List.fromList(dataToSend));
                              _textController.text = "";
                              _dealWithHexSent(Uint8List.fromList(dataToSend));
                            },
                            child: const Text("Send"),
                          ),
                        ),
                      ),
                      Text('Command sent to treadmill: $_hexCodeSent'),
                      const Text("Result Data"),
                      ..._serialData,
                    ]),
              )),
        ));
  }

  void _dealWithHexSent(final List<int> command) {
    _hexCodeSent.clear();
    for (var num in command) {
      _hexCodeSent.add(num.toRadixString(16));
    }
    setState(() {});
  }
}


List<int> writeDataToInverter(
    {required num value, required WriteCommandType type}) {
  List<int> reqAndIns = [0xf6, type.toINS()];
  List<int> dataRaw =
  _getDataFormatted(value: value, multFactor: type.toMultiFactor());
  List<int> dataSplit = _splitCode(dataRaw);
  List<int> crcRaw = _getCrc(type.toINS(), dataRaw);
  List<int> crcSplit = _splitCode(crcRaw);
  List<int> end = [0xf4];

  List<int> finalData = reqAndIns + dataSplit + crcSplit + end;
  return finalData;
}

enum WriteCommandType {
  speed,
  inclination
}

extension WriteCommandTypeToINS on WriteCommandType {
  int toINS() {
    switch(this) {
      case WriteCommandType.speed:
        return 0x90;
      case WriteCommandType.inclination:
        return 0x98;
    }
  }
}

extension CommandTypeToMultiFactor on WriteCommandType {
  num toMultiFactor() {
    switch(this) {
      case WriteCommandType.speed:
        return 1;
      case WriteCommandType.inclination:
        return 66.6;
    }
  }
}

List<int> readCommandToInverter({required ReadCommandType type}) {
  List<int> reqAndIns = [0xf6, type.toINS()];
  List<int> crc = _getCrc(type.toINS(), []);
  List<int> end = [0xf4];

  List<int> finalData = reqAndIns + crc + end;
  return finalData;
}

List<int> _getDataFormatted({required num value, required num multFactor}) {
  int convertedValue = (value * multFactor).round();

  int partOne = convertedValue >> 8 & 0xFF;
  int partTwo = convertedValue & 0xFF;

  return [partOne, partTwo];
}

List<int> _splitCode(List<int> value) {
  final List<int> command = [];

  for (int hexNum in value) {
    if (hexNum >= 0xf0 && hexNum <= 0xff) {
      int part1 = 0xf7;
      int part2 = hexNum - 0xf0;
      command.add(part1);
      command.add(part2);
    } else {
      command.add(hexNum);
    }
  }

  return command;
}

List<int> _getCrc(int ins, List<int>? data) {
  List<int> command = [ins] + data!;

  int length = command.length;

  int regCRC = 0xffff;
  int index = 0;

  while (length > 0) {
    regCRC ^= command[index]++;

    for (int i = 0; i < 8; i++) {
      if (regCRC & 0x01 == 1) {
        regCRC = (regCRC >> 1) ^ 0xa001;
      } else {
        regCRC = regCRC >> 1;
      }
    }
    length--;
    index++;
  }
  return [regCRC >> 8 & 0xFF, regCRC & 0xFF];
}

int _readDataFromInverter(
    {required Uint8List answer, required ReadCommandType type}) {
  List<int> dataAndStu = [answer[2], answer[3], answer[4]];
  List<int> crcCalculated = _getCrc(answer[1], dataAndStu);
  List<int> crcfromInverter = [answer[5], answer[6]];

  bool canContinue = _confirmCRC(crcCalculated, crcfromInverter);

  if (canContinue) {
    String dataFormat =
        answer[2].toRadixString(16) + answer[3].toRadixString(16);
    int finalValue = int.parse(dataFormat, radix: 16);
    return (finalValue / type.toDivideFactor()).round();
  } else {
    debugPrint('bytes corrompidos');
    return 0;
  }
}

bool _confirmCRC(List<int> crcCalculated, List<int> crcFromInverter) {
  Function eq = const ListEquality().equals;
  if (eq(crcCalculated, crcFromInverter)) {
    return true;
  } else {
    return false;
  }
}

enum ReadCommandType {
  speed,
  inclinationCMD,
  inclinationPOS
}

extension ReadCommandTypeToINS on ReadCommandType {
  int toINS() {
    switch(this) {
      case ReadCommandType.speed:
        return 0x10;
      case ReadCommandType.inclinationCMD:
        return 0x18;
      case ReadCommandType.inclinationPOS:
        return 0x19;
    }
  }
}

// para velocidade, usamos a mesma relação velocidadeXfrequência expressa
// no CommandTypeToMultiFactor on WriteCommandType
extension CommandTypeToDivideFactor on ReadCommandType {
  double toDivideFactor() {
    switch (this) {
      case ReadCommandType.speed:
        return 1;
      case ReadCommandType.inclinationCMD:
        return 66.6;
      case ReadCommandType.inclinationPOS:
        return 66.6;
    }
  }
}