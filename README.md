[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

- https://wiki.voidlinux.org/Manual_install_with_ZFS_root
- https://github.com/nightah/void-install

```
podman run --rm -it voidlinux/voidlinux /bin/sh
podman run --rm -it voidlinux/voidlinux-musl /bin/sh
```

- [x] virt-install scripts
- [x] git pre-commit hooks shellcheck
- [ ] install scripts
  - [x] zfs parts
  - [x] system install
  - [ ] network, dns
  - [ ] bootloader
- [ ] port arch-config playbook + git hook ansible-playbook --syntax-check
- [ ] zectl with syslinux: https://github.com/johnramsden/zectl/issues/35
- [ ] travis on playbook run
