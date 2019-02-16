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
Register registers[] = { {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12} };

unsigned long reportTime;
char sz[512];

void setup() {
  bt.begin(9600);
  reportTime = millis();
  led.set(RgbLed::white);
}

void loop() {
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

void connectToBike() {
  led.set(RgbLed::yellow);
  strcpy(currentStatus, "connecting to bike");
  sendData();
  delay(1000);
  if (kawa.initPulse()) {
    strcpy(currentStatus, "bike is connected");
  } else {
    strcpy(currentStatus, "handshake failed");
  }
  sendData();
}

void requestRegisters() {
  led.set(RgbLed::green);
  uint8_t response[sizeof (Register::value)];
  for (auto& r : registers) {
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
