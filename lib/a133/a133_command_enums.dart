
/// Function Code

enum A133CommandTypes {
  writeControlCommand, readControlCommand, 
  writeOneParam, readOneParam,
  writeMultipleParams, readMultipleParams
}

extension FunctionCode on A133CommandTypes {
  int toFunctionCode() {
    switch (this) {
      case A133CommandTypes.writeControlCommand:
        return 0x10;
      case A133CommandTypes.readControlCommand:
        return 0x11;
      case A133CommandTypes.writeOneParam:
        return 0x20;
      case A133CommandTypes.readOneParam:
        return 0x21;
      case A133CommandTypes.writeMultipleParams:
        return 0x40;
      case A133CommandTypes.readMultipleParams:
        return 0x41;
    }
  }
}

extension MultiplicationFactor on A133CommandTypes {
  int toMultiplicationFactor() {
    switch (this) {
      case A133CommandTypes.writeControlCommand:
      case A133CommandTypes.readControlCommand:
        return 1;
      case A133CommandTypes.writeOneParam:
      case A133CommandTypes.readOneParam:
      case A133CommandTypes.writeMultipleParams:
      case A133CommandTypes.readMultipleParams:
        return 10;
    }
  }
}


/// Instruction Code

enum A133InstructionTypes {
  stopTreadmill, startTreadmill,
  emergencyStop, calibrateIncline, clearSlaveErrors
}

extension InstructionCode on A133InstructionTypes {
  int toInstructionCode() {
    switch (this) {
      case A133InstructionTypes.stopTreadmill:
        return 0x00;
      case A133InstructionTypes.startTreadmill:
        return 0x01;
      case A133InstructionTypes.emergencyStop:
        return 0x20;
      case A133InstructionTypes.calibrateIncline:
        return 0x21;
      case A133InstructionTypes.clearSlaveErrors:
        return 0x24;
    }
  }
}


/// Parameter Index

enum A133ParameterIndexTypes {
  dataPacket, normalDataPacket,
  setSpeed, actualSpeed,
}

extension IndexParameter on A133ParameterIndexTypes {
  int toParameterIndex() {
    switch (this) {
      case A133ParameterIndexTypes.normalDataPacket:
        return 0x01;
      case A133ParameterIndexTypes.dataPacket:
        return 0x02;
      case A133ParameterIndexTypes.setSpeed:
        return 0x05;
      case A133ParameterIndexTypes.actualSpeed:
        return 0x06;
    }
  }
}