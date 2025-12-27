---
title: Migrating to PostgreSQL
author: FuzzyMistborn
date: 2025-12-26
slug: postgresql-migration
image:
categories:
  - Infrastructure
tags:
  - Database
  - Mariadb
  - Postgres
  - HomeAssistant
  - Vaultwarden
  - Gitea
  - Nextcloud
draft: false
---
I've been taking some time off work to enjoy the holidays, and decided that now was a good time to take on a few interesting projects I've wanted to do in the good ole homelab before the end of the year.  The main one I accomplished today was migrating from MariaDB to PostgreSQL for the majority of my database backends.

I've long been a user of MariaDB for all my database needs.  It has done the job and upgrades have been relatively straightforward, even between major versions.  And there has been nothing really "wrong" with my setup.  But over the years I've seen a lot more positive opinions express over PostgreSQL and a lot more projects supporting it (sometimes as the only option).  I've run it for those few instances where I've needed it, but I was never a huge fan because to upgrade between major versions (ie going from 14-->15) in Docker required you to basically dump your entire database, create a new container, and restore the backup.  That being said, PostgreSQL supports major versions for a [*long* time](https://www.postgresql.org/support/versioning/), so I never feel compelled to upgrade that often.

What really prompted me to start looking into migrating was the deprecation of the MariaDB backend for Umami, the software I use to track visits to this blog.  As much as I like Umami and the relative simplicity to set it up, I've been bitten twice by bad migrations involving the database, forcing me to start fresh.  Going from MariaDB to PostgreSQL was the second instance.  However, I'm hopeful that this will be the last time as I really don't want to have to deal with it again.  And the developer has indicated that PostgreSQL is easier to support for the software so....fingers crossed.

It just so happened at the time I was doing this conversion (over Thanksgiving when I was visiting family and bored), [TheOrangeOne](https://theorangeone.net/) shared an interesting container that removes the major pain point I've had with PostgreSQL: automatic upgrades.  The container is `pgautoupgrade/pgautoupgrade`, and just like the name implies, it handles the upgrades for you.  Obviously you should still backup before upgrading, but this container allowed me to upgrade my existing PostgreSQL instances without any issues to the latest version.  You can read more about the container [here](https://github.com/pgautoupgrade/docker-pgautoupgrade).

As a result of the Umami database conversion, the only other DB I had left on my VPS is for Gitea, so I figured I would look into migrating my MariaDB backend for Gitea to PostgreSQL.  And oooof, it was not easy.  I played around with various sql dumps, `pgloader`, and everything in between.  After faffing about for several hours, I was ultimately successful in migrating the data over (though don't ask me how now).  Huzah, two fewer instances of MariaDB and only one image/database type on my VPS.

After the pain of the Gitea migration I took a bit of a break.  But I got in a homelabbing mood today setting up Booklore so figured I would take the rest of the migrations I could.  And overall I was successful in migrating the following apps from MariaDB to PostgreSQL.  I've sorted them by ease of migration:

1) **Nextcloud** - *Super* simple.  There's an `occ`-based migration tool, `occ db:convert`.  You can read more about it [here](https://docs.nextcloud.com/server/stable/admin_manual/configuration_database/db_conversion.html).  I spun up a new PostgreSQL container, filled out the command and ran it.  Took about 5 minutes and everything was migrated over.  It even handled updating Nextcloud's `config.php` file.
2) **Vaultwarden** - Relatively simple.  Followed the instructions in the Github [here](https://github.com/dani-garcia/vaultwarden/wiki/Using-the-PostgreSQL-Backend#migrating-from-mysql-to-postgresql).  Basically spun up a new Vaultwarden instance (with the new PostgreSQL database), stopped both the old and new instances, and used `pgloader` to migrate the data.  Only complication for me was that my database was old so it was `bitwarden_rs` and not `vaultwarden` in the load file's `ALTER SCHEMA` line.
3) **HomeAssistant** - On par with the Gitea migration, but for a different reason.  My HA database is quite large, with a few million entries, which is not surprising given how many entities I have.  I therefore worked with my AI buddy Claude to tweak the settings for `pgloader` to ultimately get it to work.  The main struggle was with memory limits in both the databases as well as `pgloader`.  For posterity, this was my `pgloader` `.load` file that ended up working:

```
LOAD DATABASE
  FROM mysql://hass:password@192.168.50.1:3306/homeassistant
  INTO postgresql://homeassistant:password@192.168.50.1:5432/homeassistant

WITH include drop, create tables, create indexes, reset sequences, workers = 2, concurrency = 1

EXCLUDING TABLE NAMES MATCHING 'statistics', 'statistics_short_term'

CAST type datetime to timestamptz drop default drop not null using zero-dates-to-null 

BEFORE LOAD DO
 $$ drop schema if exists homeassistant cascade; $$, 
 $$ create schema homeassistant; $$;
```

4) And a very distant 4th place would be Umami and Gitea tied.  Umami because I was unsuccessful (which I guess maybe should make it 5th), and Gitea just because it took forever.

I fully recognize that database migrations aren't the simplest thing, and the easiest solution would have been to just start fresh, but I really didn't want to lose any data.  Therefore I fought a bit but ultimately seem to have come out (mostly) victorious.  The end result is that I only have 2 databases running MariaDB (Booklore and ROMM), and it's unclear if there will ever be PostgreSQL support for either.  But if there is, I will probably migrate.

Also shout out to [pgloader](https://github.com/dimitri/pgloader) as a useful tool for migrating between instances.

I haven't noticed much performance wise yet (it's only been a few hours), but I did immediately notice that my database LXC dropped about 5% in RAM usage as a result of the switch.  Granted, the LXC only has 3gb of RAM, but still that's a fairly substantial drop!  Will track performance and update this post if I notice anything worth mentioning.

> Update: RAM usage seems to now be 50% lower (from ~40% to under 20% overall utilization).  And at least HomeAssistant feels snappier in the UI.