// LED.hpp
#ifndef LED_HPP
#define LED_HPP

class LED {
public:
    virtual ~LED() = default;

    // Initialize the LED hardware
    virtual void initialize() = 0;

    // Turn the LED on
    virtual void turnOn() = 0;

    // Turn the LED off
    virtual void turnOff() = 0;

    // Toggle the LED state
    virtual void toggle() = 0;

    // Set the LED brightness (0 to 100)
    virtual void setBrightness(int level) = 0;
};

#endif // LED_HPP
#include "LED.hpp"

class BasicLED : public LED {
public:
    BasicLED(int pin) : pin_(pin), isOn_(false), brightness_(0) {}

    void initialize() override {
        // Initialize the hardware, e.g., set pin mode
        // pinMode(pin_, OUTPUT);
        isOn_ = false;
        brightness_ = 0;
    }

    void turnOn() override {
        // Turn the LED on
        // digitalWrite(pin_, HIGH);
        isOn_ = true;
    }

    void turnOff() override {
        // Turn the LED off
        // digitalWrite(pin_, LOW);
        isOn_ = false;
    }

    void toggle() override {
        // Toggle the LED state
        isOn_ = !isOn_;
        // digitalWrite(pin_, isOn_ ? HIGH : LOW);
    }

    void setBrightness(int level) override {
        // Set the LED brightness (0 to 100)
        if (level < 0) level = 0;
        if (level > 100) level = 100;
        brightness_ = level;
        // analogWrite(pin_, map(brightness_, 0, 100, 0, 255));
    }

private:
    int pin_;
    bool isOn_;
    int brightness_;
};