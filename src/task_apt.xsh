"""apt packages tasks."""
import os
import src.i_custom as i_custom
import src.utils as utils
from src.task_stubs import TaskChroot
from torizon_templates_utils.errors import Error_Out, Error
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))

source @(__script_path)/task_chroot.xsh


class TaskApt():
    """Tasks for the apt packages properties."""

    def __init__(
        self,
        apt: i_custom.AptConfig,
        task_chroot: TaskChroot,
        debug: bool = False
    ):
        self._apt = apt
        self._skip = (apt is None)
        self._chroot = task_chroot
        self._debug = debug

        utils.create_cache("apt")

    def update(self) -> bool:
        """Update the apt packages."""
        if self._skip:
            print("No apt packages to update.")
            return False

        print("🆙  Updating apt packages...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # cache
        if utils.cached("apt", "update"):
            print("Using cache for apt packages updated.")
            return False

        # run the command in chroot
        _cmd = "apt-get update"
        print(_cmd)

        self._chroot.run(_cmd)
        utils.write_cache("apt", "update")

        return True


    def install(self) -> bool:
        """Install the apt packages."""
        if self._skip:
            print("No apt packages to update.")
            return False

        print("🆕  Installing apt packages...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # cache
        if utils.cached_f("apt", "install", "./custom.yaml"):
            print("Using cache for apt packages installed.")
            return False

        _to_install = getattr(self._apt, "install", []) or []

        # run the command in chroot
        if len(_to_install) == 0:
            print("No apt packages to install.")
            return False

        _cmd = f"apt-get install -y {' '.join(self._apt.install)}"
        print(_cmd)

        self._chroot.run(_cmd)
        utils.write_cache_f("apt", "install", "./custom.yaml")

        return True


    def install_debug(self) -> bool:
        """Install the apt packages for debug."""
        if self._skip or not self._debug:
            print("No apt packages to update.")
            return False

        print("🆕  Installing apt packages for debug...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # cache
        if utils.cached_f("apt", "install_debug", "./custom.yaml"):
            print("Using cache for apt packages installed.")
            return False

        _to_install = getattr(self._apt, "install_debug", []) or []

        # run the command in chroot
        if len(_to_install) == 0:
            print("No apt packages to install for debug.")
            return False

        _cmd = f"apt-get install -y {' '.join(self._apt.install_debug)}"
        self._chroot.run(_cmd)
        utils.write_cache_f("apt", "install_debug", "./custom.yaml")

        return True


    def remove(self) -> bool:
        """Remove the apt packages."""
        if self._skip:
            print("No apt packages to update.")
            return

        print("✴️  Removing apt packages...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # cache
        if utils.cached_f("apt", "removed", "./custom.yaml"):
            print("Using cache for apt packages installed.")
            return False

        _to_remove = getattr(self._apt, "remove", []) or []

        # run the command in chroot
        if len(_to_remove) == 0:
            print("No apt packages to remove.")
            return False

        _cmd = f"apt-get remove -y {' '.join(self._apt.remove)}"
        self._chroot.run(_cmd)
        utils.write_cache_f("apt", "removed", "./custom.yaml")

        return True
