---
title: "Automating Vacation Mode"
author: "FuzzyMistborn"
date: 2020-05-18T20:28:46Z
slug: automating-vacation-mode
categories:
  - "Smart Home"
tags:
  - Vacation
  - HomeAssistant
draft: false
---

Last week I wrote up about [how to set up vacation mode for your lights easily](/smart-vacation-mode-lighting/).  This week we're going to complete the loop a bit and automate turning on vacation mode. **Note this setup requires an Ecobee thermostat**.  It's a popular thermostat so this may be of some use to folks.  I like the Ecobee vacation mode because it allows me to set up a permanent hold whenever I'm not at home for an extended period of time, which usually coincides with me being on vacation/away from home.  Thanks to HomeAssistant you can set up a vacation on your Ecobee from a Google Calendar or other supported calendar (I used CalDAV).

Now you can set up a vacation from either the app or on the Ecobee website.  So you may be asking "why do this?"  The answer is I'm lazy and I hate having to open another app/webpage when I already put vacations in my calendar.  So why not automate it at that point?

## Calendar

There are two main calendar options: [CalDAV](https://www.home-assistant.io/integrations/caldav/) and [Google Calendar](https://www.home-assistant.io/integrations/calendar.google/).  The HASS documentation is pretty decent for these so I'm not going to spend a lot of time on how to set them up.  For our purposes it doesn't matter which one you use, just use whichever one you use/are most comfortable with.

Once you get your calendars imported, find the `entity_id` for your vacation calendar.  I find it useful to have a separate calendar for vacation but you could also use another calendar and just use a search/regex to pull out your vacation entities.  Either way, look for a `calendar.` entry in your states page of HASS and use that for the below automations.

## Automation

Since I use NodeRed the below is how I got things to work.  I'll share an automation for HomeAssistant that _should_ work but I don't make any promises.  Here's a visual of what the flow looks like (code will be towards the end of the post).

{{< figure src="automated-vacation-mode1.png" >}}

The first node is simply a trigger node to start the flow when the calendar in HomeAssistant goes from "off" to "on" (ie the calendar event is starting).  You will need to change the `entity_id` to match your calendar's name.

The next 5 flows use templates to set the various variables we will need later when calling the `ecobee.create_vacation` service call in HomeAssistant.  You will need to adjust the calendar name in each node to match your own calendar name.  For the Function node, you will need to adjust the `entity_id` of the thermostat to yours and also adjust the temperature presets (can be in Celsius or Fahrenheit).  You'll need to do the same in the Create Vacation service node.

That's it.  Now whenever the calendar reaches an event on your vacation calendar, the Ecobee vacation mode will automatically be set for you.  I then use proximity to trigger a flow/automation to turn on my vacation `input_boolean` when I get more than 20 miles from home and the Ecobee is in vacation mode.  And then same works in reverse (when I go under 20 miles and the `input_boolean` is on, it turns off the `input_boolean`).

### NodeRed Code Export

```json
[{"id":"455725fe.32e6a4","type":"comment","z":"f89809b5.67a0a8","name":"Vacation Mode","info":"","x":860,"y":760,"wires":[]},{"id":"ceef80b3.bd2ec","type":"trigger-state","z":"f89809b5.67a0a8","name":"Vacay Start","server":"63517380.eb951c","exposeToHomeAssistant":false,"haConfig":[{"property":"name","value":""},{"property":"icon","value":""}],"entityid":"calendar.vacation","entityidfiltertype":"exact","debugenabled":false,"constraints":[{"id":"yi1ia7zhq3q","targetType":"this_entity","targetValue":"","propertyType":"current_state","propertyValue":"new_state.state","comparatorType":"is","comparatorValueDatatype":"str","comparatorValue":"on"},{"id":"ywqkg3b9vvn","targetType":"this_entity","targetValue":"","propertyType":"previous_state","propertyValue":"old_state.state","comparatorType":"is","comparatorValueDatatype":"str","comparatorValue":"off"}],"constraintsmustmatch":"all","outputs":2,"customoutputs":[],"outputinitially":false,"state_type":"str","x":850,"y":820,"wires":[["9409550f.7ac018"],[]]},{"id":"57cb7aa3.2f8224","type":"api-call-service","z":"f89809b5.67a0a8","name":"Create Vacation","server":"63517380.eb951c","version":1,"debugenabled":false,"service_domain":"ecobee","service":"create_vacation","entityId":"","data":"{\"entity_id\":\"climate.ecobee\",\"vacation_name\":\"{{payload.vacation_name}}\",\"cool_temp\":\"78\",\"heat_temp\":\"66\",\"start_date\":\"{{payload.start_date}}\",\"start_time\":\"{{payload.start_time}}\",\"end_date\":\"{{payload.end_date}}\",\"end_time\":\"{{payload.end_time}}\"}","dataType":"json","mergecontext":"","output_location":"payload","output_location_type":"msg","mustacheAltTags":false,"x":1500,"y":780,"wires":[[]]},{"id":"9409550f.7ac018","type":"api-render-template","z":"f89809b5.67a0a8","name":"Vacay Name","server":"63517380.eb951c","template":"{{ state_attr('calendar.vacation', 'message') }}","resultsLocation":"vacay_name","resultsLocationType":"msg","templateLocation":"","templateLocationType":"none","x":1110,"y":740,"wires":[["2a3c6979.d3f7e6"]]},{"id":"2a3c6979.d3f7e6","type":"api-render-template","z":"f89809b5.67a0a8","name":"Start Date","server":"63517380.eb951c","template":"{{ as_timestamp(state_attr('calendar.vacation', 'start_time')) | timestamp_custom(\"%Y-%m-%d\") }}","resultsLocation":"start_date","resultsLocationType":"msg","templateLocation":"","templateLocationType":"none","x":1100,"y":780,"wires":[["f1e211f.564267"]]},{"id":"f1e211f.564267","type":"api-render-template","z":"f89809b5.67a0a8","name":"Start Time","server":"63517380.eb951c","template":"{{ as_timestamp(state_attr('calendar.vacation', 'start_time')) | timestamp_custom(\"%H:%M:%S\") }}","resultsLocation":"start_time","resultsLocationType":"msg","templateLocation":"","templateLocationType":"none","x":1110,"y":820,"wires":[["227d98a3.b79e78"]]},{"id":"227d98a3.b79e78","type":"api-render-template","z":"f89809b5.67a0a8","name":"End Date","server":"63517380.eb951c","template":"{{ as_timestamp(state_attr('calendar.vacation', 'end_time')) | timestamp_custom(\"%Y-%m-%d\") }}","resultsLocation":"end_date","resultsLocationType":"msg","templateLocation":"","templateLocationType":"none","x":1300,"y":740,"wires":[["c292db2d.1b8f38"]]},{"id":"c292db2d.1b8f38","type":"api-render-template","z":"f89809b5.67a0a8","name":"End Time","server":"63517380.eb951c","template":"{{ as_timestamp(state_attr('calendar.vacation', 'end_time')) | timestamp_custom(\"%H:%M:%S\") }}","resultsLocation":"end_time","resultsLocationType":"msg","templateLocation":"","templateLocationType":"none","x":1300,"y":780,"wires":[["cf86984c.4d0d18"]]},{"id":"cf86984c.4d0d18","type":"function","z":"f89809b5.67a0a8","name":"Set Payload","func":"newmsg = {}\n\nnewmsg.payload = { \"entity_id\": \"climate.ecobee\", \"vacation_name\": (msg.vacay_name), \"cool_temp\":\"78\", \"heat_temp\":\"62\", \"start_date\": (msg.start_date), \"start_time\": (msg.start_time), \"end_date\": (msg.end_date), \"end_time\": (msg.end_time) }\n\nreturn newmsg;\n","outputs":1,"noerr":0,"x":1310,"y":820,"wires":[["57cb7aa3.2f8224"]]},{"id":"63517380.eb951c","type":"server","z":"","name":"Home Assistant","legacy":false,"rejectUnauthorizedCerts":false,"ha_boolean":"y|yes|true|on|home|open","connectionDelay":true,"cacheJson":true}]
```

### HomeAssistant Automation

```yaml
- alias: "Ecobee Create Vacation"
  trigger:
    platform: state
    entity_id: calendar.YOUR_CALENDAR
    from: "off"
    to: "on"
  action:
    service: ecobee.create_vacation
    data_template:
      entity_id: climate.YOUR_THERMOSTAT
      vacation_name: "{{ state_attr('calendar.YOUR_CALENDAR', 'message') }}"
      cool_temp: 78
      heat_temp: 62
      start_date: "{{ as_timestamp(state_attr('calendar.YOUR_CALENDAR', 'start_time')) | timestamp_custom('%Y-%m-%d') }}"
      start_time: "{{ as_timestamp(state_attr('calendar.YOUR_CALENDAR', 'start_time')) | timestamp_custom('%H:%M:%S') }}"
      end_date: "{{ as_timestamp(state_attr('calendar.YOUR_CALENDAR', 'end_time')) | timestamp_custom('%Y-%m-%d') }}"
      end_time: "{{ as_timestamp(state_attr('calendar.YOUR_CALENDAR', 'end_time')) | timestamp_custom('%H:%M:%S') }}"
```
Change "YOUR_THEROMSTAT" and "YOUR_CALENDAR" to match accordingly



