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