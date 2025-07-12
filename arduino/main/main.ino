#include <Arduino.h>
#include "BLEServiceHandler.h"

void setup() {
  Serial.begin(115200);
  //setupBLE();
}

void loop() {
  if (deviceConnected) {
    //looptest();
  }
}
