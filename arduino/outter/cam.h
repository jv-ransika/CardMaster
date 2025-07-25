#ifndef CAM_H
#define CAM_H

#include "esp_camera.h"
#include <Arduino.h>

extern bool readyForNextChunk; 

void camInit();
void sendImageBLE();

#endif