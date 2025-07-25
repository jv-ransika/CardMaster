#ifndef BLE_SERVICE_HANDLER_H
#define BLE_SERVICE_HANDLER_H

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#include <config.h>

extern BLECharacteristic *pCharacteristic; // 0 nothing
extern BLECharacteristic *imageCharacteristic;
extern bool deviceConnected;

void setupBLE();
void looptest();

#endif
