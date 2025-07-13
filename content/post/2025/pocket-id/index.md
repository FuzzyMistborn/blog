---
title: Setting up Pocket-ID with Caddy-Security
author: FuzzyMistborn
date: 2025-07-13
slug: pocket-id-setup
categories:
  - Networking
tags:
  - Pocket-ID
  - Caddy
  - Caddy-Security
  - OIDC
draft: false
---
I've long been interested in setting up an easy authentication system for logging into (and in some case protecting) services I self-host.  I looked into options like [Authentik](https://goauthentik.io/), [Authelia](https://www.authelia.com/), or [Keycloak](https://www.keycloak.org/) but they seemed overly complicated to me/difficult to set up.  

I've also wanted to check out [passkeys](https://fidoalliance.org/passkeys/), which are a relatively new form of authentication to replace passwords.  They have a lot of potential and I needed something to motivate me to start the transition.

I've seen a lot of mentions of Pocket-ID before, which is a lightweight OIDC (OpenID Connect) services that uses passkeys for authentication instead of dealing with passwords.  I figured I'd spend an evening spinning it up and seeing if it was as easy as people said it was.  Ultimately in some ways it was very easy, but in others I wanted to pull hair out.  I decided I should document how I got things working in case it was helpful to others.  I'm by no means an expert but I'm happy to help if you run into issues.
# Setting up Pocket-ID

Setting up Pocket-ID is really simple.  The [documentation](https://pocket-id.org/docs/introduction) is actually quite good, though I personally don't like the `.env` file approach given how I have my infra set up, so here's a docker-compose file with the key bits you need:

```yaml
pocket-id:
  image: ghcr.io/pocket-id/pocket-id:v1.6.2
  container_name: pocket-id
  restart: unless-stopped
  environment:
    - APP_URL=https://pocket-id.example.com
    - TRUST_PROXY=true
    - MAXMIND_LICENSE_KEY=YOUR_API_KEY
    - ENCRYPTION_KEY=YOUR_ENCRYPTION_KEY
    - PUID=1000
    - PGID=1000
  ports:
    - 1411:1411
  volumes:
    - /home/fuzzy/docker/pocketid/data:/app/data
```

You'll need a few things to set this up:

1) Maxmind License Key.  You sign up for a key [here](https://www.maxmind.com/en/geolite2/signup).  I've also started using this in conjunction with geoblocking using this [Caddy plugin](https://github.com/porech/caddy-maxmind-geolocation), so it's worth signing up (and it's free!).
2) As explained in the [docs](https://pocket-id.org/docs/configuration/environment-variables#encryption-keys), you can set an encryption key.  It's technically optional as you can run Pocket-ID without it, but I'd recommend this step.  Security is not a bad idea given that this is a gateway into some of your apps/services.

Also take a look through the various [environment variables](https://pocket-id.org/docs/configuration/environment-variables/#encryption-keys) you can set.  Most can also be set from the UI, but I find from a documentation perspective it's easier to set the variables and then commit it to GitHub so I can easily recreate things if needed.

That's it!  You'll also need to put it behind a reverse proxy **with HTTPS** for Pocket-ID/passkeys to work, but that's beyond the scope of this post.  Also consider looking at the hardening guide [here](https://pocket-id.org/docs/advanced/container-security-hardening).
# Configuring Pocket-ID
## Apps that Support OIDC

Many apps support OIDC which is an authentication protocol based on the OAuth 2.0 standard.  Pocket-ID's documentation has a [number of examples](https://pocket-id.org/docs/client-examples) of how to configure apps to work with OIDC, including Proxmox, Nextcloud, Audiobookshelf and others.  You can also search for "OIDC NAME-OF-APP" and probably find information on how to set up a few more.  In the end a good chunk of the apps I run support OIDC natively, which is great because there's no additional steps to get things to work.  The more complicated part (and what I struggled with) was configuring apps that *don't* support OIDC natively.
## Apps that Don't Support OIDC

In the case of apps that don't support OIDC natively, there are a few options.  Again, the [Pocket-ID docs](https://pocket-id.org/docs/guides/proxy-services) on the topic are a great starting point and certainly pointed me in the right direction.  Going through the list, I don't run Traefik (and didn't want to switch) so that wasn't an option.  I tried both [OAuth2-Proxy](https://oauth2-proxy.github.io/oauth2-proxy/) and [TinyAuth](https://tinyauth.app/).  I couldn't get Oauth2-Proxy to work, probably due to my somewhat complicated setup where I have multiple domains and I use a VPS to tunnel my traffic to home.  I liked  TinyAuth a lot, but ultimately discovered it wouldn't work in my setup because I have multiple domains and didn't want to have to work with multiple instances.

I was about to give up but then I decided to try [Caddy-Security](https://github.com/greenpau/caddy-security).  Full disclosure, there were [some vulnerabilities disclosed in 2023](https://blog.trailofbits.com/2023/09/18/security-flaws-in-an-sso-plugin-for-caddy/).  The developer of Caddy-Security has responded in [this issue on GitHub](https://github.com/greenpau/caddy-security/issues/349).  You make up your own mind as to whether to rely on Caddy-Security.  Personally, I think the security issues are unlikely to affect me in my home-lab, but if this was a corporate thing then it maybe worth closer investigation.

You'll need to use xCaddy to build your Caddy binary to include `github.com/greenpau/caddy-security`.  That's beyond the scope of this post as it depends on how you handle your Caddy binary.  I use Ansible so it was as simple as adding the repo to the `caddy_packages` variable.  Now comes the tricky part.

The [Pocket-ID documentation](https://pocket-id.org/docs/guides/proxy-services#caddy) is...fine but I think left a few things out that took me a while to figure out.  The first thing is step 1, creating the OIDC client in Pocket-ID.  You don't need to create multiple clients (unless you really are paranoid/want to).  I wanted something simple, so I have just one OIDC client for all of Caddy.  To handle that, for your callback URL, you will want to use a wildcard.  So instead of setting `https://nextcloud.example.com/caddy-security/oauth2/pocket-id/authorization-code-callback` and `https://homeassistant.example.com/caddy-security/oauth2/pocket-id/authorization-code-callback`, you can just do `https://*.example.com/caddy-security/oauth2/pocket-id/authorization-code-callback` where the `*` is the wildcard to handle all your subdomains.  Make sure you copy/save the `client_Id` and `client_secret`, you'll need those in a minute.

Also, keep in mind `pocket-id` in the URL is going to be directly tied into the next step when configuring Caddy-Security.  So if you change the provider below (I'll highlight what I mean) you'll need to adjust your callback URL.
### Caddyfile

I'm going to provide the relevant Caddyfile bits now, but scroll down if you want to understand how you can tweak this/things I discovered.  

Here's the top part of my Caddyfile (in the [global options block](https://caddyserver.com/docs/caddyfile/options)):

```caddyfile
{
    order authenticate before respond
    order authorize before basicauth

	# caddy-security
    security {
		oauth identity provider pocket-id {
			realm pocket-id
			driver generic
			client_id {{ secret_caddy_pocket_id_user }}
			client_secret {{ secret_caddy_pocket_id_key }}
			scopes openid email profile groups
			base_auth_url https://pocket-id.example.com
			metadata_url https://pocket-id.example.com/.well-known/openid-configuration
			delay_start 3
		}

		authentication portal pocket-id {
			crypto default token lifetime 86400
			enable identity provider pocket-id
			transform user {
				match realm pocket-id
				action add role user
			}
		}

		authorization policy pocket-id {
			set auth url /caddy-security/oauth2/pocket-id
			allow roles user
			inject headers with claims
		}
	}
}
```

Then, to make it easy to import into your existing config, I have the following snippet:

```caddyfile
(pocket-id) {
	@auth {
		path /caddy-security/*
	}
	route @auth {
		authenticate with pocket-id
	}
	route /* {
		authorize with pocket-id
	}
}
```

You can then import this snippet with just `import pocket-id` like this:

```
drop.fuzzymistborn.com {
	import pocket-id
	reverse_proxy localhost:3200
}
```
### Explanation/Things I Learned

So what's different between my Caddyfile and the Pocket-ID documentation?  A few things.

1) I changed the identity provider from `generic` to `pocket-id`.  Made more sense to me.  If you also want to change this value, this is what you need to change in your callback URL above for Pocket-ID.  IE `https://*.example.com/caddy-security/oauth2/generic/authorization-code-callback` versus `https://*.example.com/caddy-security/oauth2/pocket-id/authorization-code-callback`.  You'll also need to change the `realm` to match.
2) In the `scopes` i added `groups` which I'll talk about below.
3) I changed the `authentication portal` to `pocket-id`, again because I think that makes more sense than `myportal`.  I also changed the identity provider to `pocket-id` instead of `generic`.
4) I kept the `transform user` bit, but there's another example (in line with #2 above) where you can limit which Pocket-ID groups can log in.  I didn't go this route, but I'll document a bit how you'd do it if you want.
5) Again, in the `authorization policy` I changed things to `pocket-id` instead of `mypolicy` and `generic`.
6) Finally I used a [snippet](https://caddyserver.com/docs/caddyfile/concepts#snippets)to make repeating code easier.  Repeating myself again, but if you changed anything in the global options block, you'll need to change the reference in the `route @auth` and `route` blocks.

My approach will allow all users in Pocket-ID to be able to authenticate and log into any app/website protected by Pocket-ID and Caddy-Security.  For my use case, that's completely fine as it's just family using it.  But if you wanted to restrict certain pages to certain groups, here's how you'd go about it.
#### Restricting to Groups

[This post](https://github.com/greenpau/caddy-security/issues/378#issuecomment-2765955344) was key to figuring this one out.  But essentially the difference between this and the above is that we can create a group in Pocket-ID (and you'll want to limit the [OIDC client as well](https://pocket-id.org/docs/configuration/allowed-groups)).  In this case we'll create one called `private`.  Add the necessary users, then create the new authorization policy below.  Also, note that the `authentication portal` is different.  We removed this bit:

```
			transform user {
				match realm pocket-id
				action add role user
			}
```

That bit is what basically turned all users authenticating via Caddy-Security into a generic user (who could in turn authenticate with Pocket-ID).

Here is what your Caddyfile would look like if you wanted to limit a login to certain groups.

```caddyfile
{
    order authenticate before respond
    order authorize before basicauth

	# caddy-security
    security {
		oauth identity provider pocket-id {
			realm pocket-id
			driver generic
			client_id {{ secret_caddy_pocket_id_user }}
			client_secret {{ secret_caddy_pocket_id_key }}
			scopes openid email profile groups
			base_auth_url https://pocket-id.example.com
			metadata_url https://pocket-id.example.com/.well-known/openid-configuration
			delay_start 3
		}

		authentication portal pocket-id {
			crypto default token lifetime 86400
			enable identity provider pocket-id
		}

		authorization policy limited-group {
			set auth url /caddy-security/oauth2/pocket-id
			allow roles private
			inject headers with claims
		}
	}
}
```

Snippet would look something like this:

```
(limited-group) {
	@auth {
		path /caddy-security/*
	}
	route @auth {
		authenticate with pocket-id
	}
	route /* {
		authorize with limited-group
	}
}
```
#### Bypassing Auth

For some apps/services that have, for example, an API, you may not want to protect that aspect.  A great example is HealthChecks.  Protecting the `/ping` endpoint would mean clients wouldn't be able to just curl the URL, which would basically break the entire point of the app.  So I added a custom authorization policy for Healthchecks like this:

```caddyfile
authorization policy hc-pocket-id {
	set auth url /caddy-security/oauth2/pocket-id
	allow roles user
	inject headers with claims
	bypass uri prefix /ping/
	bypass uri prefix /api/
	bypass uri prefix /badge/
}
```

and then a custom snippet (or just included in the actual URL I'm setting up) like this:

```caddyfile
(hc-auth) {
	@auth {
		path /caddy-security/*
	}
	route @auth {
		authenticate with pocket-id
	}
	route /* {
		authorize with hc-pocket-id
	}
}
```
and 
```caddyfile
healthckecks.example.com {
	import hc-auth
	reverse_proxy localhost:8000
}
```

or 

```caddyfile
healthckecks.example.com {
	@auth {
		path /caddy-security/*
	}
	route @auth {
		authenticate with pocket-id
	}
	route /* {
		authorize with hc-pocket-id
	}
	reverse_proxy localhost:8000
}
```
### Further Reading

If you want some further reading, I found the following threads/posts incredibly helpful in figuring all this out:
* [https://github.com/greenpau/caddy-security/issues/378](https://github.com/greenpau/caddy-security/issues/378)
* [https://github.com/pocket-id/pocket-id/discussions/252](https://github.com/pocket-id/pocket-id/discussions/252)
* [https://www.reddit.com/r/selfhosted/comments/1jdq5xn/caddy_security_pocket_id_multiple_oidc_clients_my/](https://www.reddit.com/r/selfhosted/comments/1jdq5xn/caddy_security_pocket_id_multiple_oidc_clients_my/)

{{< youtube sPUkAm7yDlU >}}