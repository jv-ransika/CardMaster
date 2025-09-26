#include "system.h"

void setup() {
  init_serial();

  init_bt_classic();

  delay(2000);

  if (!init_camera()) {
    ESP.restart();
  }

  pinMode(ONBOARD_LED, OUTPUT);
  digitalWrite(ONBOARD_LED, TURN_ON);
}

void loop() {
  handle_cam_stream(SerialBT);
}