import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'a133_command_enums.dart';
import 'a133_protocol.dart';

class A133Screen extends StatefulWidget {
  const A133Screen({super.key});

  @override
  State<A133Screen> createState() => _A133ScreenState();
}

class _A133ScreenState extends State<A133Screen> {
  SerialPort? _port;
  List<Widget> _ports = [];
  String _status = "Idle";

  final List<Widget> _serialData = [];
  final List<String> _hexCodeSent = [];

  late TextEditingController _textController;

  StreamSubscription<Uint8List>? _subscription;

  Timer? _normalPacketTimer;

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
      port.openReadWrite();

      port.config = SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);

      _listenToPort(port);
    } catch (_) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }

    setState(() {
      _status = "Connected";
    });
    await _initNormalPacketTimer();
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
      for (var num in data) {
        hexResponse.add(num.toRadixString(16));
      }
      setState(() {
        _serialData.add(Text('$hexResponse\n'));
      });
    });
  }

  Future<void> _initNormalPacketTimer() async {
    _normalPacketTimer?.cancel();
    _normalPacketTimer =
        Timer.periodic(const Duration(milliseconds: 150), (Timer t) async {
      List<int> normalDataPacket = [0xff, 0x41, 0x01, 0x8f, 0xbe, 0xfe];
      await _sendCommand(normalDataPacket, isNormalPacket: true);
    });
  }

  Future<void> _sendCommand(List<int>? dataToSend,
      {required bool isNormalPacket}) async {
    print('entrei no send command');
    _port?.write(Uint8List.fromList(dataToSend!));

    if (isNormalPacket) return;

    _dealWithHexSent(dataToSend!);
  }

  void _getPorts() {
    _ports = [];

    List<SerialPort> ports = [];

    for (var portName in SerialPort.availablePorts) {
      ports.add(SerialPort(portName));
    }

    if (!ports.contains(_port)) {
      _connectTo(null);
    }

    for (var port in ports) {
      _ports.add(ListTile(
          leading: const Icon(Icons.usb),
          title: Text(port.name ?? 'no ProductName specified'),
          subtitle: Text(port.manufacturer ?? 'no ManufactureName specified'),
          trailing: ElevatedButton(
            child: Text(port.isOpen ? "Disconnect" : "Connect"),
            onPressed: () {
              _connectTo(port.isOpen ? null : port).then((res) {
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
        title: const Text('Serial Communication Prototype'),
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
            const SizedBox(height: 40),
            Text('Connection Info:',
                style: Theme.of(context).textTheme.headline6),
            Text('Status: $_status\n'),
            Text('Details: ${_port.toString()}\n'),
            const SizedBox(height: 40),
            Text('Quick Commands:',
                style: Theme.of(context).textTheme.headline6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _controlCommandButton(
                      title: 'Start Operation',
                      commandType: A133CommandTypes.writeControlCommand,
                      instructionType: A133InstructionTypes.startTreadmill),
                  _controlCommandButton(
                      title: 'Stop Operation',
                      commandType: A133CommandTypes.writeControlCommand,
                      instructionType: A133InstructionTypes.stopTreadmill),
                  _controlCommandButton(
                      title: 'Emergency Stop',
                      commandType: A133CommandTypes.writeControlCommand,
                      instructionType: A133InstructionTypes.emergencyStop),
                  _oneParamButton(
                      title: 'Read Set Speed',
                      commandType: A133CommandTypes.readOneParam,
                      parameterIndex: A133ParameterIndexTypes.setSpeed),
                  _oneParamButton(
                      title: 'Read Actual Speed',
                      commandType: A133CommandTypes.readOneParam,
                      parameterIndex: A133ParameterIndexTypes.actualSpeed),
                  _oneParamButton(
                      title: 'Read Data Packet',
                      commandType: A133CommandTypes.readMultipleParams,
                      parameterIndex: A133ParameterIndexTypes.dataPacket),
                  _oneParamButton(
                      title: 'Read Normal Data Packet',
                      commandType: A133CommandTypes.readMultipleParams,
                      parameterIndex: A133ParameterIndexTypes.normalDataPacket),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text('Choose speed command in km/h:',
                style: Theme.of(context).textTheme.headline6),
            SizedBox(
              width: 300,
              child: ListTile(
                title: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'type speed',
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
                              A133Protocol.formatOneParameterCmd(
                                  value: data,
                                  commandType: A133CommandTypes.writeOneParam,
                                  parameterIndex:
                                      A133ParameterIndexTypes.setSpeed);
                          await _sendCommand(dataToSend, isNormalPacket: false);
                        },
                  child: const Text("Send"),
                ),
              ),
            ),
            Text('Command sent to treadmill: $_hexCodeSent'),
            const Text("Result Data"),
            ..._serialData,
          ]),
        ),
      ),
    ));
  }

  Widget _controlCommandButton({
    required String title,
    required A133CommandTypes commandType,
    required A133InstructionTypes instructionType,
  }) {
    List<int> command = A133Protocol.formatControlCmd(
      commandType: commandType,
      instructionType: instructionType,
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ElevatedButton(
        child: Text(title),
        onPressed: () async {
          await _sendCommand(command, isNormalPacket: false);
        },
      ),
    );
  }

  Widget _oneParamButton({
    required String title,
    required A133CommandTypes commandType,
    required A133ParameterIndexTypes parameterIndex,
    num? value,
  }) {
    List<int> command = A133Protocol.formatOneParameterCmd(
        commandType: commandType, parameterIndex: parameterIndex, value: value);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ElevatedButton(
        child: Text(title),
        onPressed: () async {
          await _sendCommand(command, isNormalPacket: false);
        },
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
