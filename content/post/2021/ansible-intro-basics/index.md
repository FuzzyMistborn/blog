---
title: "Ansible - Swiss Army Knife of the Homelab"
author: "FuzzyMistborn"
date: 2021-11-09T10:13:58Z
slug: ansible-intro-basics
image: "header.png"
categories:
  - "Infrastructure"
tags:
  - Ansible
  - Python
  - Infrastructure
  - Infrastructure as Code
  - Oops
draft: false
---

For the past 6 months or so I have slowly fallen in love with a tool called [Ansible](https://www.ansible.com/).  In fact, pretty much every computer in my possession is controlled and managed by Ansible.  I wanted to do a writeup on my usecases/setup for Ansible, which also will lead to another post shortly on using something called Renovate-Bot to help upkeep some of my code.  Together my setup has pretty much become self-maintaining.  Though admittedly that hasn't stopped me from continuing to make improvement/tweaks.

# Introduction
What is Ansible?  SImply put, Ansible is a tool that allows you configure and manage practically any computer device that you can SSH into.  It's [very well documented](https://docs.ansible.com/ansible/latest/index.html) and has an extensive community supporting it.  Best of all, it doesn't require installing any special software on the target machine other than Python.  It may require you to install certain modules on the target machine to run certain modules but that's all documented.  I use Ansible for two related reasons.  First, I use it as a combination of personal wiki/knowledgebase.  It's nice not to have to remember "how the heck did I set up Wireguard again" or "what's that application I used to do X?".  Second, I use it as a form of backup.  It's not really itself a backup but I have the vast majority of my setup in Ansible, meaning should I need to rebuild a server I can do it quickly with pretty much two commands.

Ansible is kind of like a Swiss Army knife.  It can be used to do pretty much anything you can think of.  Maybe [some of them aren't the greatest ideas](https://www.youtube.com/watch?v=TVq88JeJbw4) but the point is it's incredibly flexible.  As you can see from my [Infrastructure GitHub repo](https://www.github.com/FuzzyMistborn/infra), I have a number of roles that are dedicated to individual server setups (like copying over specific bash scripts or installing needed packages).  I also have a number of roles that can automatically install and configure applications, like Restic/Autorestic or Syncthing just the way I need.

In addition to roles you create yourself, as I said above the Ansible community is fairly awesome.  Chances are someone has already written a role to do many of the things you're trying to accomplish.  You can find may of them on [Ansible Galaxy](https://galaxy.ansible.com/) or just be searching Google/DuckDuckGo and finding some GitHub repos.  There's also others who have their entire infrastructure code available on GitHub like mine that you can poke through to see what's possible/people are doing.

# Setting up Ansible
I don't want to go into a ton of detail on the actual setup of Ansible.  There's tons of good guides out there, like this one by [Jeff Geerling](https://www.youtube.com/watch?v=goclfp6a2IQ&list=PL2_OBreMn7FqZkvMYt6ATmgC0KAGGJNAN) and this one that I used on [LearnLinuxTv](https://www.learnlinux.tv/getting-started-with-ansible/).  Honestly, a guide on Ansible would be....much longer than I'm prepared to write.  There's a lot to learn, and I'm by no means an expert, but once you get the basic idea it's pretty easy to go from there.

There are a number of ways to [install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).  It's available in most package repositories and also as a Python package on PyPi.  Depending on your distribution I'd suggest installing via `pip` because there's a fair number of releases a year and the packages can be woefully behind (looking at you Ubuntu/Debian).  Again, the main requirement here is Python.

Beyond that, I would suggest you start by reading/watching a few guides to understand the basics of how Ansible operates.  The basic gist of it is that you create various `Playbooks` which can run a number of `tasks` or `roles`.  Tasks are the basiic building blocks of Ansible.  You use individual modules like`copy` or `template`to accomplish your goals.  A role is basically a set of pre-packaged tasks; you can use it as a shorthand to call a series of tasks you want to use in a variety of places.

Probably the most important part of Ansible to learn is [variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html).  Variables allow you to reuse text over and over again easily and also to be able to use a role on multiple devices and override the variable as necessary.  For example, let's say in general I want to create a user named `fuzzy` so I set a `{{main_username}}` variable as `fuzzy`.  But on one machine I want the user created to be named `elmo`.  All I'd need to do is set the default on that one machine to `elmo` and I'm all set.  Figuring out and setting variables and your defaults is probably the biggest thing to focus on in my opinion.

# Infrastructure As Code
Once you get your Ansible playbooks the way you like, if you're feeling brave open source your code to give back to the community.  I'm a fan of the [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code) movement.  As I mentioned above, I have my entire Ansible setup available on a public GitHub repo.  I love the Ansible community and love how open it is and how much people are willing to help and provide examples.  Having my repo available is my way of giving back/saying thank you.  But wait you might say.  Fuzzy, what about your SSH keys!  Your usernames and passwords! Surely you don't have those publicly available.

Why yes, yes I do.  Welllll.....sorta.  If you feel like to crack Ansible's AES256 bit encryption, have at it.  [It might take you a while](https://www.atpinc.com/blog/what-is-aes-256-encryption).  To do this, you'll need to set up [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html).  Here's a [well-written guide](https://blog.ktz.me/secret-management-with-docker-compose-and-ansible/) I followed to set up my vault.

Now, not going to hide the fact that I've been burned before.  One night, I was up late.  I had made a ton of changes and wanted to commit the changes to GitHub before going to bed.  I ran the commit and started to head up to bed.  As I'm walking upstairs I get a ping from GitHub.  "Oh hey, we just noticed your SSH keys to connect to GitHub were published on GitHub."  Then another one from Cloudflare stating they'd come across an API key.  Crappppppppp.  I'd forgotten to encrypt my Ansible vault prior to committing it to the repo.  And being GitHub there's really no good way to delete a commit absent nuking the entire repo.  So at 1am that's what I had to do.  And since I couldn't exactly leave my setup running with the literal keys to the kingdom (SSH keys, passwords, etc) having been exposed, I spent the next 2 and a half hours changing every password/SSH key that had leaked.  It was NOT an experience that I care to repeat.

As a result I took two main actions.  First, I triple checked my [pre-commit Git script ](https://github.com/FuzzyMistborn/infra/blob/main/git-vault-check.sh)to make sure it worked by checking if my Ansible vault is encrypted before I can actually commit to GitHub.  Second, I make a point of only decrypting my vault when I need to make changes.  Admittedly when the oops happened I was making a lot more changes than I am now that required me being in the vault, but now my default is to encrypt the vault whenver I'm done for the evening.  Don't be me, learn from my mistake.

# Conclusion
Apologies if this post is a little all over the place, but I really just wanted to write up on Ansible and just how much I enjoy using it.  It's really change my life when it comes to my home lab and combined with Proxmox I'm really happy with the state of things.  It's not a tool for everyone but I encourage everyone to at least check it out.