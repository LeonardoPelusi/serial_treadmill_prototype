enum WriteCommandType {
  speed,
  inclination
}

extension WriteCommandTypeToINS on WriteCommandType {
  int toINS() {
    switch(this) {
      case WriteCommandType.speed:
        return 0x90;
      case WriteCommandType.inclination:
        return 0x98;
    }
  }
}

extension CommandTypeToMultiFactor on WriteCommandType {
  num toMultiFactor() {
    switch(this) {
      case WriteCommandType.speed:
        return 1;
      case WriteCommandType.inclination:
        return 66.6;
    }
  }
}

enum ReadCommandType {
  speed,
  inclinationCMD,
  inclinationPOS
}

extension ReadCommandTypeToINS on ReadCommandType {
  int toINS() {
    switch(this) {
      case ReadCommandType.speed:
        return 0x10;
      case ReadCommandType.inclinationCMD:
        return 0x18;
      case ReadCommandType.inclinationPOS:
        return 0x19;
    }
  }
}

// para velocidade, usamos a mesma relação velocidadeXfrequência expressa
// no CommandTypeToMultiFactor on WriteCommandType
extension CommandTypeToDivideFactor on ReadCommandType {
  double toDivideFactor() {
    switch (this) {
      case ReadCommandType.speed:
        return 1;
      case ReadCommandType.inclinationCMD:
        return 66.6;
      case ReadCommandType.inclinationPOS:
        return 66.6;
    }
  }
}