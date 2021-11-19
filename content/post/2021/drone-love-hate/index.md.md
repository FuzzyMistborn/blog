---
title: "My Love/Hate Relationship with Drone.io and CI"
author: "FuzzyMistborn"
date: 2021-11-18T08:38:00Z
slug: drone-love-hate
image: "header.png"
categories:
  - "Infrastructure"
tags:
  - Drone.io
  - Woodpecker
  - Docker
  - "Continuous Integration"
  - Automation
draft: false
---

# Introduction

Let's talk about Drone.  No, not this kind of drone

![[drone.jpg]]
[This kind of Drone](https://www.drone.io/)!  The [Continuous Integration](https://en.wikipedia.org/wiki/Continuous_integration) kind.  The one that helps you with automatically doing all kinds of fun coding things.  Basically, Drone is a self-hosted alternative to something like [GitHub Actions](https://github.com/features/actions) or [Jenkins](https://jenkins.io/) or [Travis CI](https://travis-ci.com/).  Basically, if there's something with your code that you want to run automatically after some action is taken, then CI is for you.

I've been playing around with Drone for about a week now, and while ultimately I'm pretty happy with it, I'm also incredibly frustrated by it.  My initial foray into continuous integration projects started a few months ago with GitHub Actions so I'm entirely willing to admit that it may be user/beginner error.  However, there are seemingly basic things that should *just work* but don't.  Other things that should be easily to set up but aren't.  The number of times I wanted to pull hair out over something not working is beyond count.

## Deploying
Setting up Drone is really very easy.  There are two basic parts: a [server](https://docs.drone.io/server/overview/) and a runner.  There are a number of [different runners available](https://docs.drone.io/runner/overview/) but I prefer Docker.  It's possible to run the Drone server on a different machine from the Drone runner.  For instance, I run the server on my VPS, but the runner is on an machine at my house.  Obviously my hardware at home has beefier specs that the VPS so builds go much faster.  I'm not entirely sure *how* the runner and server communicate but it did not require me creating any firewall rules on the server or at home.  And any kind of lag/delaying in triggering builds is hardly noticeable.

I think the [documentation](docs.drone.io/) here is actually pretty well done and there is'nt much that needs explaining.  Just follow the instructions and you should be up in no time.  The main limitation I ran into is that you can only tie the Drone server to one of the source control platforms (GitHub, Gitea, Gogs, etc.).  So if you have multiple places you use, you'll need multiple instances of Drone.  Given Drone's resource usage is basically non-existent, that shouldn't be an issue.

As an FYI, to get your account token which you'll need for the API, just navigate to `https://YOUR_DRONE_SERVER/account`.

## Examples

Things I'm doing with Drone:

1) Running a `yamlllint` and where appropriate `ansiblelint` on every commit;
2) Building various docker containers and pushing to Docker Hub and GHCR;
3) Running a config check on my HomeAssistant configuration files on every major HomeAssistant release (including the beta releases) so I can know ahead of time if my configuration needs fixing before I deploy the update;
4) Building and deploying this blog, along with a staging site I can use for testing/debugging purposes.

In reality, the sky's the limit with automating like this.  One of the more difficult setups I achieved was automatically building a modified  [Docker container of Nextcloud](https://github.com/FuzzyMistborn/nextcloud-docker) that includes Samba and imagick.  I prefer the official Nextcloud image but it doesn't ship with those packages installed so I needed to create it myself.  I didn't want to have to manually trigger the build every time, so now, Drone runs a check script every 6 hours and using one of my new favorite tools, [skopeo](https://github.com/containers/skopeo), checks to see if there's an updated Docker image and if there is, update the Dockerfile with an updated tag and tag a new release on GitHub.  That then triggers a new build of the docker image, which is pushed to DockerHub and GHCR.io, and then the images are deleted.  Again, that's just one example (and I'd even say a fairly basic one) of what Drone can do.

# Likes/Dislikes
## Likes
Let's start off with the good, as there's a lot of good things with Drone that I liked.  As you'll notice though, some things that I liked I also ran into aspects that I disliked.

### Use Any Docker Image
Probably the handiest feature is you can literally use *any* available Docker image/container to complete your task.  Drone has a [number of plugins](plugins.drone.io/) available (frustratingly the page doesn't support HTTPS for some reason....) but I found that in the end it was often easier to just build/do it all myself.  Sometimes that meant a lot of trial and error, and teaching myself more bash scripting like nested if/else statements.  But regardless of how you do it, the point is you probably can do it with Drone given the flexibility what container you use.

### More Flexibility
Drone lets you use bash to your hearts content.  So you can use the [`commands` portion](https://docs.drone.io/pipeline/docker/syntax/steps/#commands) of your pipeline to run basically any command you want.  Including referencing bash scripts you may have in your git repo.  Note however that if you cannot use the `commands` option with a Drone plugin.  As soon as you execute a `command` the plugin basically becomes a normal Docker container with no other special instructions.

### Triggering Builds via API
As discussed below, I ran into some limitations when it came to triggering or limiting my builds.  Using the API (and of course, using HomeAssistant to set off the trigger, thus automating my automations) was very handy.  Triggering a build is pretty easy:

```bash
curl \
-i "https://drone.example.com/api/repos/USER/REPO/builds" \
-H "Authorization: Bearer YOUR_TOKEN"
```

To add variable, add a `?YOUR_VAR=test` after `/builds` like this:

```bash
curl \
-i "https://drone.example.com/api/repos/USER/REPO/builds?VAR=test" \
-H "Authorization: Bearer YOUR_TOKEN"
```


## Dislikes
That's not to say that Drone is perfect.  I really struggled with some things that in my opinion should be really straightforward (or better documented).  

### Cron

Let's start with an easy one.  Drone includes the ability to trigger builds based on a [cron schedule](https://docs.drone.io/pipeline/docker/syntax/trigger/#by-cron) from the GUI.  

![[drone-cron.png]]

Notice, however, that there's no way to create a custom schedule beyond the defaults.  Also, you can't set the time the cron triggers.  By default it's midnight UTC.  Oh, and you can't set the timezone from the GUI either...I had to mount `/etc/localtime` as a volume for it to set it to my local timezone.

You *can* create a custom schedule, however it *must* be done via the [API](https://docs.drone.io/api/cron/cron_create/).  Which isn't hard, but it's an annoying limitation that just shouldn't exist.  Here's an example call you can use:

```bash
curl -X POST https://drone.example.com/api/repos/USER/REPO/cron \
-H "Authorization: Bearer YOUR_DRONE_TOKEN" \
-H "Content-Type: application/json" \
--data '{"name": "EXAMPLE", "expr": "* 0 */6 * * *", "branch": "main" }'
```

Note the cron scheduling includes seconds as an option so it's 6 asterisks instead of the usual 5.  So seconds, minutes, hours, day of month, month, and day of week.  Once it's created, you can see the schedule along with when the next execution will be.

![[drone-cron2.png]]

### Triggering Builds

Something that I ran into was some limitations when it came to both [conditions](https://docs.drone.io/pipeline/docker/syntax/conditions/) and [triggers](https://docs.drone.io/pipeline/docker/syntax/trigger/).  The most frustrating limitation is that while you can have multiple conditions, ALL conditions must be true in order for the step to be performed.  If you want to evaluate conditions separately, you'll probably need to create extra pipelines.  Which then introduces a problem of how do you limit the triggering of the various pipelines?  I found this a hard problem to solve, though it was something that could be worked around.

Something to keep in mind/that bit me for a while if you're adding [multiple pipelines](https://docs.drone.io/pipeline/configuration/#multiple-pipelines): the `---` between your pipelines is 100% necessary.

```yaml
kind: pipeline
type: docker
name: backend

steps:
- name: build
  image: golang
  commands:
  - go build
  - go test

--- <-----YOU NEED THIS
kind: pipeline
type: docker
name: frontend

steps:
- name: build
  image: node
  commands:
  - npm install
  - npm test
```

Another slightly annoying limitation with triggers is while it support triggers based on [tags](https://docs.drone.io/pipeline/docker/syntax/trigger/#by-event), there's no support for releases.

### Environmental Variables
Drone has a lot of different ways to handle/import variables.  There are several ways to import/use [secrets](https://docs.drone.io/secret/), including into plugin settings or as [environmental](https://docs.drone.io/pipeline/docker/syntax/steps/#environment) variables.  Another trick is that you can add variables as you would normally in bash with something like `var=Test` and calling `$var` in your commands.

The frustration is that it's not possible to share variables across pipelines (so you have to import it every time).  What I ended up doing a number of times is piping the variable to an `.env` file and then sourcing it every stage as needed.  Again, there's a solution here, it just isn't always obvious or easy to get to (and sometimes feels like a kludge).

### Git Pushes
Oh. My. God.  This was probably the most frustrating thing I dealt with when setting up Drone.  There's an official [Git Push](http://plugins.drone.io/appleboy/drone-git-push/) plugin available but with a combination of some long standing issues like [this one](https://github.com/appleboy/drone-git-push/issues/40) and [this one](https://github.com/appleboy/drone-git-push/issues/44) I just could not get the plugin to work nicely with committing back to GitHub with SSH.  I even tried something like [this](https://discourse.drone.io/t/how-can-i-set-host-ssh-key/4636) where I would add the SSH key as an environmental variable but I kept hitting `fatal: could not read Username for 'https://github.com': terminal prompts disabled`.  Also, I could not figure out how to push git `tags` with the official plugin which is something I needed.

The solution ended up being surprisingly simple.  So simple I'm shocked that it's not included in the documentation anywhere.  Since Drone uses HTTPS to clone the GitHub repo, the easiest way to do a commit back is over HTTPS as well.  All you need is to generate a [Personal Access Token](https://github.com/settings/tokens/new) for GitHub (I have not tested/tried this with Gitea or the other options so YMMV) with the `public_repo` scope.  Add the token as a secret in Drone, and then do something like this:

```yaml
  - name: generate tag
    image: alpine/git
    environment:
      GH_API_KEY:
        from_secret: push_api_key
    commands:
      - git remote add github https://YOUR_USERNAME:$GH_API_KEY@github.com/USER/REPO.git
      - git tag -a 0.0.1 -m "Release v. 0.0.1"
      - git push -u github main 0.0.1
```

You can modify the above to also push git commits or really any other `git` based action.  Again, I don't understand why this isn't documented given how common a problem pushing with SSH is.
# Conclusion
In the end, I think a large part of the problem is that the documentation could be clarified.  For example, [here](https://docs.drone.io/pipeline/docker/syntax/trigger/#by-action) it says "Action support varies by event and SCM provider" but fails to explain where I might find out more about what the SCM providers might support.  Another recent issue that I noticed is that Harness moved the GitHub repo for Drone to their own.  I'm not sure if they also closed down the Issues section or if that was done before, but now a bunch of links on the Drone forum to various issues just 404.  Kinda sucks losing that.

There also are some who have issues with the licensing of Drone.  The Drone Server is open sourced under an [Apache2 license](https://github.com/harness/drone/blob/master/LICENSE) while the Runners appear to be [propriety/not open source](https://github.com/drone-runners/drone-runner-docker/blob/master/LICENSE.md).  Personally, I don't mind this part as much as it's still self-hostable and free though I do understand the concerns.  If you only want to use open source software, there's an [alternative](woodpecker-ci.org/) that forked Drone and appears to be under active development.  Can't say I'm a fan of the name (Woodpecker? really?).

This turned out to be way longer than intended, and it may seem like I really don't like Drone.  In fact, I both love and hate Drone.  The flexibility it offers is awesome, it has a simple and clean UI that's relatively easy to navigate, and I personally am a fan of YAML.  There's just a couple of pain points that honestly just...shouldn't be pain points.  They seem so simple to fix.  And I wish I could program in GO but I cannot help.