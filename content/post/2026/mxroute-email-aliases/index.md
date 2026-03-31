---
title: MXroute Email Aliases - A SimpleLogin Replacement
author: FuzzyMistborn
date: 2026-03-30
slug: mxroute-email-aliases
image:
categories:
  - Self-Hosting
tags:
  - mxroute
  - email
  - simplelogin
draft: false
---
Recently I discovered that my favorite email service (MXroute) introduced an API which has opened up a lot of fun new possibilities with the service, including letting me recreate most (if not all) of the functionality of SimpleLogin.  In this post I'm going to detail some of what SimpleLogin is, why you should use a service like it, and if you're an MXroute user some cool apps to check out.
# SimpleLogin

So what is SimpleLogin?  Simply (heh) put, it's a service that lets you create email forwarders.  For example, if you're signing up for some sketchy service you aren't 100% sure about, you can create `sketchyservice@example.com` as an email address and sign up with that.  All the email sent to that address can then be forwarded to your actual email address and nobody on the other side is the wiser.

I've been using SimpleLogin now since 2021 (so almost 5 years) and really have had few complaints.  It got bought/acquired by [Proton in 2022](https://techcrunch.com/2022/04/08/proton-buys-simplelogin/) (the people behind ProtonMail and other privacy-focused services) and IMO I think Proton has done a good job of keeping the product alive, though I haven't seen a whole lot of innovation/development.

As mentioned above, the main usecase is to sign up for services with what is essentially a disposable email address.  Instead of having to worry about not being able to unsubscribe to emails from a company (I think we all know one company/email that we just cannot unsubscribe to), you just turn off/delete the forwarder and no more emails!  The other advantage I see is that if there is a data breach, your real email address isn't out there.  Moreover, having forwarder addresses like this lets you track down the source of a breach (or even see if a company sold your email address/data to another company).

I tried self-hosting SimpleLogin on a number of occasions because it is [open source](https://github.com/simple-login), but I could never get it to work.  Because *self-hosting email is awful*.  And nobody should do it unless you truly enjoy bashing your head against the desk and fighting spam/IP block lists.  Given the relatively low price of SimpleLogin ($30 for the year, though looks like they raised the price to $36 a year) I was content to continue paying for the service.
# MXroute

Since self-hosting emails is not an option, a few years ago I started exploring alternatives to GMail (because Google being Google).  First I tried ProtonMail, but didn't like the Android app (didn't sync read emails for notifications, which drove me crazy) and having to use the Bridge to connect to something like Thunderbird wasn't the end of the world but was limiting.  Then I tried FastMail and generally liked that as an option.  But then I stumbled onto MXroute in early 2022 and I have not looked back.  The first year I purchased a yearly subscription, but on Black Friday that year for just $100 I got a lifetime subscription to 10 gigs of storage.  The packages have changed and prices have gone up ([and there have been changes to the lifetime plan](https://blog.mxroute.com/moving-forward-with-lifetime-plans-smarter-this-time/)), but I still think it's worth it.

This is in no ways a paid advertisement, but I simply cannot rave enough about MXroute.  The owner, Jarland, has quite the personality if you browse around various forums and places you'll see what I mean.  In my very few interactions with him via support tickets, the guy *clearly* knows his stuff and is incredibly passionate about what he does.  Moreover, he takes things *seriously*.  If you at all end up on his bad side (cough cough spammer cough cough) [he does not pull his punches](https://mxroutespammer.com/).

Also, it's important to note that there are *no free trials*.  My advice if you're interested in the service is buy a year, test it out, then go for the Black Friday sale.  [Usually there are some good deals](https://mxroute.blackfriday/).
## MXroute Aliases

So there I was one day a week ago, logging into the webmail page for my email and I noticed I had an SSL cert error.  Well that was weird.  So I did some poking around trying to figure out what was going on, which led me to the MXroute subreddit.*  And that's where I learned that not only does MXroute offer unlimited email aliases/forwarding, but there's a new *[API](https://api.mxroute.com/docs#description/introduction)* ([as of 3 months ago](https://www.reddit.com/r/mxroute/comments/1q4xs8s/new_mxroute_api/)) for setting up those aliases.  And people have taken advantage and written some really cool apps!

The first I found is [mxroute-alias-manager](https://gitlab.com/tomhello56/mxroute-alias-manager).  This is what sold me on ditching SimpleLogin.  It's incredibly easy to set up and has a really straightforward and polished UI for creating and managing your email aliases on MXroute.  Really there's not much to the setup: it's just one container, you need to generate an API key from MXroute and configure your email server/username/email domains to use.  And boom, all set.

> Oh...I did have some permission issues with the docker container in bind mount.  So you may need to create (I used `touch`) the following files: `config.json`, `dest_templates.json`, `labels.json`, `tags-metadata.json`, and `users.json`

The second app I've run into and tested so far is a [Bitwarden integration](https://github.com/bfpimentel/bitwarden-mxroute).  Bitwarden offers options to generate usernames/email addresses with services like SimpleLogin or AnnonAddy, which simplifies the creation of mostly anonymous logins.  With the MXroute Bitwarden integration, you can generate aliases on MXroute for Bitwarden.  The only "gotcha" I had with this one is that I needed to set up a reverse-proxy with SSL in order to use it with the Android app.  It did not like using a non-HTTPS IP address of the local server.  Which is not an issue for me, so more of a heads up.
# Conclusion

In the end, I spent an evening migrating all my aliases off of SimpeLogin and moved my email completely to MXroute.  I wasn't able to migrate some logins off of my `sl.example.com` setup, so unfortunately I've had to retain that for legacy purposes.  But now if I ever have to provide an email address over the phone or in person it'll be a little bit easier to say.  I can now save $36 a year, which really wasn't my main issue with SimpleLogin but I'll happily save on one more subscription.

In summary: if you're using MXroute, take a look at the awesome projects out there!  It's really incredible and I think it's just the beginning.

`*` I did ultimately figure out what my SSL cert issue was.  Turns out there's a new [management panel](http://panel.mxroute.com/) that largely supplants the old DirectAdmin control panel, and somehow some of my settings involving the SSL certs got wonky.  That is probably my only complaint about MXroute: it's not the easiest service to get configured and things move around, but I do think things are getting better and the new panel is a step in the right direction.