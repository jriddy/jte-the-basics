# jte-the-basics
Pipeline libraries for JTE
# Jenky benk

## What I did to get this working

- Make a file that subs `sudo podman` for `docker` invocations.
- Let Jenkins have access to run sudo podman with
- Modify containers.conf to enable cgroups
- Run the image with something like

```sh
podman run --privileged --user root --device /dev/fuse -d --name fpj-root --rm  -p 8080:8080 -p 50000:50000 fedora-podman-jenkins init
```

I don't think `--device /dev/fuse` is necessary.  Also could be nice to mount volumes for e.g. `/var/lib/containers`

I tried to do rootless-in-rootless but kept hitting uidmap-related issues.  I'll need to get my head around that stuff more if I want to push on that route.  Seems to possibly be related to systemd, since we're running systemd in a container here (because Jenkins wants to be able to restart).  We could play around with another init system like [s6-overlay](https://github.com/just-containers/s6-overlay) as well but I didn't have time to dive into that too deep.

## Debugging/going through

- Install git lol
