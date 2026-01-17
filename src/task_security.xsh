"""security tasks."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order
# pylint: disable=broad-exception-caught
# pylint: disable=protected-access

import sys
import secrets
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

        # 1. disable root login via SSH
        self._chroot.run(
            "sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config"
        )
        self._chroot.run(
            "sed -i 's/^PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config"
        )

        # 2. disable root password login
        self._chroot.run(
            "passwd -l root"
        )

        # 3. disable phobos login without password
        self._chroot.run(
            "passwd -l phobos"
        )

        # 4. disable sudo without password
        self._chroot.run(
            # pylint: disable=line-too-long
            "sed -i 's/^\\%sudo\\s\\+ALL=(ALL:ALL) NOPASSWD: ALL/\\%sudo ALL=(ALL:ALL) ALL/' /etc/sudoers"
        )

        # 5. create a secure password for the phobos user
        _new_secure_password = secrets.token_urlsafe(32)
        self._chroot.run(
            f"echo -e '{_new_secure_password}\n{_new_secure_password}' | passwd phobos"
        )

        print(
            "🔒 The phobos user password has been set to a secure value",
            color=Color.YELLOW, bg_color=BgColor.BLACK
        )
        print(
            # pylint: disable=line-too-long
            "THIS PASSWORD WILL BE SHOWN ONLY ONCE, MAKE SURE TO SAVE IT!",
            color=Color.YELLOW, bg_color=BgColor.BLACK
        )
        print(f"Phobos user password: {_new_secure_password}")

        # 4. update motd to say that the device is secure
        self._chroot.run(
            "echo '🔒 This device was hardened by opus.' > /etc/motd"
        )
