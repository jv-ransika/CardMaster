#include "BLEServiceHandler.h"

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

#define IMAGE_SERVICE_UUID "019d667d-1a82-469d-b5b1-7fb7191dc3d3"
#define IMAGE_CHARACTERISTIC_UUID "96047a38-ed23-4916-8e40-54a01a6b075d"


BLECharacteristic *pCharacteristic = nullptr;
BLECharacteristic *imageCharacteristic = nullptr;
bool deviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("Device connected");
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("Device disconnected");
    pServer->getAdvertising()->start();
    Serial.println("Waiting for a client to connect...");
  }
};

void setupBLE() {
  BLEDevice::init("CardMaster Bot");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLEService *imageService = pServer->createService(IMAGE_SERVICE_UUID);

  // For pService
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY |
    BLECharacteristic::PROPERTY_INDICATE
  );

  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setValue("Hello from ESP32");


  pService->start();

  // For  imageService
  imageCharacteristic = imageService->createCharacteristic(
    IMAGE_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY |
    BLECharacteristic::PROPERTY_INDICATE
  );

  imageCharacteristic->addDescriptor(new BLE2902());
  imageCharacteristic->setValue("0");

  imageService->start();


  
  pServer->getAdvertising()->start();
  Serial.println("Waiting for a client to connect...");
}

void looptest(){
  pCharacteristic->setValue("Time: " + String(millis() / 1000));
  pCharacteristic->notify();
  delay(2000);
}
