// #define CAMERA_MODEL_WROVER_KIT // Has PSRAM
#define CAMERA_MODEL_AI_THINKER

#define DEVICE_NAME "CardMaster - OC"
// #define DEVICE_NAME "CardMaster - IC"

#define COMMAND_CAP "CAP"

#define START_MARKER {0xAA, 0x55, 0xAA, 0x55}
#define END_MARKER {0x55, 0xAA, 0x55, 0xAA}

#define FLASH_LED_PIN 4

#ifdef CAMERA_MODEL_WROVER_KIT
#define ONBOARD_LED 2
#define TURN_ON HIGH
#elif defined(CAMERA_MODEL_AI_THINKER)
#define ONBOARD_LED 33
#define TURN_ON LOW
#endif