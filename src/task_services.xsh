"""systemd services tasks."""
import src.i_custom as i_custom
from src.task_stubs import TaskChroot
from torizon_templates_utils.errors import Error_Out, Error
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))

source @(__script_path)/task_chroot.xsh

class TaskServices():
    """Tasks for managing systemd services."""

    def __init__(self, services: i_custom.ServicesConfig, task_chroot: TaskChroot):
        self._services = services
        self._skip = (services is None)
        self._chroot = task_chroot


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
