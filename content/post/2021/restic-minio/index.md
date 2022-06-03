---
title: "Backing up your data with Restic (+ Autorestic) and Minio"
author: "FuzzyMistborn"
date: 2021-09-02T08:38:00Z
slug: backup-restic-minio
categories:
  - "Linux"
tags:
  - Backup
  - Restic
  - Autorestic
  - Minio
  - S3
draft: false
---

Having a good backup strategy has always been important to avoid data loss but is now even more important in this day and age of constant ransomware stories in the news.  Despite your best efforts to avoid clicking anything, all it takes is one slipup or mistake and your data can be lost.  I've long hunted for a good backup strategy and I think I've finally settled on a pretty good option utilizing Restic (plus a wrapper called Autorestic, more below) backing up data to my Synology NAS and to Backblaze's B2 Cloud Storage.

# Backup Strategies

Before getting too far into the weeds, let's talk basics about backup strategies.  For a long time, the advice has been 1 is none, two is one, and three is good.  IE having one copy of your data is as good as having none, two copies means you really have just one, and three is a good start.  This advice can be summarized with the 3-2-1 backup strategy, where you have three copies of your data on two different media with one being offsite.  I think this generally is sound advice to follow, though personally I don't think two different forms of media is as important for home/personal use.  Let's be honest, how many of you have tape backups of your data?  I bet more than 90% of people just have the data backed up to hard drives.  So 

Recently, Backblaze wrote a [fantastic article](https://www.backblaze.com/blog/whats-the-diff-3-2-1-vs-3-2-1-1-0-vs-4-3-2/) arguing that it may be time to rethink the 3-2-1 strategy because ransomware is growing more clever and is going after backups.  So you don't want your backups to be accessible and be offline.  The article discuss a 3-2-1-1-0 and 4-3-2 strategies.  Personally I follow a sort of hybrid where I have four copies of my data backed up to 3 different devices, one of which is offsite and an extra copy that's stored offsite AND offline (so I guess 4-3-1-1?).  I have the "live" copy of my data, plus a copy backed up regularly to my Synology and to B2, and then most of my most important data gets backed up to an external HDD that lives in my office desk drawer.  The external drive only comes home once a month for an update and then goes straight back to the office.

# Restic

At first my solution was to use [Duplicati](https://www.duplicati.com/).  It offered a GUI plus configurable backups that were incremental and on a scheduled basis.  But I had so many issues with it where my backup database would get corrupted and I'd have to wipe everything and restart.  Or the backups would fail silently and I'd get no warning about it.  There's some ways to work around it but overall it's not a tool I would recommend.

For a while I switched to  doing `rsync` backups of my data to various places but there were numerous issues with this strategy.  If my data got encrypted then it would just get copied over to the backup and overwrite the "good" data.  I had no version control.  And it was horribly inefficient.  I tried to solve some of the issues by making tarballs of my data but then I ran into storage issues because there was no deduplication of the data so I was exponentially increasing the amount of space required to backup my data as I went.  Eventually I stumbled onto [Restic](https://restic.readthedocs.io/en/stable/) and it basically solved all my issues.  There's a few other options in this space, [BorgBackup](https://www.borgbackup.org/) and [Kopia](https://kopia.io/) as other popular solutions.

What I like about Restic is that it supports a wide variety of backup methods, such as local disks, SFTP, and S3 Object Storage.  It also encrypts all your backups and supports incremental backups, though it does not support compression (yet, maybe someday).  You can set up retention policies so you can manage how long your data is backed up, and importantly forget and prune unneeded data.  During a forget/prune, Restic will go through your data and repack it so that it only keeps the data it needs and forgets the snapshots it no longer needs.  Overall I've been very impressed with the performance.  I have about 500GB of data backed up via Restic (to both the Synology and B2) and prunes take at most a half hour on my largest datasets.  Most of the time it's minutes.

## Autorestic

This next part is entirely optional, but I think it makes the Restic usage experience much simpler.  [Autorestic](https://autorestic.vercel.app/) is a wrapper for Restic that makes the configuration and basic commands very easy to execute.  There's TONS of options out there for Restic wrappers, such as [Crestic](https://github.com/nils-werner/crestic) and [restique](https://github.com/maxkueng/restique).  Pick one that works for you and has the features you want.  But the rest of this guide is for using Autorestic.

Follow the installation guide for Autorestic [here](https://autorestic.vercel.app/installation).  Then you'll need to create a configuration guide.  The documentation is pretty good here, and feel free to poke around my Github Infra repo and take a look at my autorestic config files, like [this one](https://github.com/FuzzyMistborn/infra/blob/ad580ebef65fcf7ebdb6b40faf33028ed0062c2f/group_vars/adonalsium.yml#L298-L429).  The basic idea is there's a `backend` (S3, local, SFTP etc) and a `location` which is the location of the data you're backing up to a backend.  You can have multiple backends and backup a location to multiple backends (though you can only have a single file location/path per location).  You set the backup password and that's pretty much it.  You can further configure to run some hook scripts (such as calling Healthchecks.io), setting up a retention policy, and excluding files/directories

As I mentioned above, I backup my data to my Synology (using Minio) and Backblaze's B2 service.  I found these options easier to configure than either setting up a storage mount (which would make it easier for ransomware to encrypt) to use local storage or even SFTP which required sharing SSH keys which can be a PITA.

# Minio

[Minio](https://min.io/) is an S3 compatible object storage app that can be run in Docker, and thus on the Synology NAS.  This is now much easier on DSM7, the latest version of the DSM software as it ships with a fairly recent version of Docker.  I would highly encourage you to install `docker-compose` on the Synology [see the docs here](https://docs.docker.com/compose/install/) as Synology's Docker GUI is....well...bad.  It's functional but to change things (like the `command` variable needed for Minio) you have to delete and recreate the container from the GUI.  Docker-Compose just makes it all simpler and easier.  Here's my docker-compose for Minio:

```
version: "2"
services:
  minio:
    image: minio/minio
    container_name: minio
    volumes:
      - /volume1/Minio:/data
    ports:
      - 9000:9000
      - 9001:9001
    environment:
      - MINIO_ROOT_USER=YOUR_USER
      - MINIO_ROOT_PASSWORD=YOUR_PASSWORD
    command:
      ['server', '/data', '--address', '0.0.0.0:9000', '--console-address', '0.0.0.0:9001']
    restart: unless-stopped
```

Once you set up Minio, you can access it at `YOUR_SYNOLOGY_IP:9000` in your web browser.  Login with your root user/password (this is what you use for your AWS_ACCESS_KEY_ID and SECRET_ACCESS_KEY for [Autorestic](https://autorestic.vercel.app/backend/available#s3--minio)).  Alternatively, Alex/IronicBadger has a post [here](https://blog.ktz.me/access-a-synology-nas-with-traefik-on-dsm7/) for setting up a reverse proxy (using Traefik) to access Minio.  I prefer the IP address but to each their own.

And that's it!  You now have an S3 compatible object storage location on your Synology NAS.  Makes backup pretty easy if you ask me!

# Conclusion

I've been running this setup for about 4 months and so far it's been rock solid.  I've had to restore data a few times and the data has been there just as I needed it.  And because the backups are incremental my B2 storage bill is around $2/month for about 500gb of storage.  $2 well spent for some peace of mind over ransomware.
