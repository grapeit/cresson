class Led
{
  char _pin;

public:
  Led(char p) : _pin(p) {
    pinMode(_pin, OUTPUT);
  }

  void on() {
    digitalWrite(_pin, HIGH);
  }

  void off() {
    digitalWrite(_pin, LOW);
  }

  void pwm(unsigned char v) {
    analogWrite(_pin, v);
  }
};

class RgbLed
{
  Led _r, _g, _b;

public:
  RgbLed(char r, char g, char b) : _r(r), _g(g), _b(b) { }

  void set(unsigned char r, unsigned char g, unsigned char b) {
    _r.pwm(r);
    _g.pwm(g);
    _b.pwm(b);
  }

  void set(unsigned long rgb) {
    set((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF);
  }

  enum Color : unsigned long {
    off    = 0x000000,
    white  = 0xFFFFFF,
    red    = 0xFF0000,
    green  = 0x00FF00,
    blue   = 0x0000FF,
    yellow = 0xAABB00,
    purple = 0x800080
  };
};
