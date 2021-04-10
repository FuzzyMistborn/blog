---
title: "HomeAssistant and CATT (Cast All the Things!)"
author: "FuzzyMistborn"
date: 2020-05-01T01:28:25Z
image: "header.jpeg"
slug: homeassistant-and-catt-cast-all-the-things
categories:
  - "Smart Home"
tags:
  - HomeAssistant
  - CATT
  - Google Home
draft: false
---

[Home Assistant Cast](https://cast.home-assistant.io/) was [announced](https://www.home-assistant.io/blog/2019/08/06/home-assistant-cast/) about 9 months ago (August 2019) and it's a very nifty concept if you have a Google/Nest Home Hub.  Essentially it allows you to cast a Lovelace page to your Hub and you can use the touch screen to interact with the page, just like a tablet.  There are a lot of possible use cases, from a security camera monitor to light/room controls and even media controls.  One example I use is to pull up a Google Maps view of my commute that shows me traffic data, and another example is to pull up a radar image on my nightstand so I can easily see if it's raining when I wake up and decide whether I should go back to bed or go for a run.

Unfortunately for me I could never get it to work consistently enough.  A common scenario would be I either got just a blank screen or I would get a HomeAssistant screen with "Connected" but no Lovelace page or even an error that it couldn't find the path, despite the fact that it had worked before and I had not changed anything on my end. [This Github issue](https://github.com/home-assistant/frontend/issues/4614) is representative of the many issues I had.

There's also issues that you need your HASS installation to be remotely accessible (either through NabuCasa or your own webpage/dynamic DNS url) which isn't an issue for many but for some it might be.

Then one day I stumbled across [this thread](https://community.home-assistant.io/t/using-catt/130332) in the HASS Community forum.  There's an alternative out there called, appropriately, "Cast All the Things" and it's available on [Github](https://github.com/skorokithakis/catt).  Let's go through the steps to get it installed and working with HASS.

## Installation

Installation is easy enough.  Open up a terminal on whatever device you use to run HASS (if you're running HASS.IO/HomeAssistant you probably need to use a different machine.  I don't use Hass.io so can't help with the install there check out [this GitHub](https://github.com/homeassistant-addons-eliseo/resting-catt) which should allow for CATT control via HASS.  Please note I haven't used so can't speak to how well it works).  The install command is:

```
pip3 install catt
```
You may need to make it "pip" depending on how you have Python/pip installed

Once installed, using CATT is fairly straightforward.  Here's a list of all the commands:

```
Commands:
  add           Add a video to the queue (YouTube only).
  cast          Send a video to a Chromecast for playing.
  cast_site     Cast any website to a Chromecast.
  clear         Clear the queue (YouTube only).
  del_alias     Delete the alias name of the selected device.
  del_default   Delete the default device.
  ffwd          Fastforward a video by TIME duration.
  info          Show complete information about the currently-playing video.
  pause         Pause a video.
  play          Resume a video after it has been paused.
  play_toggle   Toggle between playing and paused state.
  remove        Remove a video from the queue (YouTube only).
  restore       Return Chromecast to saved state.
  rewind        Rewind a video by TIME duration.
  save          Save the current state of the Chromecast for later use.
  scan          Scan the local network and show all Chromecasts and their IPs.
  seek          Seek the video to TIME position.
  set_alias     Set an alias name for the selected device.
  set_default   Set the selected device as default.
  skip          Skip to end of content.
  status        Show some information about the currently-playing video.
  stop          Stop playing.
  volume        Set the volume to LVL [0-100].
  volumedown    Turn down volume by a DELTA increment.
  volumeup      Turn up volume by a DELTA increment.
  write_config  Please use "set_default".
```

I would suggest starting with running "catt scan" to make sure you can find all your Chromecast devices.  Then you can test it out by running:

```
catt -d "NAME_OF_DEVICE" cast_site https://www.google.com
```
"NAME_OF_DEVICE" is whatever the name of the device is from running "catt scan"

You should be able to see the Google webpage on your Hub.  You can stop it by running

```
catt -d "NAME_OF_DEVICE" stop
```

At this point you're all set with CATT, unless you want to set up some default settings.  If you do, see the CATT Readme section [here](https://github.com/skorokithakis/catt#configuration-file).  It's entirely optional.

## Setup in HomeAssistant

### Trusted Networks

Now that we have CATT set up, it's time to get it working with HASS.  By default CATT won't work with HASS because HASS requires authentication and there's no way to get a keyboard on a Hub.  To get around this limitation, we'll need to configure a [Trusted Network](https://www.home-assistant.io/docs/authentication/providers/#trusted-networks) in HASS (this is assuming you are running a version of HASS >0.89).

There's a few ways to do this.  You can whitelist your entire network range if you want, or you can do individual devices.  You also can limit the users available.  Personally I wanted to restrict things as much as possible so I only allowed the 3 Hubs I have to be considered to be on a trusted network and restricted the user to a special "Dashboard" account I created in HASS.  So my configuration.yaml looks like this:

```yaml
homeassistant:
# Note that this section is a subset of homeassistant: and is not tabbed all the way to the left like other things in configuration.yaml
  auth_providers:
    - type: trusted_networks
      trusted_networks:
        - IP_ADDRESS_1/32
        - IP_ADDRESS_2/32
        - IP_ADDRESS_3/32
      trusted_users:
        IP_ADDRESS_1: DASHBOARD_USER_ID
        IP_ADDRESS_2: DASHBOARD_USER_ID
        IP_ADDRESS_3: DASHBOARD_USER_ID
      allow_bypass_login: true
      # Note that bypass_login only works if one user is authorized
```

Under "trusted networks" I list out the 3 IP addresses with a /32 to limit the range to just that single IP.  Under "trusted user" you list the IP address of the device and then the user_id(s) you want available.  You can find the user_id if you go to the HASS configuration page, click "Users" and then click the username.  You should see a line that says "ID" and a bunch of letters and numbers.  Copy that.

{{< figure src="hass_user_id.png" >}}

Now that you have the trusted networks set up, reboot HASS and test it out to make sure it works.  Find a page you want to cast (you will need to use the internal address and not any external URL you might use).  So an example cast might be:

```
catt -d "NAME_OF_DEVICE" cast_site http://HASS_URL:PORT/lovelace/0
```
Replace HASS_URL with the IP address of your server and pot with the port. Also change "lovelace/0" to whatever page you want to cast

You should see a login screen on your Hub, but you'll be able to select your dashboard user and login.  You also can click the "Save login" button in the bottom right corner to avoid having to log in every time.

### Automating

Assuming everything is working so far, now comes the fun part, automating!  To use CATT in a HASS automation you need to use the [Shell_Command integration](https://www.home-assistant.io/integrations/shell_command/).  This is simply a line just like you would put in terminal to start up CATT.  So for example:

```yaml
shell_command:
  cast_weather: catt -d "NAME_OF_DEVICE" cast_site http://HASS_URL:PORT/lovelace/weather
```
Goes in your configuration.yaml file

You'll need to restart HASS before the command is available.  Once it is, you can invoke it using the shell_command service call.  So using the above example, an automation might look like this:

```yaml
- alias: "Good Morning Radar"
  trigger:
    platform: state
    entity_id: input_boolean.fuzzy_awake
    to: on
  action:
    - service: shell_command.cast_weather
    - delay: "00:01:00"
    - service: shell_command.cast_stop
```

Note that I also created a "cast_stop" shell command to stop the casting, and have it run 1 minute after the cast starts.  Another way to do this is to create a bash script and call that instead.  Here's an example:

```bash
#!/bin/bash
/home/fuzzy/.local/bin/catt -d 'DEVICE_NAME' cast_site "URL"

sleep 1m

/home/fuzzy/.local/bin/catt -d 'DEVICE_NAME' stop
```
Adjust the paths, device name and URL as appropriate

Since I run HASS in Docker, I actually installed CATT on the server running HASS and then use SSH to remote out of the docker container to the server.  Seems kinda meta but it works.  But that's outside the scope of this post (I plan on a post soon on how to restrict SSH'ing so it's not a gaping security hole).

## Conclusion

CATT is definitely a bit more complicated to set up that Home Assistant Cast but it has a few advantages.  For one, it actually works (though I do hope that the HASS devs get it working consistently, its a really cool concept!).  Also, since it's all local you don't need to make your HASS instance open to the outside world and it should work even if your internet is down.
