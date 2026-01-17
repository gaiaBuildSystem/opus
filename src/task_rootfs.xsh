"""rootfs configurations."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order
# pylint: disable=broad-exception-caught
# pylint: disable=protected-access

import os
import sys
from pathlib import Path
# we are redefining the print to have colors
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))

import src.i_custom as i_custom
from src.task_stubs import TaskChroot

source @(__script_path)/task_chroot.xsh

class TaskRootfs():
    """Tasks for the rootfs properties."""

    def __init__(self, rootfs: i_custom.RootfsConfig, task_chroot: TaskChroot):
        self._rootfs = rootfs
        self._skip = rootfs is None
        self._chroot = task_chroot


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
            # check if the path exists
            if not os.path.exists(f"{self._rootfs}{_path}"):
                print(
                    f"Path {_path} does not exist under the image rootfs. Skipping.",
                    color=Color.YELLOW
                )
                continue

            print(f"Removing path {_path} from the image rootfs.")
            # rm the path from the rootfs
            rm -rf @(f"{self._rootfs}{_path}")


    def mkdir(self):
        """Create the path."""
        if self._skip:
            print("No rootfs configurations to create directories.")
            return

        print("📂  Creating directories in rootfs...", color=Color.BLACK, bg_color=BgColor.BLUE)
        _to_mkdir = getattr(self._rootfs, "mkdir", []) or []

        if len(_to_mkdir) == 0:
            print("No rootfs configurations to create directories.")
            return

        for _dir in _to_mkdir:
            _full_dir = f"{self._chroot._root_dir}{_dir}"
            sudo mkdir -p @(f"{_full_dir}")


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
            # sync the path to the rootfs
            # WARNING: this / on the fstring is for the rsync sinc instead of
            # copy the folder inside the folder
            sudo rsync \
                -a --mkpath @(f"{_path}/") \
                @(f"{self._chroot._root_dir}{_rootfs_path}")


    def chroot_debug(self):
        """Run debug commands under the rootfs."""
        if self._skip:
            print("No rootfs configurations to run debug commands.")
            return

        if self._rootfs.chroot_debug is not None and len(self._rootfs.chroot_debug) > 0:
            print("⚠️  Debug chroot scripts does not run under production task, skipping ...")
        else:
            print("No rootfs configurations to run debug commands.")


    def chroot(self):
        """Run script under the rootfs."""
        if self._skip:
            print("No rootfs configurations to chroot.")
            return

        print("🔒  Chrooting into the rootfs...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _to_chroot = getattr(self._rootfs, "chroot", []) or []
        if len(_to_chroot) == 0:
            print("No rootfs configurations to chroot.")
            return

        raise NotImplementedError(
            "Chrooting into the rootfs is not implemented yet. Please check the code."
        )


    def copy(self):
        """Copy a file or folder from source to the rootfs."""
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
            _full_dest = f"{self._chroot._root_dir}{_dest}"

            print(f"Copying {_source} to {_dest} in the image rootfs.")

            # Create parent directory if it doesn't exist
            _parent_dir = os.path.dirname(_full_dest)
            if not os.path.exists(_parent_dir):
                print(f"Creating parent directory {_parent_dir} in the image rootfs.")
                sudo mkdir -p @(_parent_dir)

            # Copy the file or directory
            if os.path.isdir(_source):
                print("rsync for directories to handle recursive copying ...")
                # For directories, use rsync to handle recursive copying
                sudo rsync -a @(f"{_source}/") @(f"{_full_dest}/")
            else:
                print("cp for files ...")
                # For files, use cp
                sudo cp @(_source) @(_full_dest)
