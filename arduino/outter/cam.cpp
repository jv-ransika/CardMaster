#include "cam.h"
#include "BLEServiceHandler.h"


// #define CAMERA_MODEL_AI_THINKER
#define CAMERA_MODEL_WROVER_KIT
#include "camera_pins.h"

bool readyForNextChunk = true;


void camInit(){
    // Camera configuration
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_VGA;
  config.pixel_format = PIXFORMAT_RGB565;
  config.grab_mode = CAMERA_GRAB_LATEST;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 10;
  config.fb_count = 2;

  // Initialize the camera
  if (esp_camera_init(&config) != ESP_OK) {
    Serial.println("Camera init failed");
    return;
  }
}

void sendImageBLE() {
  if (!deviceConnected) {
    Serial.println("No device connected. Cannot send image.");
    return;
  }

  readyForNextChunk = true;

  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    return;
  }

  int len = fb->len;
  int chunkSize = 500; // Adjust based on MTU
  int offset = 0;

  Serial.printf("Starting image transfer: %d bytes\n", len);

  while (offset < len) {
    readyForNextChunk = false;

    // It's good practice to check for connection status periodically in long loops
    if (!deviceConnected) {
        Serial.println("Device disconnected during image transfer.");
        break; // Exit the loop if disconnected
    }

    int sendingSize = min(chunkSize, len - offset);
    imageCharacteristic->setValue(fb->buf + offset, sendingSize);
    imageCharacteristic->notify();
    Serial.printf("Sent chunk: offset=%d, size=%d\n", offset, sendingSize);
    offset += sendingSize;
    
    delay(20); // BLE stack needs some delay
  }

  Serial.printf("Image sent over BLE: %d bytes\n", fb->len);
  esp_camera_fb_return(fb);
}
