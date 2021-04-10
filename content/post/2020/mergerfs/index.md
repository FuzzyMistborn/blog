---
title: "MergerFS + SnapRAID - Perfection?"
author: "FuzzyMistborn"
date: 2020-06-02T01:09:20Z
image: "header.jpg"
slug: mergerfs
categories:
  - "Linux"
tags:
  - Mergerfs
  - Snapraid
  - Storage
  - NAS
draft: false
---

Recently I've begun listening to the [Self-Hosted podcast](https://selfhosted.show/).  One of the hosts, Alex, is a huge fan of [MergerFS](https://github.com/trapexit/mergerfs).  He's written about it a few times as the "Perfect Media Server" solution.  You can here him talk about it [here](https://selfhosted.show/5) or read one of his write ups [here](https://blog.linuxserver.io/2016/02/02/the-perfect-media-server-2016/)  [here](https://blog.linuxserver.io/2017/06/24/the-perfect-media-server-2017/) and [here](https://blog.linuxserver.io/2019/07/16/perfect-media-server-2019/).  For the record he does also really like ZFS, but his write up of MergerFS and SnapRAID intrigued me for 2 reasons:

1) The ability to increase the size of the data array easily after you've already created it.

2) The ability to use drives of different sizes.

### ZFS/MergerFS

Originally I was using ZFS and it was....fine.  I created my drive pool using Raid-Z (3 drives, 1 parity disk) and mounted it and....never really gave it a second thought.  I know I wasn't using a lot of the more fun features of ZFS but that really wasn't what I was after, I just wanted the ability to pool drives into an array and have a parity disk for "backup" ([RAID IS NOT BACKUP](https://blog.storagecraft.com/5-reasons-raid-not-backup/) but it's a nice security blanket).

But I slowly was reaching max capacity on my array and realized I was going to have trouble expanding the array.  And by trouble I meant "uhhhh....".  ZFS pool expansion has been on the "coming soon" list [since 2017](https://www.freebsdfoundation.org/blog/openzfs-raid-z-online-expansion-project-announcement/) but I haven't seen any progress.  One solution would be to create a new array and either add it to my server (which I don't have room for) or transfer the data over (requiring another computer).  Honestly neither option was super appealing to have to do on an even infrequent basis.  Also, ZFS is complicated because you need to buy matching drives which adds to the cost/complexity.

So I decided to look into MergerFS and SnapRAID.  The install is really easy (and well laid out in the above linked-to posts).  Essentially, it's 1) install MergerFS, 2) figure out the drive serial IDs, 3) create directories for the mount points (including one for the "usable" mount point, 4) edit fstab to mount the drives, and 5) run `mount -a`.  That's it.  You can add and remove drives from the mount fairly easily as well so it's really very flexible.  Which is great for a media server because I can slowly add HDDs in or replace dead ones instead of being constrained by the limitations of ZFS.

### SnapRAID

For parity, [SnapRAID](https://www.snapraid.it/) is pretty cool too.  It's not instantaneous parity like ZFS so technically if you have data loss between backups intervals you're screwed.  But here's actually where another advantage of MergerFS comes into play.  All the data for a file is stored on a single disk.  So if your HomeMovies.mkv file is on Disk 1 and Disks 2, 3 and 4 fail....no worries, your home movies are fine.  Unlike with something like ZFS where if you exceed the fault tolerance of the array (_i.e._ you're running RAID-Z/RAID5 and lose 1 disk, or RAID-Z2 and lose 2 disks, etc) you lose ALL the data of the array.  Pretty sweet.

Setting up SnapRAID was a bit more complicated than MergerFS because I had some issues initially with [SnapRunner](https://github.com/Chronial/snapraid-runner) but those issues worked themselves out over time and now it's all fine and dandy.  Again, I used Alex's guide to build SnapRAID and run SnapRunner so I would point you there for a how to.

### Data Transfer

This is more of a "lulz" bit but because I was out of space in my server (no more SATA/power connectors) I needed a way to transfer data over.  Recently I'd upgraded my desktop motherboard/CPU and I had it lying around still.  So I did the drive swap and set up the spare "computer" and transferred the data over.  Took a day or two to transfer the few TBs of data and then I retired the setup, but overall it went well and now I have all my data on the new array of disks and can expand it as needed without having to do this again, which is a relief.

{{< figure src="frankenserver.png" caption="Frankenserver" >}}

So that's now how I'm doing my storage in my server.  MergerFS+SnapRAID ftw.  I would highly recommend it over ZFS for most people building a home server array.
