#include <EEPROM.h>

const char fuelMapCommand[] = "map:";

class FuelMap {
  char _map = 0;
  char _pin = 0;
  int _address = 0;
  int _commandIndex = 0;

public:
  FuelMap(char pin, int address) : _pin(pin), _address(address) {
  
  }

  void setup() {
    _map = EEPROM.read(_address);
    pinMode(_pin, OUTPUT);
    set();
  }

  int get() const {
    return _map;
  }

  void input(char i) {
    if (fuelMapCommand[_commandIndex] == 0) {
      _map = i;
      _commandIndex = 0;
      set();
      save();
    } else if (fuelMapCommand[_commandIndex] == i) {
      ++_commandIndex;
    } else {
      _commandIndex = 0;
    }
  }

private:
  void set() {
    digitalWrite(_pin, _map == 2 ? HIGH : LOW);
  }

  void save() {
    if (EEPROM.read(_address) != _map) {
      EEPROM.write(_address, _map);
    }
  }
};
