import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial_for_android/transaction.dart';
import 'package:usb_serial_for_android/usb_device.dart';
import 'package:usb_serial_for_android/usb_event.dart';
import 'package:usb_serial_for_android/usb_port.dart';
import 'package:usb_serial_for_android/usb_serial_for_android.dart';

//import 'main_two.dart';
import 'main_three.dart';

void main() => runApp(const MyApp());

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   _MyAppState createState() => Teste02();
// }
//
// class _MyAppState extends State<MyApp> {
//   UsbPort? _port;
//   String _status = "Idle";
//   List<Widget> _ports = [];
//   final List<Widget> _serialData = [];
//
//   StreamSubscription<Uint8List>? _subscription;
//   Transaction<Uint8List>? _transaction;
//   UsbDevice? _device;
//   final List<String> _hexCodeSent = [];
//
//   //final TextEditingController _textController = TextEditingController();
//
//   Future<bool> _connectTo(UsbDevice? device) async {
//     _serialData.clear();
//
//     if (_subscription != null) {
//       _subscription!.cancel();
//       _subscription = null;
//     }
//
//     if (_transaction != null) {
//       _transaction!.dispose();
//       _transaction = null;
//     }
//
//     if (_port != null) {
//       _port!.close();
//       _port = null;
//     }
//
//     if (device == null) {
//       _device = null;
//       setState(() {
//         _status = "Disconnected";
//       });
//       return true;
//     }
//
//     //_port = await device.create();
//     // You can customize your driver and the port number
//     _port = await device.create(UsbSerial.CH34x, 0);
//     if (await (_port!.open()) != true) {
//       setState(() {
//         _status = "Failed to open port";
//       });
//       return false;
//     }
//     _device = device;
//
//     await _port!.setDTR(true);
//     await _port!.setRTS(true);
//     await _port!.setPortParameters(
//         9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
//
//     await _port!.connect();
//
//     _transaction = Transaction.terminated(
//         _port?.inputStream as Stream<Uint8List>, Uint8List.fromList([0xfd]));
//
//     _subscription = _transaction!.stream.listen((Uint8List line) {
//       final List<String> hexLine = [];
//       for (var num in line) {
//         hexLine.add(num.toRadixString(16));
//       }
//       setState(() {
//         _serialData.add(Text('${hexLine.toString()}\n'));
//         if (_serialData.length > 20) {
//           _serialData.removeAt(0);
//         }
//       });
//     });
//
//     setState(() {
//       _status = "Connected";
//     });
//     return true;
//   }
//
//   void _getPorts() async {
//     _ports = [];
//     List<UsbDevice> devices = await UsbSerial.listDevices();
//     if (!devices.contains(_device)) {
//       _connectTo(null);
//     }
//
//     for (var device in devices) {
//       print('deviceId: ${device.deviceId} -- deviceName: ${device.deviceName} '
//           '-- interfaceCount: ${device.interfaceCount} -- manufacturerName: ${device.manufacturerName} '
//           '-- pid: ${device.pid} -- serial: ${device.serial} -- vid: ${device.vid}');
//       _ports.add(ListTile(
//           leading: const Icon(Icons.usb),
//           title: Text(device.productName ?? 'no ProductName specified'),
//           subtitle: Text(device.manufacturerName ?? 'no ManufactureName specified'),
//           trailing: ElevatedButton(
//             child: Text(_device == device ? "Disconnect" : "Connect"),
//             onPressed: () {
//               _connectTo(_device == device ? null : device).then((res) {
//                 _getPorts();
//               });
//             },
//           )));
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//
//     UsbSerial.usbEventStream!.listen((UsbEvent event) {
//       _getPorts();
//     });
//
//     _getPorts();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _connectTo(null);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         home: Scaffold(
//           appBar: AppBar(
//             title: const Text('USB Serial Plugin example app'),
//           ),
//           body: Center(
//               child: SingleChildScrollView(
//                 child: Column(
//                     children: <Widget>[
//                   Text(
//                       _ports.isNotEmpty
//                           ? "Available Serial Ports"
//                           : "No serial devices available",
//                       style: Theme.of(context).textTheme.headline6),
//                   ..._ports,
//                   Text('Status: $_status\n'),
//                   Text('info: ${_port.toString()}\n'),
//                   /*ListTile(
//                     title: TextField(
//                       controller: _textController,
//                       decoration: const InputDecoration(
//                         border: OutlineInputBorder(),
//                         labelText: 'Text To Send',
//                       ),
//                     ),
//                     trailing: ElevatedButton(
//                       onPressed: _port == null
//                           ? null
//                           : () async {
//                         if (_port == null) {
//                           return;
//                         }
//                         String data = "${_textController.text}\r\n";
//                         await _port!.write(Uint8List.fromList(data.codeUnits));
//                         _textController.text = "";
//                       },
//                       child: const Text("Send"),
//                     ),
//                   ), */
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 5),
//                     child: ElevatedButton(
//                       child: const Text('Initiate Treadmill'),
//                       onPressed: () async {
//                         final List<int> startTreadmill = [0xf7, 0xf8, 0x13, 0x01, 0x01, 0x02, 0x01, 0x01,
//                           0x5e, 0x00, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0x00, 0xfd];
//                         await _port?.write(Uint8List.fromList(startTreadmill));
//                         _dealWithHexSent(startTreadmill);
//                       },
//                     ),
//                   ),
//                       Container(
//                         margin: const EdgeInsets.symmetric(vertical: 5),
//                         child: ElevatedButton(
//                           child: const Text('Speed: 1km/h'),
//                           onPressed: () async {
//                             final List<int> OneKm = [0xf7, 0xf8, 0x13, 0x01, 0x01, 0x02, 0x04, 0x01, 0x5e,
//                               0x00, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0x03, 0xfd];
//                             await _port?.write(Uint8List.fromList(OneKm));
//                             _dealWithHexSent(OneKm);
//                           },
//                         ),
//                       ),
//                       Container(
//                         margin: const EdgeInsets.symmetric(vertical: 5),
//                         child: ElevatedButton(
//                           child: const Text('Speed: 2km/h'),
//                           onPressed: () async {
//                             final List<int> fiveKm = [0xf7, 0xf8, 0x13, 0x01, 0x01, 0x02, 0x04, 0x02, 0xbc,
//                               0x00, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0x62, 0xfd];
//                             await _port?.write(Uint8List.fromList(fiveKm));
//                             _dealWithHexSent(fiveKm);
//                           },
//                         ),
//                       ),
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 5),
//                     child: ElevatedButton(
//                       child: const Text('Speed: 5km/h'),
//                       onPressed: () async {
//                         final List<int> fiveKm = [0xf7, 0xf8, 0x13, 0x01, 0x01, 0x02, 0x04, 0x06, 0xd6,
//                           0x00, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0x80, 0xfd];
//                         await _port?.write(Uint8List.fromList(fiveKm));
//                         _dealWithHexSent(fiveKm);
//                       },
//                     ),
//                   ),
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 5),
//                     child: ElevatedButton(
//                       child: const Text('Speed 10km/h'),
//                       onPressed: () async {
//                         final List<int> tenKm = [0xf7, 0xf8, 0x13, 0x01, 0x01, 0x02, 0x04, 0xd, 0xac,
//                           0x00, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0x5d, 0xfd];
//                         await _port?.write(Uint8List.fromList(tenKm));
//                         _dealWithHexSent(tenKm);
//                       },
//                     ),
//                   ),
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 5),
//                     child: ElevatedButton(
//                       child: const Text('Inclination 02'),
//                       onPressed: ()  async {
//                         final List<int> twoIncl = [0xf7, 0xf8, 0x13, 0x01, 0x01, 0x02, 0x08, 0x02, 0xbc,
//                           0x02, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0x68, 0xfd];
//                         await _port?.write(Uint8List.fromList(twoIncl));
//                         _dealWithHexSent(twoIncl);
//                       },
//                     ),
//                   ),
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 5),
//                     child: ElevatedButton(
//                       child: const Text('Inclination 06'),
//                       onPressed: ()  async {
//                         final List<int> twoIncl = [0xf7, 0xf8, 0x13, 0x01, 0x01, 0x02, 0x08, 0x02, 0xbc,
//                           0x06, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0x6c, 0xfd];
//                         await _port?.write(Uint8List.fromList(twoIncl));
//                         _dealWithHexSent(twoIncl);
//                       },
//                     ),
//                   ),
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 5),
//                     child: ElevatedButton(
//                       child: const Text('Stop Treadmill 01'),
//                       onPressed: () async {
//                         final List<int> stopCommand = [0xf7, 0xf8, 0x13, 0x01, 0x02, 0x02, 0x02, 0x00, 0x00,
//                           0x00, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0xa3, 0xfd];
//                         await _port?.write(Uint8List.fromList(stopCommand));
//                         _dealWithHexSent(stopCommand);
//                       },
//                     ),
//                   ),
//                       Container(
//                         margin: const EdgeInsets.symmetric(vertical: 5),
//                         child: ElevatedButton(
//                           child: const Text('Stop Treadmill 02'),
//                           onPressed: () async {
//                             final List<int> stopCommand = [0xf7, 0xf8, 0x13, 0x01, 0x02, 0x02, 0x20, 0x00, 0x00,
//                               0x00, 0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00, 0xc1, 0xfd];
//                             await _port?.write(Uint8List.fromList(stopCommand));
//                             _dealWithHexSent(stopCommand);
//                           },
//                         ),
//                       ),
//                   Text('Command sent to treadmill: $_hexCodeSent'),
//                   const Text("Result Data"),
//                   ..._serialData,
//                 ]),
//               )),
//         ));
//   }
//
//   void _dealWithHexSent(final List<int> command) {
//     _hexCodeSent.clear();
//     for (var num in command) {
//       _hexCodeSent.add(num.toRadixString(16));
//     }
//     setState(() {});
//   }
// }