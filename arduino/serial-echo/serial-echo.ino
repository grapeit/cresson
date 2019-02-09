#include <SoftwareSerial.h>

SoftwareSerial target(12, 13); // RX, TX

void setup() {
  Serial.begin(9600);
  target.begin(9600);
  Serial.println("Hello");
}

void loop() {
  while (Serial.available()) {
    char c = Serial.read();
    Serial.write(c);
    target.write(c);
  }
  while (target.available()) {
    Serial.write(target.read());
  }
}
