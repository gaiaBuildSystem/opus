"""Task for run commands in chroot."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order

import os
import shlex
# we are redefining the print to have colors
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print, Color, BgColor


class TaskChroot():
    """Tasks for the chroot properties."""


    def __init__(self, root_dir: str, machine: str = ""):
        self._machine = machine
        self._root_dir = root_dir
        self._var_dir = os.path.realpath(f"{root_dir}../../var")
        self._rootdirs = os.path.join(self._var_dir, "rootdirs")
        # The rootfs (sysroot) sits 5 levels above the deploy dir:
        # {rootfs}/ostree/deploy/{osname}/deploy/{hash}.0/
        self._sysroot_dir = os.path.realpath(f"{root_dir}../../../../../")

        print("Fixups for chroot ...")

        # disable the chattr
        sudo chattr -i @(self._root_dir)

        # Replicate what ostree-prepare-root does at runtime: bind-mount the
        # rootfs as /sysroot so the deploy's root-level symlinks (home, var,
        # media, etc.) which use "sysroot/ostree/deploy/phobos/var/rootdirs/..."
        # resolve correctly inside the chroot without modifying them.
        sudo mount --bind @(self._sysroot_dir) @(f"{self._root_dir}sysroot")

        self.run("chmod 1777 /tmp")
        self.run("rm -rf /etc/resolv.conf")
        self.run('echo "nameserver 8.8.8.8" > /etc/resolv.conf')

        print("Fixups for chroot, ok")


    def reconfigure(self):
        """Reconfigure the chroot config mess."""
        print("🔍  Reconfiguring deploy...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # Merge live /etc into /usr/etc so the new commit carries the correct
        # configuration template; ostree admin deploy recreates /etc via 3-way merge.
        self.run("rsync -a --delete /etc/ /usr/etc/")
        self.run("rm -rf /etc")

        # Unmount the sysroot bind-mount used for the chroot session.
        # All root-level symlinks (home, var, media, ...) are left untouched
        # so they are committed with their original "sysroot/..." targets.
        # umount_virtualfs() handles /var cleanup (unmount + rmdir + symlink restore).
        sudo umount @(f"{self._root_dir}sysroot")


    def rollback_etc(self):
        """This is used if something was failed during the deploy."""

        self.run("mkdir -p /etc")
        self.run("rsync -a /usr/etc/ /etc/")


    def run_ret(self, cmd: str)-> str:
        """Run a command in chroot and return the output."""
        print(f"run command: {cmd}")

        # run the command in chroot
        _escaped_cmd = shlex.quote(cmd)
        _cmd = f"chroot {self._root_dir} /bin/bash -c {_escaped_cmd}"
        print(_cmd)

        _cmd_args = shlex.split(_cmd)

        # run the command and return the output
        _ret = ""
        _ret = $(sudo @(_cmd_args))

        return _ret


    def copy(self, path: str):
        """Copy a file or folder from source to the rootfs."""
        print(f"Copying the file [{path}] to the rootfs...")

        # this copy to the /root user dir
        sudo cp -r @(f"{path}") @(f"{self._rootdirs}/root/")


    def run(self, cmd: str)-> int:
        """Run a command in chroot."""
        print(f"run command: {cmd}")

        # run the command in chroot
        _escaped_cmd = shlex.quote(cmd)
        _cmd = f"MACHINE={self._machine} chroot {self._root_dir} /bin/bash -c {_escaped_cmd}"
        print(_cmd)

        _cmd_args = shlex.split(_cmd)

        # run the command
        sudo @(_cmd_args)

        # this will always return 0, as we are running it locally
        # if we have some error we will raise an exception
        return 0
