---
title: "Easy Smart Vacation Mode Lighting with HomeAssistant"
author: "FuzzyMistborn"
date: 2020-05-10T18:42:49Z
slug: smart-vacation-mode-lighting
image: "header.png"
categories:
  - "Smart Home"
tags:
  - HomeAssistant
  - Vacation
  - Lighting
draft: false
---

Lighting definitely [helps](https://www.nytimes.com/2019/09/19/smarter-living/wirecutter/smart-lights-enhance-home-security-and-shine-a-light-on-crime.html) to [deter burglaries](https://www.npr.org/2016/02/23/466603833/should-you-leave-your-lights-on-at-night-it-depends) when you aren't home.  I'm old enough to remember having to pull out those plug in timers to turn a lamp on/off on a timer whenever my family would go on vacation.  But the issue there is that 1) it was a fixed time and 2) only a few lights in the house were able to do this.  The other option was to leave lights on all the time, but that's both wasteful and not very effective against convincing burglars that you're actually home.

There's obviously a lot of ways to do this.  The most common is to randomize the lights turning on/off between set times (say sunset and 10pm).  I initially went down this path using [Occusim](https://github.com/acockburn/occusim) but I hit 2 problems.  First, it requires [AppDaemon](https://github.com/home-assistant/appdaemon) which is a great tool for doing things in Python.  However, OccuSim was the only thing I was using AppDaemon for and I generally don't like one-off solutions like this because it's yet another thing to update and more importantly it required a lot of tweaking to get "right."  I had to think about where I was at different times of day which isn't always the same.  So while it allowed me to randomize lights on a schedule or at random times overall it wasn't a great solution.

# Replay Last Week's Light Schedule

By far the best way I've found to do this is to "replay" what the lights did the previous week.  So if on Saturday the lights in my bedroom turned on at 6:51am and off at 7:23am, then with my vacation mode setup the lights in the bedroom would do the exact same thing a week later.  By mimicking what I did in a past week it will 1) reflect a real schedule, 2) saves me from having to pre-program based on weekday/weekend, take into account the sunset, etc, and 3) with it being a week apart it's unlikely a criminal would realize that the lights are following any kind of pre-determined program.  Hat tip to [/u/atra-ignis](https://www.reddit.com/user/atra-ignis/) on [Reddit](https://www.reddit.com/r/homeassistant/comments/dnqxtl/what_vacation_mode_automations_do_you_have/f5h74du) for the initial concept and helping me get this working.  I did make some tweaks from there but credit for the idea goes to them.

## Setup

The two tools we need for this are HomeAssistant and NodeRed (though you can do the automation bit in HomeAssistant too if that's what you use).  This presumes you have all your lights set up in HomeAssistant, obviously.  Also, you'll need to have your [recorder/database](https://www.home-assistant.io/integrations/recorder/) set up to record for a least 1 week.

### HomeAssistant

For this, we're going to use the [History Stats](https://www.home-assistant.io/integrations/history_stats/) integration.  This integration has some pretty cool use cases but here what we'll use it for is to create a sensor that will represent with a 0 or a 1 whether a light is on or off.  Here is an example:

```yaml
sensor:
  - platform: history_stats
    name: "Replay Office"
    entity_id: light.office
    state: "on"
    type: count
    start: >
      {{ as_timestamp(now()) - (7*86400) }}
    duration: 00:00:30
```
Goes in the sensor portion of your configuration.yaml file

A lot of the above is self explanatory.  Name the sensor whatever you want, though I would strongly suggest starting with some of kind of prefix like "Replay" or "Vacation" which you'll see why when we get to NodeRed.  With the history_stats sensor you can define 2 of `start`, `end` or `duration`.  For our purposes we're using `start` and `duration`.  The start time is 7 days ago, so we create a template to determine that (there are 86400 seconds in a day).  Duration is how used to measure.  I keep mine to 30 seconds to get a fairly accurate picture of the changes.

Create a sensor for each light/switch/group you want to track.  Restart HomeAssistant and you should see something like this when you click on the sensor in the States page:

{{< figure src="vacation-light1.png" caption="1 represent 'on' and 0 represents 'off'" >}}

You'll also want some way of tracking whether you're on vacation or not.  For me I use an input_boolean called "Vacation Mode" (original I know) that I can manually toggle on/off, but actually is triggered by my Ecobee thermostat going into vacation mode.  You can set up vacations manually in the Ecobee app or what I do is create the vacation based on a vacation calendar in Google and use that information to trigger the vacation mode in Ecobee.

### NodeRed

The NodeRed setup is extremely simple.  I'll post the code below but here's a brief explainer of what it does.

{{< figure src="vacation-light2.png" caption="Vacation mode made simple" >}}

The first node is a state node that triggers when any of the replay sensor changes.  Instead of having to create a node for every single sensor, if you followed the naming suggestion I made above and everything is `sensor.replay_` then you can use a single node.  Just select "substring" instead of "exact" in the node settings and don't put anything for the state.

{{< figure src="vacation-light3.png" caption="Select 'substring'" >}}

The next node is a check to make sure that vacation mode is turned on.  Then there's a change node to change the "1" payload to "on" and the "0" payload to "off."  Finally there's a switch node to route the changes to the right light/switch you want to control, depending on which `sensor.replay_` is changing, with a corresponding call service node to turn the light on/off depending on the payload.

{{< figure src="vacation-light4.png" caption="Using {{payload}} allows you to have one node for turn on and off" >}}

As promised, here's the NodeRed code:

```json
[{"id":"83bc26c9.2c2288","type":"server-state-changed","z":"9a7feaee.12c878","name":"Replay","server":"63517380.eb951c","version":1,"entityidfilter":"sensor.replay_","entityidfiltertype":"substring","outputinitially":false,"state_type":"str","haltifstate":"","halt_if_type":"str","halt_if_compare":"is","outputs":1,"output_only_on_state_change":true,"x":250,"y":4300,"wires":[["7081a406.114374"]]},{"id":"7081a406.114374","type":"api-current-state","z":"9a7feaee.12c878","name":"Vacation Mode?","server":"63517380.eb951c","version":1,"outputs":2,"halt_if":"on","halt_if_type":"str","halt_if_compare":"is","override_topic":false,"entity_id":"input_boolean.vacation_mode","state_type":"str","state_location":"","override_payload":"none","entity_location":"","override_data":"none","blockInputOverrides":false,"x":400,"y":4300,"wires":[["89580e3b.3d991"],[]]},{"id":"89580e3b.3d991","type":"change","z":"9a7feaee.12c878","name":"State","rules":[{"t":"change","p":"payload","pt":"msg","from":"1","fromt":"num","to":"on","tot":"str"},{"t":"change","p":"payload","pt":"msg","from":"0","fromt":"num","to":"off","tot":"str"}],"action":"","property":"","from":"","to":"","reg":false,"x":550,"y":4300,"wires":[["261a9672.986142"]]},{"id":"261a9672.986142","type":"switch","z":"9a7feaee.12c878","name":"Switch","property":"data.entity_id","propertyType":"msg","rules":[{"t":"eq","v":"sensor.replay_basement","vt":"str"},{"t":"eq","v":"sensor.replay_office","vt":"str"},{"t":"eq","v":"sensor.replay_kitchen","vt":"str"}],"checkall":"true","repair":false,"outputs":3,"x":670,"y":4300,"wires":[["bfe718.3fb748e8"],["3fdd00a1.a644f"],["b40d6311.da7848"]]},{"id":"df4ffbf5.3de44","type":"comment","z":"9a7feaee.12c878","name":"Vacation Mode - Replay","info":"","x":300,"y":4200,"wires":[]},{"id":"bfe718.3fb748e8","type":"api-call-service","z":"9a7feaee.12c878","name":"Basement","server":"63517380.eb951c","version":1,"debugenabled":false,"service_domain":"light","service":"turn_{{payload}}","entityId":"light.basement","data":"","dataType":"json","mergecontext":"","output_location":"","output_location_type":"none","mustacheAltTags":false,"x":820,"y":4260,"wires":[[]]},{"id":"3fdd00a1.a644f","type":"api-call-service","z":"9a7feaee.12c878","name":"Office","server":"63517380.eb951c","version":1,"debugenabled":false,"service_domain":"light","service":"turn_{{payload}}","entityId":"light.office","data":"","dataType":"json","mergecontext":"","output_location":"","output_location_type":"none","mustacheAltTags":false,"x":810,"y":4300,"wires":[[]]},{"id":"b40d6311.da7848","type":"api-call-service","z":"9a7feaee.12c878","name":"Kitchen","server":"63517380.eb951c","version":1,"debugenabled":false,"service_domain":"switch","service":"turn_{{payload}}","entityId":"switch.kitchen","data":"","dataType":"json","mergecontext":"","output_location":"","output_location_type":"none","mustacheAltTags":false,"x":820,"y":4340,"wires":[[]]},{"id":"63517380.eb951c","type":"server","z":"","name":"Home Assistant","legacy":false,"rejectUnauthorizedCerts":false,"ha_boolean":"y|yes|true|on|home|open","connectionDelay":true,"cacheJson":true}]
```

# Conclusion

That's it.  Now whenever you turn on vacation mode in HomeAssistant the lights will simply repeat what they did the week before.  Even if you're on vacation for multiple weeks it won't matter, it will just repeat what the lights did the previous week (which is the same as the previous week).  While some very clever criminal might pick up on the fact the lights keep repeating exactly the same week in, week out that's fairly unlikely.
