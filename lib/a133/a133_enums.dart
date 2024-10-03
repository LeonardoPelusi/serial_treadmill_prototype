
enum A133WriteCommandType { speed, inclination }

extension FunctionCode on A133WriteCommandType {
  int toFunctionCode() {
    switch (this) {
      case A133WriteCommandType.speed:
      case A133WriteCommandType.inclination:
        return 0x20;
    }
  }
}

extension ParameterIndex on A133WriteCommandType {
  int toParameterIndex() {
    switch (this) {
      case A133WriteCommandType.speed:
        return 0x05;
      case A133WriteCommandType.inclination:
        return 0x98;
    }
  }
}

extension CommandTypeToMultiFactor on A133WriteCommandType {
  num toMultiFactor() {
    switch (this) {
      case A133WriteCommandType.speed:
        return 10.0;
      case A133WriteCommandType.inclination:
        return 53.3;
    }
  }
}

enum A133ReadCommandType { speed, inclinationCMD, inclinationPOS }

extension ReadCommandTypeToINS on A133ReadCommandType {
  int toReadINS() {
    switch (this) {
      case A133ReadCommandType.speed:
        return 0x21;
      case A133ReadCommandType.inclinationCMD:
        return 0x18;
      case A133ReadCommandType.inclinationPOS:
        return 0x19;
    }
  }
}

extension ReadCommandTypeToIndexParam on A133ReadCommandType {
  int toIndexParam() {
    switch (this) {
      case A133ReadCommandType.speed:
        return 0x05;
      case A133ReadCommandType.inclinationCMD:
        return 0x98;
      case A133ReadCommandType.inclinationPOS:
        return 0x98;
    }
  }
}
