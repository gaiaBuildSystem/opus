# Opus Command

<p align="center">
    <img
        src="logo.png"
        height="212"
    />
</p>

Opus is the PhobOS customization and development tool. With Opus you can easily set up and manage a base PhobOS image and transform it into your custom OS optimized for your application.

## Customizing PhobOS

PhobOS can be customized through a `custom.yaml` configuration file. Below is a comprehensive guide to all available customization options.

### Configuration Structure

The configuration file has the following top-level structure:

```yaml
image:
  machine: "rpi5b"
  version: "0.0.0"
  # ... additional options
```

### Required Fields

- **machine** (string): The target machine for the image (e.g., 'rpi5b' for Raspberry Pi 5B)
- **version** (string): Version number in semantic format (e.g., '0.0.0')

This will download the corresponding PhobOS base image, from the version set, from the official PhobOS artifacts repository.

### Optional Configuration Sections

#### Image Size

- `increase` (string): Percentage to increase the image size by (e.g., '10%')

#### Debug Mode

Configure debug mode for development on connected devices:

```yaml
debug:
  enable: true
  commit: true
  device:
    ip: "192.168.1.100"
    port: 22
```

- `enable` (boolean): Enable or disable debug mode
- `commit` (boolean): Commit and deploy changes to the connected device
- `device` (required when enabled):
  - `ip` (string): Device IP address
  - `port` (integer): Connection port (1-65535)

When debug mode is enabled the Opus instead of create an output image, it will deploy the changes directly to the connected device via SSH.

If `commit` is set to true, all changes will be committed in a new OSTree commit and deployed to the connected device.

#### Package Management (apt)

Install or remove Debian packages:

```yaml
apt:
  install:
    - package1
    - package2
  install_debug:
    - debug-tool1
    - debug-tool2
  remove:
    - unwanted-package
```

- `install` (array): Packages to install via apt
- `install_debug` (array): Debug-only packages (installed only on connected device)
- `remove` (array): Packages to remove via apt

#### Systemd Services

Enable or disable systemd services:

```yaml
services:
  enable:
    - myservice.service
    - another.service
  disable:
    - unwanted.service
```

- `enable` (array): Services to enable (must match pattern: `*.service`)
- `disable` (array): Services to disable (must match pattern: `*.service`)

When debug mode is enabled, enabled services will also be started on the connected device.

#### Root Filesystem Modifications

Customize the root filesystem:

```yaml
rootfs:
  mkdir:
    - /opt/myapp
    - /var/mydata
  merge:
    - ./rootfs/etc/systemd/system
    - ./rootfs/usr/app
  remove:
    - /unnecessary/directory
  copy:
    - ./local/file.conf:/etc/app/file.conf
    - ./binary:/usr/bin/mybinary
  chroot:
    - ./scripts/setup.sh
  chroot_debug:
    - ./scripts/debug-setup.sh
```

- `mkdir` (array): Create directories in rootfs (absolute paths)
- `merge` (array): Directories from `./rootfs` to merge into the image (cannot merge into `/home`, `/root`, `/var`, or `/opt`)
- `remove` (array): Directories to remove from rootfs (absolute paths)
- `copy` (array): Files to copy using `source:destination` format
- `chroot` (array): Scripts to run inside the chroot environment
- `chroot_debug` (array): Scripts to run inside the SSH chroot environment during debug mode

#### Kernel Configuration

Customize kernel parameters and modules:

```yaml
kernel:
  cmdline:
    - console=ttyS0,115200
    - loglevel=7
  devicetree:
    - ./hardware/custom.dts
  devicetree_overlays:
    - ./hardware/overlay.dtso
  config:
    CONFIG_CUSTOM_OPTION: "y"
    CONFIG_MODULE: "m"
    CONFIG_CUSTOM_VALUE: "value"
  out_of_tree_modules:
    - ./modules/custom-driver
```

- `cmdline` (array): Kernel command line parameters
- `devicetree` (array): Device tree blob files (`.dts` files from local workspace)
- `devicetree_overlays` (array): Device tree overlay files (`.dtso` files from local workspace)
- `config` (object): Kernel configuration options (triggers kernel build from source)
  - Keys must match pattern `CONFIG_*`
  - Values can be "y" (built-in), "m" (module), or custom strings
- `out_of_tree_modules` (array): Kernel modules from `./modules` directory (compiled from source)

#### Environment Variables

Set environment variables in the image:

```yaml
env:
  - MY_VAR: "value1"
  - ANOTHER_VAR: "value2"
```

- `env` (array): List of environment variable objects with string values

#### Security Configuration

Configure security hardening:

```yaml
security:
  hardened: true
```

- `hardened` (boolean): Enable or disable security hardening (required for production images)
