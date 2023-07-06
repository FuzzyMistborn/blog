---
title: "Bye Bye Minio, Hello Restic Rest Server!"
author: "FuzzyMistborn"
date: 2023-07-06T11:01:00Z
slug: restic-server-over-minion
categories:
  - "Linux"
tags:
  - Backup
  - Restic
  - Autorestic
  - Minio
  - S3
---

Previously, I wrote about [Minio](https://blog.fuzzymistborn.com/backup-restic-minio/), an S3 compatible object storage solution, as the backend for backing up my data locally using Restic.  And largely it worked great.  I never had an issue where data wouldn't be sent or anything along those lines (which ultimately is what matters here).  But I had many, many issues when it came time to update.

## Minio Issues

Admittedly, I was very infrequent with my updates (anywhere from 6 months to a year).  Largely that was because I'd forget I was running Minio as it 1) just kept working and 2) since I rarely log into my Synology box I'd forget about updates.  Plus, since I don't keep my Synology docker-compose file in my infra repo, I don't get automatic update notifications like I do with Rennovatebot.  This definitely is largely a "me" problem, but let's talk about the updates themselves.

Whenever I would update, I'd usually run into  a massive breaking change that would take hours (sometimes over multiple days) to resolve.  And this last time the breaking change was a doozey.  As best I understand it, they [deprecated the underlying filesystem](https://min.io/docs/minio/container/operations/install-deploy-manage/migrate-fs-gateway.html) used by default with the Docker container sometime in 2020.  And as of a release in October 2022, the code was removed.  That's fine, I usually don't have an issue with deprecations.  However, what was absolutely maddening about this change is that there was no automated migration for users, and in fact, the ONLY way to update is to spin up a new instance of Minio and **COPY ALL THE DATA** over with various commands (and basically going over HTTP).  You can't just spin up a new instance and point it at the older folder structure/data.

I also ran into a number of other issues trying to follow the documentation, namely the `mc` binary isn't included in the Minio server docker container, so I had to find a way to install the binary.  Then there were some version incompatibilities I had to deal with.  And then the final nail in the coffin was when I ran the `mc mirror` command.  A number of errors popped up that gave me serious concerns as to whether the data was being transferred over.  That left me with 2 options: 1) spin up a new Minio instance and forget all the data, and maybe find myself in another upgrade hell situation in another year or 2) still forget about the data but find a new solution.  I chose #2 because fool me once, shame on me.  Fool me twice, I ain't gonna let it get to thrice.

## Minio Alternative - Restic Rest Server

The solution I came across thanks to user @TheDragon on the Self-Hosted podcast Discord server is a [rest server](https://github.com/restic/rest-server) created by the restic devs.  It is a very lightweight server that basically provides a way for data to be transferred over HTTP.  And while Minio wasn't resource heavy, I didn't really *need* S3-compatible object storage for just backing up my data.  I just wanted an easy way to send my restic backups to a different host without having to use SSH/FTP.

It's really easy to spin up.  Here's my docker-compose:

```yaml
  restic-server:
    image: restic/rest-server:0.12.0
    container_name: restic-server
    volumes:
      - /YOURMOUNTPOINT:/data
    ports:
      - 8000:8000
    restart: unless-stopped
```

Yep, that's it!  Once the server is up you create a user with `docker exec -it restic_server create_user myuser` and pick a password.  It was also pretty easy to migrate my Autorestic configs as the Rest server is a [supported backend](https://autorestic.vercel.app/backend/available#rest-server).

I did toy around with the idea of running the rest server on my main proxmox host and have the folder mounted over NFS.  However, upon reflection I realized that was probably a poor idea (and in fact when I tried it the logs kept nagging me that it was a bad idea).  If there ever was a disconnect (for whatever reason) between the host and my Synology the data wouldn't get backed up.  Or well...it would but on my host which isn't what I want.  So instead I set up the rest server on my Synology.  To get update notifications I'm tracking the Github releases page and also left the docker-compose snippet in my Proxmox host's config (without running it) so that way Rennovatebot will also find the changes.

## Final Thoughts

Some other fun things for those who might be interested is that you can run the rest server in "append only" mode which prevents deletion/modification of existing backups.  Handy if you want to prevent any kind of ransomware infecting your backups.  Also, there's a way to export Prometheus/Grafana data for you data nerds out there.

And in terms of my old data, I left it on my Synology for now, and if I find myself needing it in the next few months I can spin up Minio for a minute to pull the data.  And after a few months, I'll just delete the data.

So if you're using MInio *just* for backups, take a look at the restic rest server.  It's much simpler to spin up, works just as well, and (hopefully) shouldn't be nearly as much of a PITA to update!