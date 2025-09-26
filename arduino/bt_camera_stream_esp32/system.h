#include "config.h"
#include "camera_pins.h"
#include "BluetoothSerial.h"
#include "esp_camera.h"
#include "cam_stream.h"

BluetoothSerial SerialBT;

void init_serial() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();
  Serial.println("=========================================");
  Serial.println("BT Classic Camera Streamer.");
  Serial.println("Card Master 1.0");
  Serial.println("=========================================");
}

void init_bt_classic() {
  SerialBT.begin(DEVICE_NAME);
  Serial.println("[BT]: BT-Classic started.");
  Serial.print("[BT]: Device Name: ");
  Serial.println(DEVICE_NAME);
}

bool init_camera() {
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
  config.frame_size = FRAMESIZE_UXGA;
  config.pixel_format = PIXFORMAT_JPEG;  // for streaming
  // config.pixel_format = PIXFORMAT_RGB565; // for face detection/recognition
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  // if PSRAM IC present, init with UXGA resolution and higher JPEG quality
  //                      for larger pre-allocated frame buffer.
  if (config.pixel_format == PIXFORMAT_JPEG) {
    if (psramFound()) {
      config.jpeg_quality = 10;
      config.fb_count = 2;
      config.grab_mode = CAMERA_GRAB_LATEST;
    } else {
      // Limit the frame size when PSRAM is not available
      config.frame_size = FRAMESIZE_SVGA;
      config.fb_location = CAMERA_FB_IN_DRAM;
    }

    config.frame_size = FRAMESIZE_HD; // 1280x720
  } else {
    // Best option for face detection/recognition
    config.frame_size = FRAMESIZE_240X240;
    // config.frame_size = FRAMESIZE_QVGA; // 320x240
    // config.frame_size = FRAMESIZE_VGA; // 640x480
    // config.frame_size = FRAMESIZE_SVGA; // 800x600
    // config.frame_size = FRAMESIZE_HD; // 1280x720
  }

#if defined(CAMERA_MODEL_ESP_EYE)
  pinMode(13, INPUT_PULLUP);
  pinMode(14, INPUT_PULLUP);
#endif

  Serial.println("[CAM]: Initializing camera...");

  // camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("[CAM]: Camera init failed with error 0x%x", err);
    return false;
  } 

  Serial.println("[CAM]: Camera initialized.");

  sensor_t *s = esp_camera_sensor_get();

//...
#ifdef CAMERA_MODEL_AI_THINKER
  s->set_brightness(s, -2); // lower brightness
  s->set_saturation(s, 0);  
  s->set_gainceiling(s, (gainceiling_t)0);
  s->set_ae_level(s, -2);
  s->set_raw_gma(s, 0);
#endif

#if defined(CAMERA_MODEL_M5STACK_WIDE) || defined(CAMERA_MODEL_M5STACK_ESP32CAM)
  s->set_vflip(s, 1);
  s->set_hmirror(s, 1);
#endif

#if defined(CAMERA_MODEL_ESP32S3_EYE)
  s->set_vflip(s, 1);
#endif

  return true;
}