import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:serial_to_usb_treadmill_prototype/RM6T6/treadmill_protocol.dart';
import 'enums.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SerialPort? _port;
  List<Widget> _ports = [];
  String _status = "Idle";

  final List<Widget> _serialData = [];
  final List<String> _hexCodeSent = [];

  late TextEditingController _textController;
  WriteCommandType commandType = WriteCommandType.speed;

  StreamSubscription<Uint8List>? _subscription;

  //final TextEditingController _textController = TextEditingController();

  Future<bool> _connectTo(SerialPort? port) async {
    _serialData.clear();

    if (_port != null) {
      _port!.close();
      _port = null;
    }
    if (port == null) {
      setState(() {
        _status = "Disconnected";
      });
      return true;
    }

    //_port = await device.create();
    // You can customize your driver and the port number
    _port = port;

    try {
      _port!.openReadWrite();

      _port!.config = SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);

      _listenToPort(_port!);
    } catch (_) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  void _listenToPort(SerialPort port) {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }

    SerialPortReader reader = SerialPortReader(port);
    

    _subscription = reader.stream.listen((data) {
      print("aqui a resposta: $data");

      List<String> hexResponse = [];
      for (var byte in data) {
        hexResponse.add(byte.toRadixString(16));
      }

      setState(() {
        _serialData.add(Text('$hexResponse\n'));
      });
    });
  }

  Future<void> _sendCommand(List<int>? dataToSend) async {
    print('entrei no send command');
    _port?.write(Uint8List.fromList(dataToSend!));
    _dealWithHexSent(dataToSend!);
  }

  void _getPorts() {
    _ports = [];

    if (!SerialPort.availablePorts.contains(_port?.name)) {
      _connectTo(null);
    }

    List<SerialPort> ports = [];

    for (var portName in SerialPort.availablePorts) {
      ports.add(SerialPort(portName));
    }

    for (var port in ports) {
      _ports.add(ListTile(
          leading: const Icon(Icons.usb),
          title: Text(port.name ?? 'no ProductName specified'),
          subtitle: Text(port.manufacturer ?? 'no ManufactureName specified'),
          trailing: ElevatedButton(
            child: Text(_port?.name == port.name ? "Disconnect" : "Connect"),
            onPressed: () {
              _connectTo(_port?.name == port.name ? null : port).then((res) {
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

    _getPorts();
  }

  @override
  void dispose() {
    _textController.dispose();
    _connectTo(null);
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('Serial Plugin example app'),
      ),
      body: Center(
          child: SingleChildScrollView(
        child: Column(children: <Widget>[
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
                _chooseCommandType(
                    'Choose Speed Command', WriteCommandType.speed),
                _chooseCommandType(
                    'Choose Inclination Command', WriteCommandType.inclination),
                _commandButton(
                    'Initiate Treadmill', [0xf6, 0xa0, 0x80, 0x10, 0x78, 0xf4]),
                _commandButton('Verify Error', [0xf6, 0x1a, 0x8b, 0x3e, 0xf4]),
                _commandButton('Read Speed', [0xf6, 0x10, 0x8c, 0xbe, 0xf4]),
                _commandButton(
                    'Illegal command', [0xf6, 0x00, 0x00, 0x00, 0xf4]),
                _commandButton('Stop command 0xff',
                    [0xf6, 0xa0, 0xff, 0xf7, 0x00, 0x39, 0xf4]),
                _commandButton(
                    'Stop command 0xc0', [0xf6, 0xa0, 0xc0, 0xe0, 0x79, 0xf4]),
                _commandButton(
                    'Stop command 0x00', [0xf6, 0xa0, 0x00, 0xb0, 0x79, 0xf4]),
                _commandButton('Encavalado', [
                  0xf6,
                  0x98,
                  0x00,
                  0x85,
                  0x8c,
                  0x31,
                  0xf4,
                  0xf6,
                  0x90,
                  0x09,
                  0x60,
                  0x95,
                  0x77,
                  0xf4,
                ]),
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
                            TreadmillProtocol.writeDataToInverter(
                                value: data, type: commandType);
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
          child: Text(title), onPressed: () async => commandType = type),
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
