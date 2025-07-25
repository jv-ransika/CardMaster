#include "Arduino.h"

#include "CardStackHandler.h"
#include "pinConfig.h"
#include "config.h"

void cardStackInit(){
  pinMode(SteperDirPinStack, OUTPUT);
  pinMode(StepperStepPinStack, OUTPUT);
  pinMode(LimitSwitchPin, INPUT_PULLUP);
}


void clockviceFullRound(int n){
  Serial.println("rotating stack stepper "+ String(n) + "rounds");
  digitalWrite(SteperDirPinStack, HIGH); // Clockwise
  for (int y = 0; y < n; y++){
    for (int i = 0; i < StepperstepsPerRevolution; i++) {
      digitalWrite(StepperStepPinStack, HIGH);
      delayMicroseconds(StepperSpeedDelay); // Control speed
      digitalWrite(StepperStepPinStack, LOW);
      delayMicroseconds(StepperSpeedDelay);
    }
  }
}

void counterClockviceFullRound(int n){
  Serial.println("rotating stack stepper "+ String(n) + "rounds");
  digitalWrite(SteperDirPinStack, LOW); // Counter-clockwise
  for (int y = 0; y < n; y++){
    for (int i = 0; i < StepperstepsPerRevolution; i++) {
      digitalWrite(StepperStepPinStack, HIGH);
      delayMicroseconds(StepperSpeedDelay); // Control speed
      digitalWrite(StepperStepPinStack, LOW);
      delayMicroseconds(StepperSpeedDelay);
    }
  }
}

int limitSwitchStatus(){
  if(digitalRead(LimitSwitchPin) == 0){
    return 1;
  }else {
    return 0;
  }
}

void stepperTest(){
  clockviceFullRound(1);
  Serial.println("clock");
  delay(1000);
  counterClockviceFullRound(1);
  Serial.println("anti");
  delay(1000);
}

