---
title: "HomeAssistant App and TinyCam - Powerful Combination!"
author: "FuzzyMistborn"
date: 2023-02-19T23:01:00Z
slug: hass-notification-open-cam
categories:
  - "Smart Home"
tags:
  - HomeAssistant
  - Android
  - TinyCam
  - Cameras
---

This is going to be a quick one, but I'm unreasonably excited about it.  Lately I've noticed that image-based notifications haven't been always going through via Telegram.  Lots of errors in the logs about timed out connections, which I chalk up to the fact my internet is over a 5G router.  It's not bad, but it's not always stable/reliable.  I started to consider alternatives like Gotify (which I already use, except not for images) or even something Matrix.  But then I decided to take a closer look at an app I already have installed, the HomeAssistant companion app!

The HomeAssistant companion app is way more than just a way to access HomeAssistant.  It can provide all kinds of sensor data about your phone back to HASS and also serve as a vehicle for notifications.  Not all of which need to be an actual message!  You can do all sorts of things, like turn Bluetooth on/off, set do not disturb mode, and even trigger other apps to do things (I believe this part is Android only, I don't use iOS so apologies to those who do).

When I saw that it was possible to alter the action when you [click the notification](https://companion.home-assistant.io/docs/notifications/notifications-basic/#opening-a-url) I was intrigued.  Then I saw that you could also call an Android intent to open up another app.  And somewhere I saw the idea to open up [TinyCam](https://play.google.com/store/apps/details?id=com.alexvas.dvr.pro) and I had to dig in.  I've been using TinyCam as a quick and easy way to access my POE cameras as I have a mix of camera brands (post coming soon, promise).  I tried the BlueIris app and it's OK, but the UI isn't ideal for quickly seeing a camera feed.  TinyCam on the other hand literally just shows the camera feeds on the opening page.  Doesn't get much simpler.

I had a "ah-ha" moment realizing I could use the HomeAssistant  companion app to send a notification with a snapshot of the camera feed when motion is detected, and then when I click the notification, it takes me directly to that camera's feed in TinyCam so I can see what's going on.  I struggled for the better part of a day to figure out the right intent (hat tip to the HASS Discord server and @dshokouhi, as well as [/u/nVIceman on Reddit](https://www.reddit.com/r/tinycam/comments/xebr7y/comment/j1563l6/?utm_source=share&utm_medium=web2x&context=3)) but I got it.  So now if there's motion at my front door, I get a notification with the doorbell image and if I click the link, the doorbell camera feed opens in TinyCam.

```yaml
service: notify.mobile_app_fuzzy_phone
data:
  message: Motion detected at the Front Door!
  data:
    image: /api/camera_proxy/camera.truthwatcher_front_door
    clickAction: "intent:#Intent;action=android.intent.action.MAIN;component=com.alexvas.dvr.pro/com.alexvas.dvr.activity.LiveViewActivity;S.com.alexvas.dvr.intent.extra.shortcut.NAME=Front Door;end"
```
That's it.  All you'd need to do is change the last bit (after "NAME=") to match the name of the camera in TinyCam.  If you wanted instead to open the camera directly without having to click a link, you could do something like this:

```yaml
service: notify.mobile_app_fuzzy_phone
data:
  message: command_activity
  data:    
    intent_action: "android.intent.action.MAIN"
    intent_extras: "com.alexvas.dvr.intent.extra.shortcut.NAME:Front Door"
    intent_package_name: "com.alexvas.dvr.pro"
```
In closing, I'd encourage everyone to take a close look at the [HomeAsssistant companion app docs](https://companion.home-assistant.io/).  It's really impressive what it can do!