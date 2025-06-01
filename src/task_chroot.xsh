"""Task for run commands in chroot."""
import shlex
import src.i_custom as i_custom
from torizon_templates_utils.errors import Error_Out, Error
from torizon_templates_utils.colors import print, Color, BgColor

class TaskChroot():
    """Tasks for the chroot properties."""


    def __init__(self, root_dir: str):
        self._root_dir = root_dir

        print(f"Fixups for chroot ...")

        self.run("rm -rf /var")
        self.run("mkdir -p /var/log/apt")
        self.run("chmod 1777 /tmp")
        self.run("rm -rf /etc/resolv.conf")
        self.run('echo "nameserver 8.8.8.8" > /etc/resolv.conf')

        print(f"Fixups for chroot, ok")


    def reconfigure(self):
        """Reconfigure the chroot config mess."""
        print("🔍  Reconfiguring deploy...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # the /var was messed up, so we need to fix it
        self.run("rm -rf /var")
        self.run("ln -sf sysroot/ostree/deploy/phobos/var/rootdirs/var /var")

        # the /etc need to be merged to the /usr/etc
        self.run("rsync -a --delete /etc/ /usr/etc/")
        self.run("rm -rf /etc")


    def run(self, cmd: str)-> int:
        """Run a command in chroot."""
        print(f"run command: {cmd}")

        # run the command in chroot
        _escaped_cmd = shlex.quote(cmd)
        _cmd = f"chroot {self._root_dir} /bin/bash -c {_escaped_cmd}"
        print(_cmd)

        _cmd_args = shlex.split(_cmd)

        # run the command
        sudo @(_cmd_args)

        # this will always return 0, as we are running it locally
        # if we have some error we will raise an exception
        return 0
