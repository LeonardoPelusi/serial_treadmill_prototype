import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:serial_to_usb_treadmill_prototype/treadmill_protocol.dart';
import 'package:usb_serial_for_android/transaction.dart';
import 'package:usb_serial_for_android/usb_device.dart';
import 'package:usb_serial_for_android/usb_event.dart';
import 'package:usb_serial_for_android/usb_port.dart';
import 'package:usb_serial_for_android/usb_serial_for_android.dart';
import 'enums.dart';

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

  Transaction<Uint8List>? _transaction;
  UsbDevice? _device;
  final List<String> _hexCodeSent = [];
  late TextEditingController _textController;
  WriteCommandType commandType = WriteCommandType.speed;

  //final TextEditingController _textController = TextEditingController();

  Future<bool> _connectTo(UsbDevice? device) async {
    _serialData.clear();
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


    setState(() {
      _status = "Connected";
    });
    return true;
  }

  Future<void> _sendCommand(List<int>? dataToSend) async {
    print('entrei no send command');
    var response = await _transaction?.transaction(_port!, Uint8List
        .fromList(dataToSend!), const Duration(seconds: 1));
    print("aqui a resposta: $response");
    _dealWithHexSent(dataToSend!);
    setState(() {
      _serialData.add(Text('${response.toString()}\n'));
    });
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
                            _chooseCommandType('Choose Speed Command',
                                WriteCommandType.speed),
                            _chooseCommandType('Choose Inclination Command',
                                WriteCommandType.inclination),
                            _commandButton('Initiate Treadmill',
                                [0xf6, 0xa0, 0x80, 0x10, 0x78, 0xf4]),
                            _commandButton('Verify Error',
                                [0xf6, 0x1a, 0x8b, 0x3e, 0xf4]),
                            _commandButton('Read Speed',
                                [0xf6, 0x10, 0x8c, 0xbe, 0xf4]),
                            _commandButton('Illegal command',
                                [0xf6, 0x00, 0x00, 0x00, 0xf4]),
                            _commandButton('Stop command 0xff',
                                [0xf6, 0xa0, 0xff, 0xf7, 0x00, 0x39, 0xf4]),
                            _commandButton('Stop command 0xc0',
                                [0xf6, 0xa0, 0xc0, 0xe0, 0x79, 0xf4]),
                            _commandButton('Stop command 0x00',
                                [0xf6, 0xa0, 0x00, 0xb0, 0x79, 0xf4]),
                            _commandButton('Encavalado',
                                [0xf6, 0x98, 0x00, 0x85, 0x8c, 0x31, 0xf4,
                                  0xf6, 0x90, 0x09, 0x60, 0x95, 0x77, 0xf4,]),
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
                              TreadmillProtocol.writeDataToInverter(value: data, type: commandType);
                              await _sendCommand(dataToSend);
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

  Widget _commandButton(String title, List<int> command) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ElevatedButton(
        child: Text(title),
        onPressed: () async {
          await _sendCommand(command);
        },
      ),
    );
  }

  Widget _chooseCommandType(String title, WriteCommandType type) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        child: Text(title),
        onPressed: () async => commandType = type
      ),
    );
  }

  void _dealWithHexSent(final List<int> command) {
    _hexCodeSent.clear();
    for (var num in command) {
      _hexCodeSent.add(num.toRadixString(16));
    }
    setState(() {});
  }
}