class Activator {
  const char*   _command;
  const char    _pin;
  const long    _duration;
  int           _commandIndex = 0;
  unsigned long _activated = 0;       

public:
  Activator(const char* command, char pin, long durationMs) : _command(command), _pin(pin), _duration(durationMs) { }

  void setup() {
    pinMode(_pin, OUTPUT);
    digitalWrite(_pin, LOW);
  }

  void input(char i) {
    if (_command[_commandIndex] == i) {
      ++_commandIndex;
    } else {
      _commandIndex = 0;
      return;
    }
    if (_command[_commandIndex] == 0) {
      _commandIndex = 0;
      _activated = millis();
      digitalWrite(_pin, HIGH);
    } 
  }

  void tick() {
    if (!_activated) {
      return;
    }
    unsigned long now = millis();
    if (now - _activated < _duration) {
      return;
    }
    _activated = 0;
    digitalWrite(_pin, LOW);
  }
};
