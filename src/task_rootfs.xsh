"""rootfs configurations."""
import src.i_custom as i_custom
from src.task_stubs import TaskChroot
from torizon_templates_utils.errors import Error_Out, Error
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))

source @(__script_path)/task_chroot.xsh

class TaskRootfs():
    """Tasks for the rootfs properties."""

    def __init__(self, rootfs: i_custom.RootfsConfig, task_chroot: TaskChroot):
        self._rootfs = rootfs
        self._skip = (rootfs is None)
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
                print(f"Path {_path} does not exist under the image rootfs. Skipping.", color=Color.YELLOW)
                continue

            print(f"Removing path {_path} from the image rootfs.")
            # rm the path from the rootfs
            rm -rf @(f"{self._rootfs}{_path}")


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
                -a @(f"{_path}/") \
                @(f"{self._chroot._root_dir}{_rootfs_path}")


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
                sudo mkdir -p @(_parent_dir)

            # Copy the file or directory
            if os.path.isdir(_source):
                # For directories, use rsync to handle recursive copying
                sudo rsync -a @(f"{_source}/") @(f"{_full_dest}/")
            else:
                # For files, use cp
                sudo cp @(_source) @(_full_dest)
