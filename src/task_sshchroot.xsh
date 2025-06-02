"""Task for run commands in chroot."""
import shlex
import src.i_custom as i_custom
from torizon_templates_utils.errors import Error_Out, Error
from torizon_templates_utils.colors import print, Color, BgColor

class TaskSshChroot():
    """
    Tasks for the chroot properties.
    ⚠️ This only works with the insecure dev mode images ⚠️
    """


    def __init__(self, device: i_custom.DebugDevice, image: i_custom.ImageConfig):
        self._device = device

        # check the match machine
        _remote_machine = $(
            ssh -p @(f"{self._device.port}") \
                -o UserKnownHostsFile=/dev/null \
                -o StrictHostKeyChecking=no \
                -o LogLevel=ERROR \
                @(f"root@{self._device.ip}") "echo $MARS_OSTREE_REPO_BRANCH"
        )

        if _remote_machine != image.machine:
            raise Exception(
                f"Remote machine '{_remote_machine}' does not match the image machine '{image.machine}'."
            )

        # try to connect to the device
        # if this fails we will exit anyway
        ssh \
            -p \
            @(f"{self._device.port}") \
            -o UserKnownHostsFile=/dev/null \
            -o StrictHostKeyChecking=no \
            -o LogLevel=ERROR \
            @(f"root@{self._device.ip}") "echo connected"

        # set the mars to enable debug mode
        ssh \
            -p \
            @(f"{self._device.port}") \
            -o UserKnownHostsFile=/dev/null \
            -o StrictHostKeyChecking=no \
            -o LogLevel=ERROR \
            @(f"root@{self._device.ip}") "mars dev"

        # check the status
        ssh \
            -p \
            @(f"{self._device.port}") \
            -o UserKnownHostsFile=/dev/null \
            -o StrictHostKeyChecking=no \
            -o LogLevel=ERROR \
            @(f"root@{self._device.ip}") "ostree admin status"


    def reconfigure(self):
        """Reconfigure the chroot config mess."""
        print("🔍  Reconfiguring debug...", color=Color.BLACK, bg_color=BgColor.BLUE)


    def run(self, cmd: str) -> int:
        """Run a command in chroot."""
        print(f"run command: {cmd}")

        # run the command in chroot
        _escaped_cmd = shlex.quote(cmd)
        _cmd = f"/bin/bash -c {_escaped_cmd}"
        print(_cmd)

        # run the command
        ssh \
            -p \
            @(f"{self._device.port}") \
            -o UserKnownHostsFile=/dev/null \
            -o StrictHostKeyChecking=no \
            -o LogLevel=ERROR \
            @(f"root@{self._device.ip}") \
            @(_cmd)

        # not sure yet if the ssh return and error code
        # the xonsh will raise an exception too, so, let's return here
        return __xonsh__.last.returncode
