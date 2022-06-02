---
title: "Deconz v. Zigbee2MQTT"
author: "FuzzyMistborn"
date: 2022-05-24T22:30:00Z
slug: z2m-v-deconz
categories:
  - "Smart Home"
tags:
  - HomeAssistant
  - Zigbee
  - Deconz
  - MQTT
  - Zigbee2mqtt
draft: false
image: "logo.png"
---

I'm a big believer in both Zwave and Zigbee.  Both have their pros and cons.  Zwave in my opinion is a better technology because of the lack of interference and it propagates further/wider due to being a lower frequency.  However, the devices are more expensive and there's less overall variety.  Zigbee on the other hand shares the same frequencies as Wifi (and other technologies) in the 2.4ghz band so interference can be an issue.  However, the devices are usually significantly cheaper and there's a **lot** more variety when it comes to devices.

So instead of picking one and sticking to it, I run both in my house to play to the general strengths of both.  When it comes to Zigbee, I'm a big fan of the Xiaomi Aqara line of devices.  They're cheap, they work great, and there's a lot of nice devices.  My personally favorite are [these button switches](https://www.amazon.com/dp/B07D19YXND) that I use all over the house to trigger various automations.

For a hub, I've long used a [Conbee II](https://www.amazon.com/dresden-elektronik-ConBee-Universal-Gateway/dp/B07PZ7ZHG5).  There are a number of hubs out there but I've found the Conbee to be the best.  The Conbee is manufactured by a company called Phoscon/Dresden-Elektronik, who in turn make a controller software called [deConz](https://github.com/dresden-elektronik/deconz-rest-plugin) (Note: I may have the ownership part wrong, I tried researching but couldn't find a definitive answer).  When I first started out, I figured why not use the software that's made by the company that makes the hardware.  There's probably good synergy there.  And I was right.  Sorta.

# deConz
DeConz as software works fine.  It is able to interface with a good variety of devices and it controls them just fine.  What was not so wonderful was 1) pairings could be an absolute nightmare and 2) occasionally devices would drop off the network and require a repair.  And third, unless you had lights in your network in a group, EVERY TIME you logged in you'd have to click through 3 screens about setting up light groups.  Was a real PITA and I could never figure out how to turn that off.  The first two issues though were real pain points.  For example, pairing my [Ikea Fyrtur](https://www.ikea.com/us/en/p/fyrtur-blackout-roller-blind-wireless-battery-operated-gray-20417465/) curtains took literally days and dozens of attempts to get paired.  And even then occasionally they would just stop responding for no apparent reason.

I also found it can sometimes take a while for deConz to support new devices.  They do seem to want to take their time and get it right, but if you want the latest and greatest devices it can be frustrating at times.  And while it's technically possible to run Over the Air updates on deConz, I struggled to get it to work and just gave up.

In terms of integrating with HomeAssistant, it was really quite simple.  There's an official integration, devices just show up, and it works fine.  To get the button events I had to use an even listener but that wasn't a major problem.  I didn't have an issue with this part of using deConz.

# Zigbee2MQTT
I'm not really going to go into the "how to set up Zigbee2MQTT" because I think 1) it's really pretty straightforward and 2) there are a lot of other posts/videos on how to do it.  So instead, I'm going to be focusing on my thoughts/impressions.

I wanted to test out Zigbee2MQTT as an alternative to deConz for a while, particularly because I'd heard great things about the sheer number of devices it supported, including the new [Aqara P1 motion sensor](https://www.amazon.com/dp/B09QKVMMTB/?psc=1) I picked up off Amazon.  One evening, I decided I would give it a try.  And stupid me, I thought I could just stop deConz, start up Zigbee2MQTT, add the P1 sensor, try it all out and then go back to deConz without any issues.

That....did not go according to plan.  I was able to set up Zigbee2MQTT just fine, got it all connected to the MQTT broker and everything worked fine.  Was done for the night, shut down Zigbee2MQTT, restarted deConz and started wrapping up for the evening.  When I noticed some of the motion sensors didn't seem to be working because the lights weren't turning on.  Went into deConz and....none of the devices were showing up.  Uh oh....

Decided to bite the bullet since I was going to have to repair everything anyway and just switch everything over to Zigbee2MQTT.  That evening I got the bare essentials repaired and then got the rest repaired the following day, along with renaming things so my existing automations would continue to work.  It was painful with about 25 devices but not horribly so.  The biggest thing that made it easier was the pairing was **so much easier** with Zigbee2MQTT than Deconz.  For starters, everything paired without much issue.  Including the Fyrtur blinds that I struggled so mightily with when using deConz.  Second, Zigbee2MQTT opens up pairing for 5 minutes and allows you to pair as many devices as you want/can in that time period.  deConz was one at a time, and like with the entry screens, the UI was cumbersome to navigate.

The devices just showed up for me in HomeAssistant under the MQTT integration.  I do wish they were separated from some of my other MQTT-based devices, but they were easy to configure/rename so it's a minor quibble.  And doing OTA updates via Zigbee2MQTT is a breeze.  Not many of my devices actually had an update to run 

# Conclusion
After a few days, I'm very happy I switched.  Devices that were giving me trouble with deConz are working just fine now with Zigbee2MQTT, with one issue regarding the humidity sensor I use in my shower along with a trend binary sensor to detect whether someone is showering.  I'm sure I'll figure it out.

In terms of "should I switch off deConz to Zigbee2MQTT" the answer is it depends.  I was kinda forced to repair everything so I figured why not make the switch, and my network is relatively small at 25 devices.  If deConz is working fine for you and you aren't using unsupported devices, I don't think there's a super compelling reason to switch.  But if you are just starting out with Zigbee or find yourself wanting/needing to switch, then definitely give Zigbee2MQTT a go!