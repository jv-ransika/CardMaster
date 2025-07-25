#include <Arduino.h>
#include "BLEServiceHandler.h"
#include "cam.h"
#include "pinConfig.h"

void setup() {
  Serial.begin(115200);
  setupBLE();
  camInit();
}

void loop() {
  if (deviceConnected) {
    // if(pCharacteristic->getValue() == "1"){
    
  }
  delay(10);
}
