#include <Arduino.h>
#include "BLEServiceHandler.h"
#include "cam.h"

void setup() {
  Serial.begin(115200);
  setupBLE();
  camInit();
}

void loop() {
  if (deviceConnected) {
    //looptest();
  }
}
