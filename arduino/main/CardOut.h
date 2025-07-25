#ifndef CARD_OUT
#define CARD_OUT

#include <ESP32Servo.h>
#include "pinConfig.h"

Servo outServo;

void cardOutInit(){
  outServo.attach(ServerOUT);
  pinMode(DCOUT, OUTPUT);
}

void cardOutDcOn(int sec_time){
  digitalWrite(DCOUT, HIGH);
  delay(sec_time * 1000);
  digitalWrite(DCOUT, LOW);

}

void cardOutServoGo(int deg){
  outServo.write(deg);
}

#endif
