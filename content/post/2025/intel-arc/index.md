---
title: The Amazing Arc Pro A40 and Problems with Coral TPU Passthrough
author: FuzzyMistborn
date: 2025-07-13
slug: intel-arc-pro
categories:
  - Infrastructure
tags:
  - Intel
  - Graphics
  - Frigate
  - Coral
  - Jellyfin
  - Handbrake
  - Arc
  - TPU
  - USB
  - Transcoding
draft: false
---
Thanks to a  fun garage sale by a certain IronicBadger, I picked up an [Intel Arc Pro A40](https://www.intel.com/content/www/us/en/products/docs/discrete-gpus/arc/workstations/a-series/a40.html) graphics card for a very reasonable price and decided to put it to use for transcoding.  This post is going to be documenting some of my failures/issues in the dream of a single VM to house all my transcoding apps (Jellyfin, Handbrake, and Frigate).

I wrote this post for 2 reasons.  First, I wanted to document my failures for the USB Coral TPU passthrough in case someone searching for answers comes across my efforts and learns it's not going to happen.  And second, my experiences so far with the Arc Pro A40 as I've been moving my infrastructure around.

TLDR: you can't pass through a Coral TPU USB device to VM for Frigate, but it was kinda fun trying.

Second TLDR: the Arc Pro is a flipping BEAST for transcoding.
# Transcoding Setup

We'll start with my first attempt to house everything in an LXC.  I know there are security concerns/issues with running Docker containers inside an LXC and the Proxmox devs do not support/condone it.  But...it works for me and it's incredibly lightweight so...I do it anyway.  However, I ran into an issue that I couldn't get around.  Namely that was passing through the correct graphics card to the LXC as I have both an iGPU from my i5-10400 and the Arc Pro.  Annoyingly in my past experience the two would flip back and forth between `/dev/dri/renderD128` and `/dev/dri/renderD129`.  Therefore I couldn't reliably ensure that the Arc Pro was the card available in the LXC, which kind of defeated the entire purpose of the setup.  I only wanted to pass the one through so that way when I configured the services I knew I had the Arc Pro available and not the iGPU.

So after a few days spent toying with udev rules, I abandoned the LXC approach and went for a full VM.  Much simpler to handle passing only the Arc Pro through and the trade off of the higher resource requirements was worth it for a guarantee of always having the Arc Pro available.  All my issues solved right?  Wrong.

# Coral TPU over USB

As I mentioned above, I wanted to also run Frigate in the VM and use the Arc Pro to handle all the transcoding of my camera streams.  I use a Coral TPU over USB, which has worked extremely well as an efficient solution for person/car detection in Frigate.  I figured it wouldn't be hard to pass through the USB device to the VM.  How wrong I was.

I quickly learned how much of a special snowflake the Coral TPU USB is.  When you first plug it in, it shows up as
```
Bus 002 Device 002: ID 1a6e:089a Global Unichip Corp.
```
However, after it's used/initialized, it changes it's device ID (!!!!!!) to:
```
Bus 002 Device 003: ID 18d1:9302 Google Inc.
```

What.  The.  Hell.  

You can read more about it in this [long GitHub issue](https://github.com/google-coral/edgetpu/issues/536).

Because it changed IDs (and I think I tried passing both through to the VM and it didn't work), I needed a way initialize the Coral on the host then pass through the "right" device ID to the VM.  So along with my AI pal Claude, we came up with this solution:

**Step 1**: Created a Docker container that contains the necessary bits to intialize the device: https://github.com/FuzzyMistborn/docker-coral-usb/?tab=readme-ov-file

**Step 2**: Made a bash script that would run the Docker container:
```bash
#!/bin/bash 
docker run --rm --device /dev/bus/usb ghcr.io/fuzzymistborn/docker-coral-usb
```

**Step 3**: Create a udev rule to run the bash script when the Coral is plugged in:
```
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", ATTRS{idProduct}=="089a", RUN+="/home/fuzzy/usb-docker-trigger.sh"
```
**Step 4**: Create a systemd service to also call the bash script on boot:

```
[Unit]
Description=USB TPU Initialize Docker on Boot
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
ExecStart=/home/{{main_username}}/usb-docker.sh
User={{main_username}}
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```
**Step 5**: Profit?

That all worked.  I could see the Coral TPU in the VM as the `Google Inc.` whenever I would reboot the server or plug/unplug.  Problems solved right?

Wrong.

I noticed very quickly that my Frigate logs were filled with this:

```
frigate.watchdog               INFO    : Detection appears to be stuck. Restarting detection process...
root                           INFO    : Waiting for detection process to exit gracefully...
root                           INFO    : Detection process didn't exit. Force killing...
root                           INFO    : Detection process has exited...
detector.coral                 INFO    : Starting detection process: 34258
frigate.detectors.plugins.edgetpu_tfl INFO    : Attempting to load TPU as usb
frigate.detectors.plugins.edgetpu_tfl INFO    : TPU found
```

I found a number of threads like [this one](https://github.com/blakeblackshear/frigate/discussions/16977) or [this one](https://github.com/blakeblackshear/frigate/discussions/16649)of people with the issue.  I tried all the solutions: a powered USB hub, a shorter cable, etc.  None of that worked.  I thought about getting the Dual PCIe TPU instead, but that was quickly going to add up in costs, partly thanks to tariffs and also partly just because they're hard to find as I believe Google has stopped production.

For now, I've reverted to having Frigate run on the host in Docker with the TPU USB passed through, and that works fine.  I've been playing with `OpenVINO` on the Arc Pro in the VM and it consumes a lot more power in comparison to the USB Coral.  So I think until the USB Coral dies, I'm going to stick with my current setup as the power draw is well worth it.  Plus I have the detection settings dialed in nicely for the TPU and I would have to play a bit more with OpenVino to get it "right."
# Arc Pro Transcoding Performance

It's. A. Monster.

As mentioned above, I have an i5-10400 in my server, which has a UHD Graphics 630 iGPU.  Per the very handy [Wikipedia page on Intel Quick Sync](https://en.m.wikipedia.org/wiki/Intel_Quick_Sync_Video#Hardware_decoding_and_encoding), the 630 can handle HEVC and even HEVC-10bit.  It cannot handle AV1, which the Arc Pro can.

I haven't really pushed the Arc Pro long term yet, but with some quick performance tests in Jellyfin, I found the Arc Pro was about twice as fast transcoding 4k files than the iGPU.  Granted, we're talking ~60 FPS on the iGPU so it wasn't BAD, but I'm never going to have transcoding issues/stutters with the Arc Pro.

The addition of AV1 also is potentially interesting, though I noticed the speed is more like 25% faster on the Arc Pro than the iGPU (50fps on the iGPU, 75fps on the Arc Pro).  What's more interesting is that when I used Handbrake to reencode some files, the resulting files were noticeable *smaller* from the Arc Pro.  For example:

| **Device** | **Starting Size** | **Ending Size** |
| ---------- | ----------------- | --------------- |
| iGPU       | 8.7 GB            | 3.9 GB          |
| Arc Pro    | 8.7 GB            | 2.7 GB          |

In terms of power draw, I'm relatively pleased.  My first experience with an Arc card, the A380, [the power draw was terrible](https://techhub.social/@FuzzyMistborn/111592531655107031).  I think there have been some improvements to the Linux kernel and also more time to figure out that you need to enable ASPM in the BIOS.  Thankfully my motherboard supported ASPM so I was able to get the draw down to around 10watts idle.

I think long term the Arc Pro is going to have a happy life in my home lab.  One day it'll probably take over image processing for the Coral TPU while also handling all my transcoding needs.  And who knows what else some clever developer will come up with that can take advantage of the Arc card.