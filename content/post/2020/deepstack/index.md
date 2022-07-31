---
title: "Object Detection with BlueIris and Deepstack"
author: "FuzzyMistborn"
date: 2020-08-26T18:59:08Z
slug: object-detection-with-blueiris-and-deepstack
image: "header.jpeg"
categories:
  - "Smart Home"
tags:
  - HomeAssistant
  - BlueIris
  - Cameras
  - NVR
  - Deepstack
draft: false
---

> **NOTE**: See [revised post here](https://blog.fuzzymistborn.com/).  Below is being left for posterity, but is not longer what I would recommend.

As I previously mentioned, I recently ditched my Wyze cams and moved over to Eufy cams for indoor.  I also decided to buy some outdoor cams to mount and watch my front door and driveway in real time.  However, I got tired of getting lots of false alerts due to trees/bushes moving in the wind, bugs flying by the camera at night, etc.  So I started to explore ways of weeding out the false positive alerts and only getting alerts when there actually was a person at my door or a car in my driveway.  Went through a few set ups but I've found one that has been working terrifically for a few days so wanted to share.

## What You'll Need:

**Video Camera -** Inside I use my Eufy cams, and outside I picked up these [Reolink RLC-410W's](https://smile.amazon.com/gp/product/B07DC2GM5K/).  I wanted to do POE but due to house design issues I couldn't run the necessary wiring.  So far the 410W's are working great.

**NVR Software** - I use BlueIris, but really any NVR software should be able to work, so long as you can use it to trigger the AI software to analyze the camera snapshot.

**AI Software** - There's a LOT of options out there, some of which are local and some of which rely on various cloud setups.  Personally I wanted to only use local processing.  I know several people who use the [Coral USB Accelerator](https://smile.amazon.com/dp/B07S214S5Y/) and [Frigate](https://github.com/blakeblackshear/frigate) (which uses TensorFlow).  I personally settled on using [Deepstack](deepstack.cc/) which I have found to be fairly accurate and when configured correctly not overkill on my server.  Though I'm sure if I figured out a way of adding some kind of Coral-like device the processing would get significantly faster.

**HomeAssistant** - This really should go without saying at this point...

## Approach #1

Initially, I was inspired for this project by this video by Rob over at TheHookUp.

{{< youtube fwoonl5JKgo >}}

In a nutshell, his set up using BlueIris to take a snapshot when motion is detected on the lower definition substream of his camera, which is then processed by Deepstack to determine if there's a person.  If there is, it triggers recording in full 4k resolution.  The goal for Rob was to limit the recording in 4k since it would chew up a lot of HDD space quickly to record in 4k 24/7.

I followed this approach at first and was very impressed at how simple it was.  And it worked.  However, I quickly ran into a limitation for my own use case.  I wasn't concerned with my cameras all recording at full quality (the Eufy ones don't have a substream) but I wanted a snapshot sent to my phone when the camera detected a person (or a car) at the front door or in the driveway.

What I had set up based on the above approach was 1) BlueIris would detect motion and take a snapshot, 2) the AITools application would send the snapshot over to Deepstack, 3) if Deepstack indicated it was a person/car, AITools would then trigger the camera, which 4) would send an MQTT alert to HomeAssistant to take a snapshot of the stream.  The result was, as you might expect, that often times the person would no longer be in the frame by the time HomeAssistant took a snapshot due to the lag of DeepStack processing (even though it was only a few seconds).  So that forced me back to the drawing board.

## Approach #2

When I would check the log in AITools I would see that Deepstack was pretty accurately detecting that there was a person/car.  The only other way to get images out of AITools was via Telegram.  But the downside here was that there was no way to filter out snapshots when I didn't want them (ie when the front door is opened by me to go get the mail).  Plus it put a decent amount more stress on my CPU since it would send a LOT of images to Deepstack to be processed.

So basically what I wanted was a way to have BlueIris detection motion, send a trigger to HomeAssistant, which would then (depending on certain conditions I might want to set) take a snapshot and send the snapshot to Deepstack, which would then return the same image if it detected a person/car.  So no more middleman and trying to get the images synced up.

To do this, I found this [custom component](https://github.com/robmarkcole/HASS-Deepstack-object).  There's also one that can detect faces but I have not given that a go.  The instructions on the GitHub page for installing Deepstack via Docker and getting everything set up are pretty well done.  Just a few comments/things I've discovered:

1) There's a few different versions of the Deepstack container.  The GitHub page examples all use the `noavx` tag, versus the `latest` tag supports AVX.  You can determine if your computer supports AVX with `grep avx /proc/cpuinfo` in Linux.  HOWEVER, I couldn't get the "latest" image to work properly as activation seemed broken.  The `noavx` image works fine so that's what I went with.  There's also `cpu-x3-beta` or `gpu-x3-beta` which supposedly include a number of improvements, but based on reports I've seen the processing is currently a LOT slower.  Deepstack is in the process of open sourcing the software so hopefully when that process is complete we'll see improved versions.

2) I would also highly suggest playing around with the Deepstack UI built by Rob Markcole, which you can find [here](https://github.com/robmarkcole/deepstack-ui).  It will help you set up the entities in HomeAssistant since you can see how adjusting the x/y coordinates will affect image processing.

3) If you're running BlueIris, then I would suggest checking out the custom component [here](https://github.com/elad-bar/ha-blueiris).  You can get might higher quality streams into HomeAssistant this way (over the MJPEG one I had set up), and you can easily get various alerts set up (without having to define them all in YAML).  Note for the alerts you'll want to refer to the BlueIris manual located [here](https://github.com/elad-bar/ha-blueiris/blob/master/docs/blueiris-server.md).  This also lets you use BlueIris's profiles, which was something I hadn't used too much before but absolutely am now to help control when alerts are sent to HomeAssistant and thus limiting the amount of logic in HASS/NodeRed that's required.

4) I think Rob mentions it in his video, but I would encourage you to set the motion sensitivity of the cameras to pretty high, since any false positive alerts _should_ be sifted out by Deepstack.

## Conclusion

Not a lot of "how to" in this post since I think the documentation is pretty well explained.  I intended this more as an explanation of how easy it is to set up AI-based object detection in your home and boost the accuracy of your motion alerts.

Overall, this was a pretty easy project to set up.  It took some tweaking of the motion sensitivity of the camera and getting all the alerts set up but overall the result is that I no longer get false positives of "someone at the door" when there really isn't.
