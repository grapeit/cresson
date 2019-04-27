#include <SoftwareSerial.h>
#include "kawa.h"
#include "led.h"
 
SoftwareSerial bt(12, 13); // RX, TX
Kawa kawa; // uses Serial so do not use it anywhere else (pins 0 and 1)
RgbLed led(4, 2, 3);

struct Register
{
  uint8_t id = 0;
  uint32_t value = 0;
  Register(uint8_t i) : id(i) { }
};

char currentStatus[32] { };
Register registers[] = {
    {4},  // Throttle Position Sensor 0x00D2 - 0x037A (depends on kill switch)
//    {5},  // Air Pressure
    {6},  // Engine Coolant Temperature (C) = (a - 48) / 1.6
//    {7},  // Intake Air Temperature
//    {8},  // ?
    {9},  // Engine RPM = (a * 100) + b
    {10}, // Battery (V) = a / 12.75
    {11}, // Gear Position = a (always 0 or 6 when not running)
    {12}  // Speed (km/h) = ((a * 100) + b) / 2
};

int fuelMap = 1;
int fuelMapPin = 10;

unsigned long cycle;
bool shouldRequest(uint8_t id) {
  if (!id) {
    return true;
  }
  if (id == 6) {
    return cycle % 2 != 0;
  }
  if (id == 10) {
    return cycle % 2 == 0;
  }
  return true;
}

unsigned long reportTime;
char sz[256];

void setup() {
  bt.begin(9600);
  pinMode(fuelMapPin, OUTPUT);
  setFuelMap();
  reportTime = millis();
  led.set(RgbLed::white);
}

void loop() {
  processInput();
  if (kawa.getLastError() != 0) {
    connectToBike();
  }
  if (kawa.getLastError() == 0) {
    requestRegisters();
  } else {
    led.set(RgbLed::red);
    delay(1000);
  }
}

void processInput() {
  if (!bt.available()) {
    return;
  }
  do {
    fuelMap = bt.read();
  } while (bt.available());
  setFuelMap();
}

void setFuelMap() {
  digitalWrite(fuelMapPin, fuelMap == 2 ? HIGH : LOW);
}

void connectToBike() {
  led.set(RgbLed::yellow);
  strcpy(currentStatus, "connecting to bike");
  sendData();
  delay(1000);
  if (kawa.initPulse()) {
    cycle = 0;
    strcpy(currentStatus, "bike is connected");
  } else {
    strcpy(currentStatus, "handshake failed");
  }
  sendData();
}

void requestRegisters() {
  led.set(RgbLed::green);
  uint8_t response[sizeof (Register::value)];
  ++cycle;
  for (auto& r : registers) {
    if (!shouldRequest(r.id)) {
      continue;
    }
    uint8_t l = kawa.requestRegister(r.id, response, sizeof response);
    if (kawa.getLastError() != 0) {
      break;
    }
    r.value = 0;
    for (int b = 0; b < l; ++b) {
      *((uint8_t*)&r.value + (l - b) - 1) = response[b];
    }
  }
  sendData();
}

void sendData() {
  led.set(RgbLed::blue);
  //NOTE: sending payload to `bt` in pieces will allow to decrease size of `sz` buffer 
  int s = sprintf(sz, "{\"status\":\"%s\",\"registers\":[", currentStatus);
  if (kawa.getLastError() == 0) {
    bool first = true;
    for (const auto& r : registers) {
      if (first) {
        first = false;
      } else {
        sz[s++] = ',';
      }
      s += sprintf(sz + s, "{\"i\":%hhu,\"v\":%lu}", r.id, r.value);
    }
  }
  sz[s++] = ']';
  s += sprintf(sz + s, ",\"lastError\":%d", kawa.getLastError());
  s += sprintf(sz + s, ",\"time\":%ld", millis() - reportTime);
  sz[s++] = '}';
  sz[s] = 0;
  led.set(RgbLed::purple);
  bt.println(sz);
  reportTime = millis();
}
