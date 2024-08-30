import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// formatará os dados que serão enviados para o inversor da esteira.
// Os valores abaixo são fixados da seguinte forma:
// pctxd[0] e pctxd[1] - cabeçalho fixo
// pctxd[2] - comprimento dos dados, exceto header e tail. Para controles de comando, o tamanho é fixado nesse valor
// pctxd[3] - valor fixo para checar envio
// pctxd[4] - 0x01 representa envio para o upper control
// pctxd[5] - 0x02 define control instruction. É isso que define o comprimento como 22 (com header e tail)
// pctxd[6] - bit para especificar o tipo de comando (activation, speed, inclination or turn off)
// pctxd[7] e pctxd[8] - valor de velocidade, sendo [7] mais significativo e [8] menos significativo
// pctxd[9] - valor de inclinação (de 0 a 15)
// pctxd[10] - valor correspondente a corrente máxima
// pctxd[11] - bit fixo de verificação
// pctxd[12] - representa a inclinação máxima, que é 15
// pctxd[13] até pctxd[16] - 4 bits represent 32-bit rpm_measured_scale, which is represented as 0x000CB735 = 83333
// This value is calculated based on the number of discs. Light-sensing speed measurement is used
// pctxd[17] até pctxd[19] - This constant is used to calculate the actual speed under the condition of light or magnetic inductance
// pctxd[20] - checksum
// pctxd[21] - bit fixo de finalização do pacote
List<int> writeDataToInverter(
    {required num value, required WriteCommandType type}) {
  List<int> pctxdZeroAndOne = [0xf7, 0xf8];
  List<int> pctxdTwoToFive = [0x13, 0x01, 0x01, 0x02];
  List<int> pctxdSix = [type.bitCode()];
  List<int> pctxSevenAndEight = _speedValueFormatted(value: value, type: type);
  List<int> pctxdNine = [
    _inclinationValueFormatted(value: value.toInt(), type: type)
  ]; // para inclinação, deve ser sempre int (0-15)
  List<int> pctxdTenToNineteen = [0x82, 0x00, 0x0f, 0x00, 0x0c, 0xb7, 0x35, 0x00, 0x00, 0x00];
  // o valor abaixo será usado para o checksum. Ele exclui apenas o header e o tail
  List<int> mainData = pctxdTwoToFive + pctxdSix + pctxSevenAndEight +
      pctxdNine + pctxdTenToNineteen;
  // os bits abaixo terminam a sequência com o checksum e o bit de finalização
  List<int> pctxdTwentyAndTwentyOne = [
    _getCheckSum(previousValues: mainData), 0xfd
  ];
  // bytes que serão enviados para o inversor da esteira:
  List<int> finalData = pctxdZeroAndOne + mainData + pctxdTwentyAndTwentyOne;
  return finalData;
}

// retorna os campos de velocidade (pctxd[7] e pctxd[8])
// se o comando não for speed, deve retornar valores zerados
// o valor enviado é multiplicado por 350 (correspondente ao RPM ratio)
List<int> _speedValueFormatted(
    {required num value, required WriteCommandType type}) {
  if (type != WriteCommandType.speed) {
    return [0,0];
  }
  int convertedValue = (value * 350).round();
  int partOne = convertedValue >> 8 & 0xFF;
  int partTwo = convertedValue & 0xFF;
  return [partOne, partTwo];
}

// retorna o valor de inclinação pctxd[9]
// se o comando não for inclination, deve retornar zero
int _inclinationValueFormatted(
    {required int value, required WriteCommandType type}) {
  if (type != WriteCommandType.inclination) {
    return 0;
  }
  return value;
}

// o checksum será a soma de todos os outros dados, com exceção do header e do
// tail. O bit menos significativo será ignorado
int _getCheckSum({required List<int> previousValues}) {
  int sum = 0;
  for (var num in previousValues) {
    sum += num;
  }
  int partTwo = sum & 0xFF;
  return partTwo;
}

enum WriteCommandType {
  activateTreadmill,
  speed,
  inclination,
  turnOff
}

extension WriteCommandTypeToINS on WriteCommandType {
  int bitCode() {
    switch(this) {
      case WriteCommandType.activateTreadmill:
        return 0x01;
      case WriteCommandType.speed:
        return 0x04;
      case WriteCommandType.inclination:
        return 0x08;
      case WriteCommandType.turnOff:
        return 0x02;
    }
  }
}