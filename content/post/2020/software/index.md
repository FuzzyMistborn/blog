---
title: "What software do I run?"
author: "FuzzyMistborn"
date: 2020-04-22T01:55:00Z
slug: what-software-do-i-run
image: "header.jpg"
categories:
  - "Smart Home"
tags:
  - HomeAssistant
  - Software
  - NodeRed
  - Docker
draft: false
---

Maybe the first place to start is: what software am I running to control my smart home?

Surprisingly, a lot.

## HomeAssistant

First, and most importantly, is [Home-Assistant](http://home-assistant.io), or HASS.  HASS is...incredible.  HASS can literally integrate with thousand of devices and services (1,500+ as of writing this) and it's continually increasing.  Not to say that HASS is perfect (it's not).  There are still a lot of growing pains as it's not 1.0 yet, which means lots of breaking changes between updates and some of them aren't popular.  I still think it's the best piece of software for running a smart home given it's popularity, ease of installation, and helpful userbase.  I probably won't do any kind of "How to Install HASS" as that's well covered elsewhere (and again, kinda everchanging at the moment) but I probably will do some posts about the various things I integrate with HASS and how I made those decisions.

## NodeRed

Next is [Node-Red](https://nodered.org/).  The best way to think about Node-Red is that it's the "brains" running the show.  HASS provides the connections to my various devices and their state and then Node-Red tells HASS what to do.  Node-Red is a visual automation editor that I have found to be far superior to the built in HASS automation editor.  I started out with HASS as the automation engine and it worked very well for me.  But I grew tired of repeating lines of code over and over when I'd add things and debugging was a pain.  Node-Red is much easier in my opinion to 1) see what you're doing, 2) easily reuse what you've done before (I love using links), and 3) debug your automations to see if there are problems and where they are.  At this point I have very few automations left in HASS (mainly those I just can't figure out how to recreate or am to lazy to deal with).

{{< figure src="NodeRed.png" caption="Example of Node-Red in action" >}}

The above automation replaced a few hundred lines of code and controls my alarm system.  I have some other examples I'll explore later, but I would highly recommend someone starting out with HASS to explore Node-Red as well.

## Other Software

Just a quick rundown of other software I run. [MQTT](https://mqtt.org/) (Message Queuing Telemetry Transport) is an absolutely essential as it's an incredibly versatile tool.  I use it a lot of interconnect various devices and services.  Basically you create a MQTT broker/server and then various clients can connect to it to both send and read/receive messages on different topics.  Sounds complicated but once you dig into it a bit you'll see how simple and flexible it can be.  Personally I use [Mosquitto](https://mosquitto.org/) but there are a few other options out there.

I'll have a larger post on hardware at some point, but recently I picked up a Zigbee stick (Conbee II) and to control the various Zigbee devices I've picked up I use deConz.  Again, more on hardware later.

Database-wise I mostly use Mariadb, but also have an InfluxDB that feeds HASS data into Grafana for some pretty graphs.  Not much to say here, a database is kind of a database...

Other odds and ends that are tangentially related to smart home things are [MotionEye](https://github.com/ccrisan/motioneye) for recording my various Wyze Cams running RTSP (more on these later). [Nginx](https://nginx.org/) is my reverse proxy of choice (I tried Apache and Traefik but I have nginx working so I'm following the "if it ain't broke don't fix it" mantra).

## Docker

Everything described above is run via [Docker](https://www.docker.com/) and [Docker-Compose](https://docs.docker.com/compose/).  Docker makes things so much simpler to set up, configure, and run.  Basically everything installs inside of a container so everything should "just work."  If it doesn't work, I can easily delete the container/image with minimal system impacts (and best of all, very few lingering files/folders/other cruft).  I end up trying a lot of things out and really like using Docker to test things out for that reason.  In fact, if there's NOT a Docker container available I'm less likely to want to try the software out these days.  The result is that there's very little that runs outside of Docker for me on my server.

Finally, speaking of my server, I'm running Ubuntu 18.04 LTS (soon to be upgraded to 20.04 LTS once the .1 patch comes out).  Ubuntu works well and is well supported so again it "just works."  Again part of the benefit of running everything in Docker is that the underlying OS doesn't matter a ton so use what works for you.

## Conclusion

So that's what runs my smart house.  Probably an overly simplistic overview but hope it's helpful to someone to see.  Next up I'll probably cover the hardware I use, before I start branching off a bit to some of the more nuts and bolts things that I want to write to document/write up.

Till next time.


