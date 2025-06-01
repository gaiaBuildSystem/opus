"""security tasks."""
import src.i_custom as i_custom
from src.task_stubs import TaskChroot
from torizon_templates_utils.errors import Error_Out, Error
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))

source @(__script_path)/task_chroot.xsh

class TaskSecurity():
    """Tasks for managing security tasks."""

    def __init__(self, security: i_custom.SecurityConfig, task_chroot: TaskChroot):
        self._security = security
        self._skip = (security is None)
        self._chroot = task_chroot


    def hardened(self):
        """Apply security hardening measures."""
        if self._skip:
            print("No security hardening to apply.")
            return


        raise NotImplementedError(
            "Security hardening is not implemented yet."
        )
