#include <SoftwareSerial.h>

SoftwareSerial bt(12, 13); // RX, TX

char sz[256];

long registers[] = {
 1234,
 2345,
 3456,
 4567 
};

unsigned long reportTime;

void setup() {
  randomSeed(analogRead(0));
  bt.begin(9600);
  reportTime = millis();
}

void loop() {
  delay(rand() % 1000);
  sendData();
}

void sendData() {
  int s = sprintf(sz, "{\"status\":\"%s\",\"registers\":[", "connected");
  bool first = true;
  int idx = 0;
  for (long& i : registers) {
    if (!first) {
      sz[s++] = ',';
    } else {
      first = false;
    }
    i += random(-10, 11);
    s += sprintf(sz + s, "{\"i\":%d,\"v\":%ld}", idx++, i);
  }
  sz[s++] = ']';
  s += sprintf(sz + s, ",\"time\":%ld", millis() - reportTime);
  sz[s++] = '}';
  sz[s] = 0;
  bt.println(sz);
  reportTime = millis();
}
