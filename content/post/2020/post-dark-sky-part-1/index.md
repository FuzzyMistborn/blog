---
title: "Weather in a post DarkSky world"
author: "FuzzyMistborn"
date: 2020-11-09T14:53:38Z
image: "header.jpeg"
slug: weather-in-a-post-darksky-world
categories:
  - "Smart Home"
tags:
  - RTL433
  - HomeAssistant
  - "Dark Sky"
draft: false
---

Back on April 1st, DarkSky [announced](https://blog.darksky.net/dark-sky-has-a-new-home/) that it had been purchased by Apple and would be shutting down both it's Android app and API.  The API will continue to function "through the end of 2021," but there are no new signups permitted.

This is extremely disappointing as DarkSky had a fantastic API and very generous limits for free use (1k a day, so you could easily pull updates every 10-15 minutes without issue).  It also was super accurate.  Once the API goes away, it will be sorely missed as there's no solution like it out there that I have found that 1) has a free API and 2) is mostly accurate, and 3) has as much information available.  While I know I still have over a year left before the API goes away, since it IS going away I figured I needed to start exploring my alternative options.

The main things I was looking for were: 1) weather forecast for the next couple of days, 2) cloud cover (use this for a few spots were I don't have light sensors but want some kind of threshold for my motion senor lights), 3) precipitation (ie is it raining/how much), and 4) high/low temperature and a bonus for wind chill/apparent temp.

# Options out there

Pulling up the [list of HomeAssistant weather integrations](https://www.home-assistant.io/integrations/#weather), there seem like a decent number of options.  A few require hardware though (like Ecobee, Neatmo, and Ambient) so not for everyone.  A few are also international only/don't focus on the USA which further limits the options.  The ones I ended up trying were: 1) AccuWeather, 2) OpenWeatherMap, and 3) the National Weather Service.  None are as good as DarkSky and in the end I've had to cobble together multiple services to accomplish what DarkSky easily accomplished.

## Accuweather

AccuWeather is a great service (it's the weather app I use on my phone).  However, the API is extremely limited (only **50** calls a day, or twice an hour) and extremely limited information/sensors.  In terms of the data provided and what I needed, it hits most of the boxes.  However, the lack of long-term weather forecast (limited to only current weather unless you want to further limit your updates to once an hour) and the limited updates kinda kills it for me.  If it allowed just 50 more calls a day (100) so I could update every 15 minutes I might go for it.  The lowest paid tier is $25/month which is way too expensive for what I need.

{{< figure src="dark-sky-part1-1.png" caption="Sensors available" >}}

Opinion: Accuweather is a viable, though extremely limited, option due to the API limitations.

## OpenWeatherMap

This one seemed like it would be the solution.  Open data with a decent API (60 calls a minute!).  It also has a few different ways of configuring it:

{{< figure src="dark-sky-part1-2.png" >}}

Per the docs, the mode options are "`hourly` for a three-hour forecast, `daily` for daily forecast, or `freedaily` for a five-day forecast with the free tier."  I chose "free daily" as I really was looking for a long-term forecast, which also generated a lot of sensors similar to what DarkSky used to provide.  I like that things seem to update frequently but I've also run into issues where sensors appear to get stuck (for instance, it says the cloud coverage here has been at 0% for 19 hours, which is possible but I doubt it considering I see a few clouds out right now).

{{< figure src="dark-sky-part1-3.png" caption="Many more sensor this time" >}}

Opinion: Like the extra API calls though question the data accuracy.

## National Weather Service

This one is great if all you are looking for is a forecast.  Ultimately a lot of the data used to power the other weather services out there comes from NOAA/NWS so it's fun to get the data straight from the source.  However, as the integration stands right now, there are no sensors associated with it, though you can create your own with some templates as the raw data is all there.

{{< figure src="dark-sky-part1-4.png" caption="This is all you get...." >}}

Here's an example of a high and low temperature sensor you can create:

```yaml
  - platform: template
    sensors:
      nws_high_temp:
        friendly_name: "High Temperature"
        device_class: temperature
        unit_of_measurement: "°F"
        unique_id: high_temp
        value_template: >
          {% if states('weather.nws') != 'unavailable' and state_attr('weather.nws', 'forecast')[0].daytime == true %}
            {{ state_attr('weather.nws', 'forecast')[0].temperature }}
          {% elif states('weather.nws') != 'unavailable' %}
            {{ state_attr('weather.nws', 'forecast')[1].temperature }}
          {% else %}
            Unavailable
          {% endif %}
      nws_low_temp:
        friendly_name: "Low Temperature"
        device_class: temperature
        unit_of_measurement: "°F"
        unique_id: low_temp
        value_template: >
          {% if states('weather.nws') != 'unavailable' and state_attr('weather.nws', 'forecast')[0].daytime == false %}
            {{ state_attr('weather.nws', 'forecast')[0].temperature }}
          {% elif states('weather.nws') != 'unavailable' %}
            {{ state_attr('weather.nws', 'forecast')[1].temperature }}
          {% else %}
            Unavailable
          {% endif %}
```

Again, it's possible to make sensors but it requires some extra work. I also have run into some issues where on start up I get errors and every now and then the API goes down or there are issues.

Opinion: Best for forecast, but terrible for sensors and has some reliability issues.

# Conclusion

So which one did I pick?  As I mentioned above, I chose to create a frankenstein solution built on a few of these options, combined with my own weather station in my back yard.  I chose the NWS integration for the forecast, and I created a few sensors based on the data as well (high/low temperature and chance of rain).  I then used OpenWeatherMap for some of the sensors I was looking for (cloud cover, precipitation type), though now that I'm looking at Accuweather again I might switch to that one instead.  Just as a quick aside, how none of the integrations offered a high/low temperature sensor is mind boggling to me.

I'll have another post up soon regarding my weather station and how I brought all of these pieces together.  Unfortunately, my quest for a DarkSky replacement led me to realize there was no adequate replacement and I had to roll my own.  I truly wish I could say that there was a 1-1 replacement, or even something that was 75% as good.  But in reality, DarkSky was a rare gem and is going to be sorely missed when it goes away.

#RIPDarkSky

