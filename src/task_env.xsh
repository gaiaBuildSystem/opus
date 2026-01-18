"""Environment variables tasks."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order

import sys
import src.utils as utils
from pathlib import Path
from src.task_stubs import TaskChroot
# we are redefining the print to have colors
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
__script_path = Path(__file__).resolve().parent
sys.path.append(str(__script_path))


source @(__script_path)/task_chroot.xsh


class TaskEnv():
    """Tasks for the environment variables properties."""

    def __init__(
        self,
        env: list,
        task_chroot: TaskChroot,
        debug: bool = False
    ):
        self._env = env
        self._skip = env is None
        self._chroot = task_chroot
        self._debug = debug

        utils.create_cache("env")


    def inject(self) -> bool:
        """Set environment variables in /etc/environment."""
        if self._skip:
            print("No environment variables to set.")
            return False

        print("🔧  Setting environment variables...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # cache
        if utils.cached_f("env", "set", "./custom.yaml"):
            print("Using cache for environment variables set.")
            return False

        _env_list = self._env or []

        if len(_env_list) == 0:
            print("No environment variables to set.")
            return False

        # Add each environment variable only if it doesn't already exist
        for _env_dict in _env_list:
            for _key, _value in _env_dict.items():
                print(f"Setting {_key}={_value}")
                # One-liner: only add if env var doesn't exist in /etc/environment
                self._chroot.run(
                    # pylint: disable=line-too-long
                    f'grep -q "^{_key}=" /etc/environment || echo "{_key}={_value}" | sudo tee -a /etc/environment > /dev/null'
                )

        utils.write_cache_f("env", "set", "./custom.yaml")

        return True
