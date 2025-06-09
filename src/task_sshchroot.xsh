"""Task for run commands in chroot."""
import shlex
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print, Color, BgColor

# pylint: disable=import-error
import src.i_custom as i_custom


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

        # pylint: disable=undefined-variable
        if _remote_machine != image.machine:
            # pylint: disable=broad-exception-raised
            raise Exception(
                # pylint: disable=line-too-long
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


    def copy(self, path: str):
        """Copy a file to the remote chroot."""
        print(f"Copying the file [{path}] to the remote chroot...")

        # this copy to the /root user dir
        scp \
            -P \
            @(f"{self._device.port}") \
            -o UserKnownHostsFile=/dev/null \
            -o StrictHostKeyChecking=no \
            -o LogLevel=ERROR \
            @(f"{path}") \
            @(f"root@{self._device.ip}:/root")


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
        # pylint: disable=undefined-variable
        return __xonsh__.last.returncode
