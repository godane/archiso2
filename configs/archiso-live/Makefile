ver=$(shell date +%Y.%m.%d)

WORKDIR=work

MODULES="base"

ARCH?=$(shell uname -m)

PWD=$(shell pwd)
NETname=$(PWD)/archlinux-$(ver)-netinstall-$(ARCH).iso
COREname=$(PWD)/archlinux-$(ver)-core-$(ARCH).iso

#PACKAGES="$(shell cat ${MODULES}.list)"

kver_FILE=$(WORKDIR)/root-image/etc/mkinitcpio.d/kernel26.kver

all: net-iso core-iso

# Rules for each type of image
core-iso: $(COREname)
net-iso: $(NETname)

$(COREname): core-pkgs base-fs
	mkarchiso iso $(WORKDIR) $@
$(NETname): base-fs
	mkarchiso iso $(WORKDIR) $@

# This is the main rule for make the working filesystem.
base-fs: root-image overlay iso-mounts


# Rules for make the root-image for base filesystem.
root-image: $(WORKDIR)/root-image/.arch-chroot
$(WORKDIR)/root-image/.arch-chroot:
	mkarchiso -M ${MODULES} -v all $(WORKDIR) $@

# overlay filesystem
overlay:
	mkdir -p $(WORKDIR)/modules/overlay/etc/pacman.d
	cp -r overlay $(WORKDIR)/modules/
	wget -O $(WORKDIR)/modules/overlay/etc/pacman.d/mirrorlist http://www.archlinux.org/mirrorlist/$(ARCH)/all/
	sed -i "s/#Server/Server/g" $(WORKDIR)/modules/overlay/etc/pacman.d/mirrorlist


# Rule to process isomounts file.
iso-mounts: $(WORKDIR)/isomounts
$(WORKDIR)/isomounts: isomounts root-image
	sed "s|@ARCH@|$(ARCH)|g" isomounts > $@


# Rule for make the [core] repo packages
core-pkgs:
	./download-repo.sh core $(WORKDIR)/core-pkgs


# Clean-up all work
clean:
	rm -rf $(WORKDIR) $(NETname) $(COREname)


.PHONY: all core-iso net-iso
.PHONY: base-fs
.PHONY: root-image bootfiles initcpio overlay iso-mounts
.PHONY: core-pkgs
.PHONY: clean

