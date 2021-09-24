---
title: "SSH Security - Limited Commands"
author: "FuzzyMistborn"
date: 2020-05-02T17:38:18Z
image: "header.jpg"
slug: ssh-security
categories:
  - "Linux"
tags:
  - Security
  - SSH
draft: false
---

SSH (Secure Shell) is pretty much a necessity in any kind of smart home set up, particularly if you're running Linux.  It's the main way that you connect to your computer (presuming its not your main desktop but some kind of server/Raspberry Pi/NUC/other computer).  Because SSH is so crucial, it's also a potential vector for hackers to gain access to your system so you really need to make sure it's protected.

I don't really want to spend a lot of time on the standard practices to secure SSH.  There are plenty of articles out there that cover this.  My personal favorite is from [How-to Geek here](https://www.howtogeek.com/443156/the-best-ways-to-secure-your-ssh-server/).  At a minimum, you need to disable root ssh login, turn off password authentication and only use SSH keys.  Presuming you've done that, let's take it a step further and let's restrict what terminal commands an SSH key can perform.

You may ask why you'd want to do this.  An easy example is the one I alluded to in my [post about CATT](/homeassistant-and-catt-cast-all-the-things/).  I run HomeAssistant in a Docker container and CATT runs on my server outside of a container.  To run the CATT commands I therefore needed to SSH from the Docker container to the server.  That obviously presents a security risk because one of the main benefits of Docker is that it sandboxes things a bit to limit security issues.  So if there's a vulnerability in one of your containers your entire server isn't necessarily compromised (though it still could be, always keep your services up to date!).  So I needed the ability to SSH to my server but I didn't want HASS to have unrestricted access should the SSH key HASS uses somehow get compromised.

Turns out it's fairly easy to limit what commands an SSH key can run.  All you need to do is add the following bit of code to your `authorized_keys` file (in your `.ssh` folder) at the very begining of the line that contains the SSH key you're trying to restrict.

```
command="ping 192.168.1.1" ssh-rsa AAB34...
```
Everything beyond ssh-rsa is purely an example. Keep whatever values are there.

Now, that key can only run `ping 192.168.1.1` command when you try to use it.  So for example if you're logging into a Raspberry Pi via ssh and try `ssh pi@192.168.1.2 ls` instead of getting a list of files it will start pinging 192.168.1.1.  Here's the catch though.  You can only list one command.  So if you want the SSH key to be able to run multiple commands you need to do a bit more work.

The way around the single command limitation is to create a bash script that you put in the `authorized_keys` file.  Here's how to do it.  Open up your text editor of choice (I like nano personally so I would do `nano ~/.ssh/auth_commands.sh`) and create a file in your `.ssh` directory like this:

```bash
#!/bin/sh
#
# You can have only one forced command in ~/.ssh/authorized_keys. Use this
# wrapper to allow several commands.

case "$SSH_ORIGINAL_COMMAND" in
    "ping 192.168.1.1")
        ping 192.168.1.1
        ;;
    "ping 192.168.1.3")
        ping 192.168.1.3
        ;;
    "ls /home/pi/docker")
        ls /home/pi/docker
        ;;
    *)
        echo "Access denied"
        exit 1
        ;;
esac
```

Obviously you'll want to customize to whatever commands you want.  Depending on the command you may need to specify the full path to the command (run `which command_name` to get the path to the command). Next you need to make the file executable, so `chmod +x ~/.ssh/auth_commands.sh`.  Then you'll need to modify your authorized_keys files to point to the `auth_commands.sh` file (ie `command="~./ssh/auth_commands.sh"`).

Now when you run `ssh pi@192.168.1.2 ls /home/pi/docker` you'll get the results of the command.  But if you try `ssh pi@192.168.1.2 ls /home/pi/homeassistant` instead you'll get "Access denied" in response.

Obviously most of the time when you create SSH keys you're going to want to allow full access to the computer.  But if you want to limit access for some reason, I've found the above to be the simpliest and easiest way to accomplish that goal.


