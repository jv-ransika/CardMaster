#ifndef CARD_IN
#define CARD_IN

#include "pinConfig.h"
#include <ESP32Servo.h>

Servo inServo;

void cardInInit(){
   pinMode(DCIN, OUTPUT);
   inServo.attach(ServoIN);
}

void cardInDcOn(int sec_time){
  digitalWrite(DCIN, HIGH);
  delay(sec_time * 1000);
  digitalWrite(DCIN, LOW);

}

void cardInServo(){
  inServo.write(0);
  delay(1000);
  inServo.write(90);
}

#endif
