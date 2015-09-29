You know, there are these cheap ARM netbooks that can run GNU/Linux.
I have one with the WM8505 ... um, SoC?
So here's a repo for putting together other people's hard work into a vaguely bootable set of files, so that you can run Debian testing.
This only works for my exact model of netbook, so I think you'll need some tweaks to make it work.

The idea is that you'd run `make`, and it'll create `boot.zip` and `rootfs.tar.gz`.
You gotta make two partitions on an SD card and extract them and stuff.
TODO: Look up what the partitions ought to be and document them here.
Or maybe write a script that does it.

I build this on Ubuntu trusty, and I have the following packages installed for this:
* bc
* gcc-arm-linux-gnueabi
* u-boot-tools
* debian-archive-keyring
* debootstrap

## Catalog of everything in this repo

The `Makefile` describes the high level steps for doing everything.
And it has the various compilation options for the kernel.
And it has a list of packages to install in the root filesystem.

There's actually a whole 'nother branch, `kernel`, which is a blind rebase of @linux-wmt's kernel onto later mainline kernel releases.
When you run `make`, it'll clone the kernel branch into a subdirectory, so you better not have cloned all branches, because then you'd end up with two copies of the kernel, and that's bad, because it's really big.

Some kernel configuration options are in `seed`, which are mostly taken from @linux-wmt's wiki.
Other options are arbitrary things that I've turned on as I needed, not in any principled way.

The uboot script is in `cmd`, which I've also taken from @linux-wmt's wiki.
Supposedly, the exact black magic incantation needed here differs from model to model, so you might have to tweak this.

It builds the root filesystem with the `buildrootfs` script.

The root filesystem is set up with an init script made from `init.template`.
When you first boot the root filesystem, this script runs the second stage of debootstrap and also sets up a user.

## Uncategorized disclosures

It arranges for the second stage of debootstrap to run with eatmydata.

It up the system so that there's a user with sudo access, and you can't log in as root.

It sets up the root filesystem with some network-related packages.
This includes the non-free `firmware-ralink` package.

It sets the contrast on boot.
Use `/etc/udev/rules.d/99-fb-contrast.rules` to get it the way you like.

It should name the internal USB WiFi adapter wlan0.
This is different from the usual behavior, which names USB-connected links with their physical address.

There are some `/etc/network` scripts that do the GPIO stuff when you use `ifup wlan0` and `ifdown wlan0`.

## Workflow for kernel branch

```
   upstream v1          upstream v2
  /                    /
-o-(mainline changes)-o
  \                    \
   (cherry-pick)        (cherry-pick) <- rebase (private)
    \                    \
-----o--------------------o <- kernel

```
The `kernel` branch is a merge commit whose second parent is the changes rebased on some upstream release, and whose first parent is the previous state of the branch.
That is, the latest rebase is at `kernel^2`, and the previous rebase is at `kernel~^2`, and so on.
At the end of following the first parent, you'll reach @linux-wmt's `testing` branch (although I probably should have kept it consistent).

1. Privately, do `git checkout -b rebase kernel^2`.
2. Fetch an upstream version to rebase onto, e.g., with `git fetch --no-tags upstream v4.2`.
3. Do the rebase, which I guess you would do by `git rebase FETCH_HEAD`.
4. Create a new commit to link the history with `git commit-tree -p refs/heads/kernel -p HEAD -m "rebase v4.2" HEAD^{tree}`.
5. Move the `kernel` branch with `git update-ref refs/heads/kernel (whatever the previous step prints)`.

(It's all weird like that to avoid back-and-forth checkouts.)
