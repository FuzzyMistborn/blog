---
title: "Switching DNS Providers and Reverse Proxies - What could go wrong?"
author: "FuzzyMistborn"
date: 2021-08-04T08:32:00Z
slug: caddy-linode-changes
categories:
  - "Networking"
tags:
  - Caddy
  - Cloudflare
  - Linode
  - LEGO
  - SSL
  - Reverse Proxy
draft: false
---

So this post is going to be a bit different than usual.  No tutorial or guide, more of a discussion of some changes I've made on the backend to host this blog and some of my other self-hosted services.  Recently I've started using Ansible to deploy all my servers (you can see my setup [here](https://github.com/FuzzyMistborn/infra)).  I didn't convert my Linode VPS instance to Ansible because I didn't want to screw up how I had things.  But as I detailed below, I wanted to switch my DNS servers for my domains off Cloudflare.  I wanted to test the setup before making any permanent changes so I spun up a second Linode VPS.  And since I was doing *that* I figured why not just Ansibile-ize it?

So that's how I got here, but why the change?  Let me explain.

# Cloudflare/DNS Servers

I've been a big fan of Cloudflare for a long time.  They provide a tremendous product with great value for home users, including a CDN, DDoS protection, free SSL certs, and DNS servers just to name a few things.  Pretty much since my early days of self-hosting things, they have been my go-to.  I appreciated that I could point my domains to my home IP address and everything would be proxied/anonymized.  It may not really have gotten me any protection but it made me feel better.  I also appreciated that I had a level of DDoS protection from bots.

But as they say, if the product is free, you are the product.  Now that arguably may not be true in Cloudflare's case (I expect their goal is to convince people to tell their bosses to switch to Cloudflare at work and make money from the enterprise sector), but I've steadily grown more uncomfortable with the sheer amount of dominance that Cloudflare has over things.  Also, with Cloudflare handling the SSL certs and providing the CDN, it means that Cloudflare decrypts all traffic to its servers before reencrypting it when it leaves.  From a privacy standpoint, I slowly became less and less comfortable with this concept as well.  Not that there have been *any* reports of Cloudflare doing anything nefarious with data but it just didn't sit right with me anymore in this era of "big data."

So what is the alternative?  Well, there are a few.  My basic requirements were 1) free, 2) support DNS-01 ACME challenge for Let's Encrypt/ZeroSSL certs, and 3) support an API of some kind to allow dynamic DNS updates in case my home IP address changes (ideally with OPNsense as that's what I use).  There were a few options out there that fit the bill.  Ultimately I ended up switching to Linode's [DNS Manager](https://www.linode.com/docs/guides/dns-manager/).  Linode uses Cloudflare for DDoS mitigation, load balancing and distributed name servers.  But as best I can tell, NOT it's CDN so my traffic isn't proxied through Cloudflare's servers.

Adding a domain to Linode is super easy and I found the documentation here perfectly clear.  The major downside I've found with Linode is that it's slower than Cloudflare to propagate DNS changes.  With Cloudflare, I would create a new CNAME entry for example and it would be available in less than 5 minutes.  Linode seems to only update their records every 15 minutes or so, which in the grand scheme of things is fine.  I mean, how often do you really switch your DNS entries?  Linode also doesn't support DNSSEC yet but for my purposes that's fine.

So far I've switched this domain and another off Cloudflare to Linode and have had zero issues.  So I don't see any reason to switch back.

# NGINX/Reverse Proxy

So that was the DNS change.  While I was doing that I figured why not check out different reverse proxies (have I mentioned I'm a bit of a technomasochist?).  The main contenders I considered were Traefik and Caddy.  I know many people over on the Selfhosted subreddit *love* Traefik and sing its praises.  It's particularly great if you run lots of Docker containers as it handles reverse proxying to those really easily just by adding some environmental variables to the container in question.  I'd tried Traefik before and just...couldn't wrap my head around it.  Plus I found the configuration by labels just confusing as heck (and potentially making for a long docker-compose file!).  I also found the documentation sorely lacking and unfortunately when I was trying it the devs had just upgraded from v1 to v2, making a number of breaking changes and the guides out there on the internet hadn't been updated.  Overall, just very frustrating for me.  That left Caddy.

Caddy also had a major update from v1 to v2 last year and from what I can gather it was not a smooth update for all and there are still some things that aren't quite there yet (I'll explain more below).  And the [documentation](https://caddyserver.com/docs/) still is not very clear on all things.  But overall, I have found it to be remarkably simple to set up.  The feature I'm loving the most so far is that a lot of the defaults are things I already want, like some basic HTTP headers.  I don't have to declare them every single time.

For example, here is my NGINX config for Healthchecks:

```
server {
    listen         80;
    server_name    hc.fuzzymistborn.com;
    return         301 https://$host$request_uri;
}

server {

        listen 443 ssl;
        server_name hc.fuzzymistborn.com;

        ssl_certificate      /etc/nginx/ssl/cert.pem;
        ssl_certificate_key  /etc/nginx/ssl/key.pem;
        ssl_client_certificate /etc/nginx/ssl/cloudflare.crt;
        ssl_verify_client on;
        ssl_prefer_server_ciphers on;

    location / {

        proxy_pass http://healthchecks:8000/;
        proxy_set_header Host $host;
        proxy_redirect http:// https://;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $remote_addr;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

    }

}
```

Yes, there's probably something wrong in there but you'll see my point when you look at my Caddyfile:

```
hc.fuzzymistborn.com

reverse_proxy localhost:8000
```

Ok, not quite the full file (again, I'll explain later) but you see what I mean but how much simpler it is.  Caddy 1) by defaults upgrades everything from HTTP to HTTPS, 2) can handle the SSL cert generation if needed, and 3) takes care of most of the headers for you.  In some cases I still needed to add `X-Real-IP` and `X-Forwarded-Proto` but that can easily be handled.  Once you wrap your head around the principles of Caddy it's easy to see the allure and simplicity of it (and the much much shorter config file!).

It's not all sunshine and daisies though.  Here are some of my issues with Caddy.  First, if I was to define each subdomain like in my example above, it would fetch SSL certs for *each* subdomain.  Not very efficient, and while I don't have that many subdomains, it's enough that I don't want to deal with it.  To get around that, I wanted to use a wildcard cert.  To do that, you need to utilize the [handlers and host matchers](https://caddyserver.com/docs/caddyfile/patterns#wildcard-certificates), so my actual config looks more like this:

```
*.fuzzymistborn.com {

        @hc host hc.fuzzymistborn.com
        handle @hc {
                reverse_proxy localhost:8000
        }

}
```

Which then brings me to my second issue.  For some reason I'm not very clear on, Caddy in v2 decided to ditch using [LEGO](https://github.com/go-acme/lego) for it's DNS authentication and switched to [libdns](https://github.com/libdns/libdns) which is missing a LOT of providers that LEGO supports, including Linode in my case.  The previous plugin is [still available](https://github.com/caddy-dns/lego-deprecated) and can be installed but I found the documentation confusing on how exactly to implement it.  Instead, I just decided to use LEGO (which btw is probably my favorite name for something as it's for generating Let's Encrypt (LE) certs and it's written in GO, so LEGO is amazing) and pull the certs manually.  I then configured LEGO via a cronjob to renew the certs.  So I "lost" one of the main benefits of Caddy over NGINX.

A third issue is that Caddy is compartmentalized, meaning to get certain features you need to download/compile it into the binary.  Things like DNS resolvers aren't built into the default but must be added.  It's all relatively simple and I understand the reasoning behind it (makes it simpler to develop) but from an enduser it's confusing and at times frustrating.  For example, the DNS providers have to be individually added instead of in a single library/plugin.

Overall I'm not entirely sold on the benefits of Caddy over NGINX.  I like having a single, clean, simple config file and now that I've figured some things out I appreciate the defaults/basic structure.  But it was not simple and there are some definite quirks.  Honestly I'm not sure if I'll stick with it or switch back to NGINX as there is more documentation/support out there for NGINX than there is for Caddy.  If you're curious, you can see my Caddyfile over on my Ansible infra Github repo [here](https://github.com/FuzzyMistborn/infra/blob/main/roles/ambition/templates/Caddyfile.j2).

What's next for me is to set up some kind of VPN tunnel between my VPS and homelab so I don't need to expose my homelab to the outside world, probably using something like [Nebula](https://github.com/slackhq/nebula), though I have been playing around with a Wireguard tunnel too.  Once I get that going, I'll switch my last personal domain off Cloudflare.