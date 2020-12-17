[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

- https://docs.voidlinux.org/installation/guides/chroot.html
- https://wiki.voidlinux.org/Manual_install_with_ZFS_root
- https://github.com/nightah/void-install
- neffi@freenode#voidlinux zfsbootmenu config: http://ix.io/2I4m

```
podman run --rm -it voidlinux/voidlinux /bin/sh
podman run --rm -it voidlinux/voidlinux-musl /bin/sh
```

- [x] virt-install scripts
- [x] git pre-commit hooks shellcheck
- [x] install scripts
  - [x] zfs parts
  - [x] system install
  - [x] refind and zfsbootmenu
  - [x] network, dns
  - [x] ntp with chrony
  - [x] crond with cronie
  - [ ] periodic zfs scrub
- [x] port arch-config playbook
  - [x] git hook ansible-playbook --syntax-check
  - [ ] README init install git + ansible
  - [ ] create package requests for missings
  - [ ] create issue wrong missing package reported by xbps module: https://github.com/ansible-collections/community.general/issues
  - [ ] move xbps tasks from loop to name: list
- [ ] travis/github actions on playbook run

issues:
- https://sourceforge.net/p/refind/discussion/general/thread/4dfcdfdd16/

TODO:
- borgmatic config

PACKAGES:
- [ ] x2goclient: https://github.com/void-linux/void-packages/issues/27223
- [ ] tiny-irc-client: https://github.com/void-linux/void-packages/issues/27180
- [ ] swaylock-fancy: https://github.com/void-linux/void-packages/issues/27224
- [ ] python3-pre-commit: https://github.com/void-linux/void-packages/issues/27225
- [ ] ovmf: https://github.com/void-linux/void-packages/issues/27229
