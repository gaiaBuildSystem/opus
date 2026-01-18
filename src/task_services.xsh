"""systemd services tasks."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order
# pylint: disable=broad-exception-caught
# pylint: disable=protected-access

import sys
import src.i_custom as i_custom
from pathlib import Path
from src.task_stubs import TaskChroot
# we are redefining the print to have colors
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))

source @(__script_path)/task_chroot.xsh

class TaskServices():
    """Tasks for managing systemd services."""

    def __init__(
        self, services: i_custom.ServicesConfig, task_chroot: TaskChroot,
        debug: bool = False
    ):
        self._services = services
        self._skip = services is None
        self._chroot = task_chroot
        self._debug = debug


    def enable(self):
        """Enable the systemd services."""
        if self._skip:
            print("No services to enable.")
            return

        print("🚀 Enabling systemd services...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _to_enable = getattr(self._services, "enable", []) or []

        # run the command in chroot
        if len(_to_enable) == 0:
            print("No services to enable.")
            return

        for service in _to_enable:
            print(f"Enabling service: {service}")
            _cmd = f"systemctl enable {service}"
            self._chroot.run(_cmd)

            if self._debug:
                print(f"Starting service: {service}")
                _cmd_start = f"systemctl start {service}"
                self._chroot.run(_cmd_start)


    def disable(self):
        """Disable the systemd services."""
        if self._skip:
            print("No services to disable.")
            return

        print("🛑 Disabling systemd services...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _to_disable = getattr(self._services, "disable", []) or []

        # run the command in chroot
        if len(_to_disable) == 0:
            print("No services to disable.")
            return

        for service in _to_disable:
            print(f"Disabling service: {service}")
            _cmd = f"systemctl disable {service}"
            self._chroot.run(_cmd)
