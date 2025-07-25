#include <Arduino.h>
#include "BLEServiceHandler.h"

#include "pinConfig.h"
#include "CardIn.h"
#include "CardOut.h"
#include "DisplayServiceHandler.h"
#include "CardStackHandler.h"

void setup() {
  Serial.begin(115200);
  
  //Card Out
  cardOutInit();

  //Card In
  cardInInit();

  //Card Stack
  cardStackInit();


  // Display
  displayInit();

  // Run the blink task on core 0 (ESP32 has 2 cores: 0 and 1)
  xTaskCreatePinnedToCore(
    randomBlinkTask,   // Function
    "Blink Task",      // Name
    10000,             // Stack size
    NULL,              // Parameter
    1,                 // Priority
    NULL,              // Task handle
    0                  // Run on core 0
  );

  //setupBLE();
}

void loop() {
  while(!limitSwitchStatus()){
    counterClockviceFullRound(1);
    delay(10);
  }

  for( int i =0; i<15; i++){
    clockviceFullRound(1);
  }
  // cardOutServoGo(0);
  // delay(500);
  // cardOutServoGo(50);
  // delay(500);
  // cardInServo();
}
