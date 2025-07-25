#include <Adafruit_GFX.h>    // Core graphics library
#include <Adafruit_ST7735.h> // Hardware-specific library for ST7735
#include <Adafruit_ST7789.h> // Hardware-specific library for ST7789
#include <SPI.h>
#include <Arduino.h>

#include "DisplayServiceHandler.h"
#include "pinConfig.h"

Adafruit_ST7789 tft = Adafruit_ST7789(DISPLAY_TFT_CS, DISPLAY_TFT_DC, DISPLAY_TFT_RST);

#define EYE_RADIUS 100
#define PUPIL_RADIUS 60
#define CENTER_X 120
#define CENTER_Y 120
#define PUPIL_Y_OFFSET 20  // move pupil slightly down

int prevX = CENTER_X;
int prevY = CENTER_Y + PUPIL_Y_OFFSET;

float p = 3.1415926;

void testdrawtext(char *text, uint16_t color);
void tftPrintTest();
void blinkEye(int blinkDelay = 150);
void drawPupil(int x, int y, bool erase = false);
void randomBlinkTask(void *parameter);

void displayInit() {
  tft.init(240, 240, SPI_MODE3);
  tft.setRotation(0);
  tft.fillScreen(ST77XX_BLACK);
  Serial.println("Display Initialized");
  tft.fillCircle(CENTER_X, CENTER_Y, EYE_RADIUS, ST77XX_WHITE);
}

void drawPupil(int x, int y, bool erase) {
  // Use ST77XX_WHITE to erase, ST77XX_BLACK to draw
  uint16_t color = erase ? ST77XX_WHITE : ST77XX_BLACK;
  tft.fillCircle(x, y, PUPIL_RADIUS, color);
}

void blinkEye(int blinkDelay) {
  // Draw upper eyelid
  tft.fillRect(CENTER_X - EYE_RADIUS, CENTER_Y - EYE_RADIUS, EYE_RADIUS * 2, EYE_RADIUS, ST77XX_BLACK);
  delay(blinkDelay);

  // Redraw the eye (white part and pupil)
  tft.fillCircle(CENTER_X, CENTER_Y, EYE_RADIUS, ST77XX_WHITE);
  drawPupil(CENTER_X, CENTER_Y + PUPIL_Y_OFFSET); // static pupil in center but slightly down
}

void animateEye() {
  float angle = 0;
  float step = 0.05;
  int radius = EYE_RADIUS - PUPIL_RADIUS - 2;

  for (angle = 0; angle <= 2 * PI; angle += step) {
    int dx = radius * cos(angle);
    int dy = radius * sin(angle);
    int newX = CENTER_X + dx;
    int newY = CENTER_Y + dy;

    drawPupil(prevX, prevY, true);     // erase old
    drawPupil(newX, newY, false);      // draw new

    prevX = newX;
    prevY = newY;

    delay(15); // Lower delay = smoother
  }
}

void testdrawtext(char *text, uint16_t color) {
  tft.setCursor(0, 0);
  tft.setTextColor(color);
  tft.setTextWrap(true);
  tft.print(text);
}

void tftPrintTest() {
  tft.setTextWrap(false);
  tft.fillScreen(ST77XX_BLACK);
  tft.setCursor(0, 30);
  tft.setTextColor(ST77XX_RED);
  tft.setTextSize(1);
  tft.println("Hello World!");
  tft.setTextColor(ST77XX_YELLOW);
  tft.setTextSize(2);
  tft.println("Hello World!");
  tft.setTextColor(ST77XX_GREEN);
  tft.setTextSize(3);
  tft.println("Hello World!");
  tft.setTextColor(ST77XX_BLUE);
  tft.setTextSize(4);
  tft.print(1234.567);
  delay(1500);
  tft.setCursor(0, 0);
  tft.fillScreen(ST77XX_BLACK);
  tft.setTextColor(ST77XX_WHITE);
  tft.setTextSize(0);
  tft.println("Hello World!");
  tft.setTextSize(1);
  tft.setTextColor(ST77XX_GREEN);
  tft.print(p, 6);
  tft.println(" Want pi?");
  tft.println(" ");
  tft.print(8675309, HEX); // print 8,675,309 out in HEX!
  tft.println(" Print HEX!");
  tft.println(" ");
  tft.setTextColor(ST77XX_WHITE);
  tft.println("Sketch has been");
  tft.println("running for: ");
  tft.setTextColor(ST77XX_MAGENTA);
  tft.print(millis() / 1000);
  tft.setTextColor(ST77XX_WHITE);
  tft.print(" seconds.");
}

// 🧠 Task to run on separate core
void randomBlinkTask(void *parameter) {
  while (true) {
    delay(random(1000, 5000)); // Wait between 1–5 seconds
    blinkEye(150);             // Blink
    delay(200);                // Redraw delay
    drawPupil(CENTER_X, CENTER_Y + PUPIL_Y_OFFSET);
  }
}
