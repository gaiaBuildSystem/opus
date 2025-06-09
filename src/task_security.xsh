"""security tasks."""

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
from torizon_templates_utils.colors import print

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))

source @(__script_path)/task_chroot.xsh

class TaskSecurity():
    """Tasks for managing security tasks."""

    def __init__(self, security: i_custom.SecurityConfig, task_chroot: TaskChroot):
        self._security = security
        self._skip = security is None
        self._chroot = task_chroot


    def hardened(self):
        """Apply security hardening measures."""
        if self._skip:
            print("No security hardening to apply.")
            return


        raise NotImplementedError(
            "Security hardening is not implemented yet."
        )
