import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'enums.dart';
import 'package:collection/collection.dart';

abstract class TreadmillProtocol {

  static List<int> writeDataToInverter(
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

  static List<int> readCommandToInverter({required ReadCommandType type}) {
    List<int> reqAndIns = [0xf6, type.toINS()];
    List<int> crc = _getCrc(type.toINS(), []);
    List<int> end = [0xf4];

    List<int> finalData = reqAndIns + crc + end;
    return finalData;
  }

  static List<int> _getDataFormatted({required num value, required num multFactor}) {
    int convertedValue = (value * multFactor).round();

    int partOne = convertedValue >> 8 & 0xFF;
    int partTwo = convertedValue & 0xFF;

    return [partOne, partTwo];
  }

  static List<int> _splitCode(List<int> value) {
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

  static List<int> _getCrc(int ins, List<int>? data) {
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

  static int _readDataFromInverter(
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

  static bool _confirmCRC(List<int> crcCalculated, List<int> crcFromInverter) {
    Function eq = const ListEquality().equals;
    if (eq(crcCalculated, crcFromInverter)) {
      return true;
    } else {
      return false;
    }
  }
}