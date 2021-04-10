---
title: "Desk Detection with ESP8266's"
author: "FuzzyMistborn"
date: 2020-06-13T18:31:21Z
image: "header.jpg"
slug: desk-detection-with-esp8266s
categories:
  - "Smart Home"
tags:
  - HomeAssistant
  - ESPHome
  - ESP
  - ESP8266
draft: false
---

This is a bit of a tease since part of this project was to install individually addressable LED strips (WS2812B's) under the cabinets I recently installed in the office and I'm waiting to write that part up until I finish a more complicated outside install.  But I still think it's useful to discuss how I'm detecting whether I am at my desk to turn on the LEDs or not.

Since I didn't want the LEDs on all the time unless I was sitting at my desk I needed to figure out a way to detect whether I was sitting at my desk or not.

## Attempt #1

For my first attempt, I decided to try the capacitive sensors I'd been using for [bed detection](/esp8266-projects/).  Those worked....OK.  I started with 2 and eventually made 4 (actually 8 total as I made 4 for my spouse's desk as well).  Benefit here was that I already had a spare ESP32 lying around to use (and there are 8 touch-enabled pins on the ESP32) and making the sensor mats isn't incredibly difficult so I really didn't have much to lose by trying.

But no matter how much I tweaked them (changing placement, adjusting the sensitivity, etc) I couldn't get them to work reliably.  Sometimes I got false positives when the chair was in a certain spot, other times I'd be sitting/not moving but the sensor would turn off anyway.  After a few days I decided I needed to take another approach.

## Brainstorming Other Ideas

Did some searching and found 2 other solutions that people had tried.  The first is to use a contact sensor (like a door sensor).  The idea is that when you sit in the chair you'd push the sensors close enough to each other that the sensor would turn on.  I didn't like this solution because neither my spouse's desk chair nor mine would have made this easy due to the design. Also, neither one has a lot of up/down if we're seated or not so it didn't seem like it would work well.

The other solution, and the one I finally settled on, was to use an [HC-SR04 ultrasonic sensor](https://smile.amazon.com/gp/product/B07RGB4W8V), like this:

{{< figure src="desk-detection1.png" width="300">}}

This little guy sends out an ultrasonic ping at a pre-defined period (potentially every few miliseconds if you really wanted) and detects how far away an object is from it (I think it has a range limit of about 2 meters).

## Setting Things Up

So the setup here is really easy.  You'll need the following (and may already have some of the parts around if you've done any other ESP-based projects):

1) An ESP8266 or ESP32

2) An ultrasonic sensor.  I used the HC-SR04.  They're fairly cheap (about $7-9 on Amazon for 5 can be easily found).

3) Jumper wires

4) Power adapter/micro usb cable to power the ESP.

That's it!  I used ESP Home for this and followed the [instructions on the site](https://esphome.io/components/sensor/ultrasonic.html) to wire it.  It's pretty simple.  VCC to VIN (5 volts), ground to ground, and then TRIG/ECHO to a data/GPIO pin of your choice (I used D5 and D6).

Turning to the code, here's my config:

```yaml
sensor:
  - platform: ultrasonic
    trigger_pin: D6
    echo_pin: D5
    name: "Ultrasonic Sensor"
    update_interval: 1s
    id: desk
    filters:
      - delta: 0.1

binary_sensor:
  - platform: template
    name: "Desk Sensor"
    lambda: |-
      if (id(desk).state < 0.75 ) {
        return true;
      } else {
        return false;
      }
    filters:
      - delayed_on: 2s
      - delayed_off: 5s
```

The actual sensor is what measures the distance.  I have it update every 1 second which I find to be fast enough for me.  I also filter out small changes (anything less than 0.1m in change will not be reported to HomeAssistant, that's what the deta line is for).  I also created a binary sensor to report on/off depending if the distance is below a certain level.  For me, I found 0.75 was fairly accurate though I still may need to tweak a bit.  I further filtered this to delay the "on" by 2 seconds to just make sure there wasn't a whacky one-off reading and similarly 5 second delayed off to make weed out any small movements I might make.

I then added the sensors to HomeAssistant via the ESP Home integration (supppppper easy) and then created some automations to turn the lights on/off.

For the installation I just used some mounting putty and electrical wire to run the USB cable around the edge of the desk.  Finished result is that you can't even really see it.

{{< figure src="desk-detection2.jpg" caption="Not the prettiest install but it works" >}}

**Ease of project:** 9/10.  The first iteration with the under-mat sensors was a lot more complicated (requiring soldering/long wire runs and making the mats).  The ultrasonic sensor by contrast was incredibly easy and simple to do.  Probably the easiest ESP project to date.

Next up is either a summary of my experiences with individually addressable LEDs and ESP boards (with both WLED and ESP Home) or a write up on my new Eufy indoor cams.  But since I'm still waiting on my order of the pan/tilt cams I may delay doing a review of the Eufy cams until I have both (brief review: it's muuuuuuch better than the Wyze cam in a lot of areas and equal in all the rest with no drawbacks).
