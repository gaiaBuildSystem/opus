"""rootfs configurations."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order
# pylint: disable=broad-exception-caught
# pylint: disable=protected-access
# pylint: disable=line-too-long

import os
import sys
from pathlib import Path
import src.i_custom as i_custom
from src.task_stubs import TaskSshChroot
# we are redefining the print to have colors
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))

# xonsh import
source @(__script_path)/task_sshchroot.xsh


class TaskSshRootfs():
    """Tasks for the debug rootfs properties."""
    _device: i_custom.DebugDevice

    def __init__(self, rootfs: i_custom.RootfsConfig, task_chroot: TaskSshChroot):
        self._rootfs = rootfs
        self._skip = rootfs is None
        self._chroot = task_chroot
        self._device = getattr(self._chroot, "_device", None)

        assert self._device is not None, "TaskSshRootfs requires a TaskChroot with a DebugDevice."


    def remove(self):
        """Remove the rootfs configurations."""
        if self._skip:
            print("No rootfs configurations to remove.")
            return

        print("🗑️  Removing rootfs configurations...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _to_remove = getattr(self._rootfs, "remove", []) or []

        if len(_to_remove) == 0:
            print("No rootfs configurations to remove.")
            return

        for _path in _to_remove:
            print(f"Removing path {_path} from the image rootfs.")
            # the remove here need to be a remote remove
            # remembering that the _chroot here is a TaskSshChroot instance
            self._chroot.run(f"rm -rf {_path}")


    def mkdir(self):
        """Create the path uses mkdir -p"""
        if self._skip:
            print("No rootfs configurations to create directories.")
            return

        print("📂  Creating directories in rootfs...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _to_mkdir = getattr(self._rootfs, "mkdir", []) or []

        if len(_to_mkdir) == 0:
            print("No rootfs configurations to create directories.")
            return

        for _path in _to_mkdir:
            print(f"Creating directory {_path} in the image rootfs.")
            # the mkdir here need to be a remote mkdir
            # remembering that the _chroot here is a TaskSshChroot instance
            self._chroot.run(f"mkdir -p {_path}")


    def merge(self):
        """Merge the rootfs configurations."""
        if self._skip:
            print("No rootfs configurations to merge.")
            return

        print("🔀  Merging rootfs configurations...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _to_merge = getattr(self._rootfs, "merge", []) or []

        if len(_to_merge) == 0:
            print("No rootfs configurations to merge.")
            return

        for _path in _to_merge:
            _rootfs_path = _path.replace("./rootfs", "")

            # check if the path exists
            if not os.path.exists(_path):
                print(f"Path {_path} does not exist. Skipping.", color=Color.YELLOW)
                continue

            print(f"Merging path {_rootfs_path} to the image rootfs.")
            # the rsync here need to be a remote rsync
            sudo rsync \
                -a --mkpath @(f"{_path}/") \
                -e @(f"ssh -p {self._device.port} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR") \
                @(f"root@{self._device.ip}"):@(f"{_rootfs_path}")


    def chroot_debug(self):
        """Run debug commands under the rootfs."""
        if self._skip:
            print("No rootfs configurations to run debug commands.")
            return

        if self._rootfs.chroot_debug is not None and len(self._rootfs.chroot_debug) > 0:
            print("📜🪳  Running chroot_debug scripts ...", color=Color.BLACK, bg_color=BgColor.BLUE)

            for _debug_script in self._rootfs.chroot_debug:
                print(f"Running debug script: {_debug_script}")

                # check if the script exists
                if not os.path.exists(_debug_script):
                    raise FileNotFoundError(
                        f"chroot_debug [{_debug_script}] does not exist. Please check the path."
                    )

                self._chroot.copy(_debug_script)
                self._chroot.run(f"chmod +x /root/{os.path.basename(_debug_script)}")
                self._chroot.run(f"cd /root && ./{os.path.basename(_debug_script)}")
        else:
            print("No rootfs configurations to run debug commands.")


    def chroot(self):
        """Run chroot scripts commands under the rootfs."""
        if self._skip:
            print("No rootfs configurations to run chroot scripts commands.")
            return

        if self._rootfs.chroot_debug is not None and len(self._rootfs.chroot_debug) > 0:
            print("⚠️  chroot scripts does not run under production task, skipping ...")
        else:
            print("No chroot configurations to run scripts commands.")


    def copy(self):
        """Copy files to the rootfs."""
        if self._skip:
            print("No rootfs configurations to copy.")
            return

        print("📁  Copying files to rootfs...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _to_copy = getattr(self._rootfs, "copy", []) or []

        if len(_to_copy) == 0:
            print("No rootfs configurations to copy.")
            return

        for _copy_spec in _to_copy:
            # Parse the copy specification: source:destination
            _source, _dest = _copy_spec.split(":", 1)
            print(f"Copying {_source} to {_dest} in the device rootfs.")

            # check if the source is a dir or file
            if os.path.isdir(_source):
                print("Let's add something here")
                # the rsync here need to be a remote rsync
                sudo rsync \
                    -a @(f"{_source}/") \
                    -e @(f"ssh -p {self._device.port} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR") \
                    @(f"root@{self._device.ip}"):@(f"{_dest}")
            else:
                # create the path on remote anyway
                self._chroot.run(f"mkdir -p {os.path.dirname(_dest)}")

                # the scp here need to be a remote scp
                sudo scp \
                    -P @(self._device.port) \
                    -o UserKnownHostsFile=/dev/null \
                    -o StrictHostKeyChecking=no \
                    -o LogLevel=ERROR \
                    @(f"{_source}") \
                    @(f"root@{self._device.ip}:{_dest}")
