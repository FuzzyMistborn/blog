---
title: "Using WakeOnLan with Opnsense and HomeAsssitant"
author: "FuzzyMistborn"
date: 2021-05-28T08:38:00Z
slug: opnsense-wol
image: "header.jpeg"
categories:
  - "Smart Home"
  - "Networking"
tags:
  - HomeAssistant
  - Opnsense
  - WakeOnLan
  - RestAPI
draft: false
---

Note: Significant hat tip here to [/u/abstractbarista](https://www.reddit.com/user/abstractbarista/) for [this guide](https://www.reddit.com/r/homeassistant/comments/bxniet/turn_on_lg_webos_tv_across_subnets_via_opnsense/).  Most of the steps below come from their guide.  The main differences being 1) little bit improved layout/format (subjective) and 2) I figured out how to do a call to just wake a single device.

# Introduction

[WakeOnLAN](https://en.wikipedia.org/wiki/Wake-on-LAN) is one of those things that you love to hate.  When it works, it's magical.  When it doesn't it's beyond frustrating.  My biggest annoyance is with my network setup, I have multiple VLANs/subnets, and WOL doesn't really like to be routed across subnets for reasons I only barely understand so I'm not going to try to explain.  To get around this, my solution for a long time was to have a Raspberry Pi Zero on the subnet I wanted with the `wakeonlan` package.  I then set up SSH keys and added it to HomeAssistant, along with a script I could call via a `shell_command`.  It worked great but having to poke firewall rules, having SSH keys on HomeAssistant, etc always made me a little uncomfortable.  

My bigger problem was that I needed a Pi Zero on the same subnet which usually wasn't a problem.  However I've been playing around with a homelab (my old retired server) but I didn't want it running 24/7 wasting power when I only use it sporadically.  Instead of having to shut it down/turn it back on (requiring me to trudge down to my basement) I figured I'd try using WOL and just suspending the server when I'm not using it.  Well I don't have a Wifi network for my Homelab VLAN so I can't use a Pi Zero, and I really didn't want to use a full Pi for something as simple as WOL.

Enter Opnsense.  I've been running Opnsense as my firewall for about 2 months now and I have to say I love it.  Coming from an Edgerouter the difference is just night and day.  The main thing I'm really loving is all the plugins and tools that are available.  You can do so much on your router if you run Opnsense/PFsense (depending on which is your cup of tea, not getting into the debate between the two here) it really is worth it.  I discovered Opnsense has a WOL plugin and found it worked great.  Worst case I could just log into Opnsense, go to the WOL service and wake up my homelab server.  But that's just too much effort when you can get it into HomeAssistant!

# Opnsense Setup

Opnsense has a REST API that you can call prettily easily, particularly when combined with HomeAssistant's [REST API command integration](https://www.home-assistant.io/integrations/rest_command/).  The documentation for the [WOL API](https://wiki.opnsense.org/development/api/plugins/wol.html) on Opnsense is....lacking.  However, the Reddit post from /u/abstractbarista linked above got me 90% of the way there.  Their solution was simply to wake all devices.  I wanted to target mine since I have a few that I like to sleep/wake up so I kept digging a bit.  Here's the basic steps:

1) Install the `os-wol` plugin in Opnsense by going to `System->Firmware->Plugins`.
2) Go to `Services->Wake on Lan` and click the plus icon in the bottom right corner next to "Wake All", and add your device/MAC address along with the interface.  I think this step is optional given the later steps but it can't hurt to add.
3) Next step is creating a REST API token.  You could use an existing Opnsense user but I'd suggest creating a separate one just for HASS.  Go to `System->Access->Users->Add`.  Pick a username (doesn't matter) and enter a stupidly long/secure password (you'll probably never need it).  Leave everything else as default. Click "Save and go back".
4) By default the user can't do anything.  You'll need to give it permission to access to the API.  Edit the user and scroll down to "Effective Privileges".  Click the edit button and search for "Services: Wake On Lan".  Select it and then save.  Then scroll down and create an API key by clicking the plus button.  You'll be prompted to download a txt file that will have the user/key you'll need later.  Save this somewhere for now.  Click Save at the bottom.
5) Depending on how you have your firewall rules set up, you probably need to create one to allow HomeAssistant to connect to the REST API on Opnsense.  I'm assuming you know how to create firewall rules for your network, but the specific rule you need is to allow traffic from your HomeAssitant instance to "This Firewall" on either HTTP or HTTPS (depending on whether you have HTTPS enabled on Opnsense).  Congrats, you're done with the setup on Opnsense.  The rest is easy.

# HomeAssistant Setup

As mentioned above, HomeAssistant has a REST Command integration.  

```
rest_command:
  wake_device:
      url: 'http://OPNSENSE_URL/api/wol/wol/set'
      method: POST
      payload: '{"wake":{"interface": "INTERFACE","mac": "DEVICE_MAC"}}'
      content_type:  'application/json'
      username: !secret opnsense_user
      password: !secret opnsense_key
```

There are a few things to note here.  First, the Opnsense URL should be either HTTP or HTTPS depending on your setup.  If you use HTTPS you made need to add `verify_ssl: false`.  The `/api/wol/wol/set` is the part that matters/shouldn't change.  Second, to find the value for the interface, you'll need to go to "Interfaces" in Opnsense and figure out the designation for the interface where the device you're trying to wake up is.  Just click on the interface and look at the URL.  You should see something like `/interfaces.php?if=opt5`.  `opt5` is what you want.  The device MAC is self explanatory.  For username and password, put the user/key from the txt file you downloaded during step 4 above.  Restart HomeAssistant and you now have a new service call, `rest_command.wake_device`.

From here, you can use the command however you want.  Personally I combine it along with a template switch and binary ping sensor so I can put my desktop to sleep/wake it up with a switch.  Totally up to you where you want to go from here.

Hope someone finds this useful, and again major thanks to /u/abstractbarista for the inspiration and most of the heavy lifting!