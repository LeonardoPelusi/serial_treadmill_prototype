import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:serial_to_usb_treadmill_prototype/masks/text_mask.dart';
import 'package:usb_serial_for_android/transaction.dart';
import 'package:usb_serial_for_android/usb_device.dart';
import 'package:usb_serial_for_android/usb_event.dart';
import 'package:usb_serial_for_android/usb_port.dart';
import 'package:usb_serial_for_android/usb_serial_for_android.dart';
import 'a133_command_enums.dart';
import 'a133_protocol.dart';

class A133Screen extends StatefulWidget {
  const A133Screen({super.key});

  @override
  State<A133Screen> createState() => _A133ScreenState();
}

class _A133ScreenState extends State<A133Screen> {
  UsbPort? _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  final List<Widget> _serialData = [];
  final List<Widget> _base16Data = [];
  Transaction<Uint8List>? _transaction;
  UsbDevice? _device;

  final List<String> _hexCodeSent = [];
  late TextEditingController _textController;
  late TextEditingController _base16Controller;
  Timer? _normalPacketTimer;

  Future<bool> _connectTo(UsbDevice? device) async {
    _serialData.clear();
    _base16Data.clear();
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
        38400, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    await _port!.connect();

    _transaction = Transaction.terminated(
        _port?.inputStream as Stream<Uint8List>, Uint8List.fromList([0xfe]));

    setState(() {
      _status = "Connected";
    });
    await _initNormalPacketTimer();
    return true;
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
      {required bool isNormalPacket, bool isFromBase16 = false}) async {
    var response = await _transaction?.transaction(
        _port!, Uint8List.fromList(dataToSend!), const Duration(seconds: 1));

    if (isNormalPacket) return;

    _dealWithHexSent(dataToSend!);

    List<String> hexResponse = [];
    if (response != null) {
      for (var num in response) {
        hexResponse.add(num.toRadixString(16));
      }
    }
    setState(() {
      if (response != null) {
        if (isFromBase16) {
          _base16Data.add(Text('$hexResponse\n'));
        } else {
          _serialData.add(Text('$hexResponse\n'));
        }
      } else {
        if (isFromBase16) {
          _base16Data.add(Text('${response.toString()}\n'));
        } else {
          _serialData.add(Text('${response.toString()}\n'));
        }
      }
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
          subtitle:
              Text(device.manufacturerName ?? 'no ManufactureName specified'),
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
    _base16Controller = TextEditingController();
    UsbSerial.usbEventStream!.listen((UsbEvent event) {
      _getPorts();
    });

    _getPorts();
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
    _base16Controller.dispose();
    _normalPacketTimer?.cancel();
    _normalPacketTimer = null;
    _connectTo(null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('USB-Serial Communication Prototype'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
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
                                          commandType:
                                              A133CommandTypes.writeOneParam,
                                          parameterIndex:
                                              A133ParameterIndexTypes.setSpeed);
                                  await _sendCommand(dataToSend,
                                      isNormalPacket: false);
                                },
                          child: const Text("Send"),
                        ),
                      ),
                    ),
                    Text('Command sent to treadmill: $_hexCodeSent'),
                    const Text("Result Data"),
                    ..._serialData,
                  ],
                ),
                Column(
                  children: [
                    Text('Send value (Base 16)',
                        style: Theme.of(context).textTheme.headline6),
                    SizedBox(
                      width: 300,
                      child: ListTile(
                        title: TextField(
                          controller: _base16Controller,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'type value',
                          ),
                          inputFormatters: [
                            MaskedTextInputFormatter(
                                mask: 'xx xx xx xx xx xx xx xx', separator: ' '),
                          ],
                          onChanged: (value) => print('value: $value'),
                        ),
                        trailing: ElevatedButton(
                          onPressed: _port == null
                              ? null
                              : () async {
                                  if (_port == null) {
                                    return;
                                  }

                                  List<int> dataToSend = [];

                                  for (var text
                                      in _base16Controller.text.split(' ')) {
                                    dataToSend.add(int.parse('0x$text'));
                                  }

                                  await _sendCommand(dataToSend,
                                      isNormalPacket: false);
                                },
                          child: const Text("Send"),
                        ),
                      ),
                    ),
                    Text('Command sent to treadmill: $_hexCodeSent'),
                    const Text("Result Data"),
                    ..._base16Data,
                  ],
                ),
              ],
            ),
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
