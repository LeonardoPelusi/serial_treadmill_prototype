import 'a133_command_enums.dart';

abstract class A133Protocol {

  static List<int> formatOneParameterCmd({
       required A133CommandTypes commandType,
       required A133ParameterIndexTypes parameterIndex,
       num? value,
      }) {
    List<int> startFlag = [0xff];
    List<int> functionCode = [commandType.toFunctionCode()];
    List<int> paramIndex = [parameterIndex.toParameterIndex()];
    late List<int> parameterValueRaw;
    late List<int> parameterValueSplit;
    if (value != null) {
      parameterValueRaw = _getDataFormatted(
          value: value, multFactor: commandType.toMultiplicationFactor());
      parameterValueSplit = _splitCode(parameterValueRaw);
    } else {
      parameterValueSplit = [];
    }
    late List<int> checkSumRaw;
    if (value != null) {
      checkSumRaw = _getCrc([commandType.toFunctionCode(),
        parameterIndex.toParameterIndex()] + parameterValueRaw);
    } else {
      checkSumRaw = _getCrc([commandType.toFunctionCode(),
        parameterIndex.toParameterIndex()]);
    }
    List<int> checkSumSplit = _splitCode(checkSumRaw);
    List<int> stopFlag = _splitCode([0xfe]);

    List<int> finalData = startFlag + functionCode + paramIndex
        + parameterValueSplit + checkSumSplit + stopFlag;
    return finalData;
  }

  static List<int> formatControlCmd({
    required A133CommandTypes commandType,
    required A133InstructionTypes instructionType,
  }) {
    List<int> startFlag = [0xff];
    List<int> functionCode = [commandType.toFunctionCode()];
    List<int> paramIndex = [instructionType.toInstructionCode()];
    List<int> checkSumRaw = _getCrc([commandType.toFunctionCode(),
      instructionType.toInstructionCode()]);
    List<int> checkSumSplit = _splitCode(checkSumRaw);
    List<int> stopFlag = _splitCode([0xfe]);

    List<int> finalData = startFlag + functionCode + paramIndex
        + checkSumSplit + stopFlag;
    return finalData;
  }

  // formata os bytes referentes ao Data na escrita de comandos
  static List<int> _getDataFormatted(
      {required num value, required num multFactor}) {
    int convertedValue = (value * multFactor).round();

    int partOne = convertedValue >> 8 & 0xFF;
    int partTwo = convertedValue & 0xFF;

    return [partTwo, partOne];
  }

  // faz o split de comandos começando com 0xf para diferenciar dos comandos reservados
  static List<int> _splitCode(List<int> value) {
    final List<int> command = [];

    for (int hexNum in value) {
      if (hexNum >= 0xfd && hexNum <= 0xff) {
        int part1 = 0xfd;
        int part2 = hexNum - 0xfd;
        command.add(part1);
        command.add(part2);
      } else {
        command.add(hexNum);
      }
    }

    return command;
  }

  // calcula o CRC (check sum)
  static List<int> _getCrc(List<int> command) {
    int length = command.length;

    int regCRC = 0xffff;
    int index = 0;

    while (length > 0) {
      regCRC ^= command[index]++;

      for (int i = 0; i < 8; i++) {
        if (regCRC & 0x01 == 1) {
          regCRC = (regCRC >> 1) ^ 0x8408;
        } else {
          regCRC = regCRC >> 1;
        }
      }
      length--;
      index++;
    }
    return [regCRC & 0xFF, regCRC >> 8 & 0xFF];
  }
}