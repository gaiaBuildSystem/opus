"""Task for ostree commands."""
import src.i_custom as i_custom
from torizon_templates_utils.errors import Error_Out, Error
from torizon_templates_utils.colors import print, Color, BgColor

class TaskOstree():
    """Tasks for the ostree properties."""


    def __init__(self, boot_dir: str, root_dir: str, machine: str):
        self._boot_dir = boot_dir
        self._root_dir = root_dir
        self._machine = machine
        self._ostree_repo = f"{self._root_dir}ostree/repo"
        self._deploy_commit_hash = ""
        self._ostree_deploy = ""
        self._mounted = False


    def mount_virtualfs(self):
        """mount the virtual fs"""

        if not self._ostree_deploy:
            Error_Out(
                "No ostree deploy found. Please run get_deployed_commit() first.",
                Error.EINVAL
            )

        if not self._mounted:
            sudo mount -o bind /dev @(self._ostree_deploy)/dev
            sudo mount -o bind /dev/pts @(self._ostree_deploy)/dev/pts
            sudo mount -t proc none @(self._ostree_deploy)/proc
            sudo mount -t sysfs none @(self._ostree_deploy)/sys
            self._mounted = True


    def umount_virtualfs(self):
        """unmount the virtual fs"""

        try:
            if self._mounted:
                sudo umount @(self._ostree_deploy)/dev/pts
                sudo umount @(self._ostree_deploy)/dev
                sudo umount @(self._ostree_deploy)/proc
                sudo umount @(self._ostree_deploy)/sys
                self._mounted = False
        except Exception as e:
            print(f"Error unmounting virtual fs: {e}", color=Color.YELLOW)


    def get_deployed_commit(self) -> str:
        """Get the deployed commit."""
        print("🔍  Getting deployed commit...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _commit = $(ostree rev-parse --repo=@(self._ostree_repo) @(self._machine))

        if not _commit:
            Error_Out(
                "No commit found. Please check the ostree repo.",
                Error.EINVAL
            )

        # FIXME: hard coded the index .0 here, woulb nice to get this from the ostree
        self._ostree_deploy = f"{self._root_dir}ostree/deploy/phobos/deploy/{_commit}.0/"
        print(f"📦  Deployed commit: {_commit}", color=Color.BLACK, bg_color=BgColor.GREEN)
        print(f"{self._ostree_deploy}")

        return _commit


    def commit(self):
        """Commit the ostree repo."""
        print("📦  Committing changes to ostree repo...", color=Color.BLACK, bg_color=BgColor.BLUE)
        print("please wait...")

        sudo ostree \
            --repo=@(self._ostree_repo) \
            commit \
            --branch @(self._machine) \
            --tree=dir=@(self._ostree_deploy) \
            --add-metadata-string="version=0.0.0" \
            --add-metadata-string="phobos.custom=0.0.0"

        print("📦  Committed changes to ostree repo", color=Color.BLACK, bg_color=BgColor.GREEN)


    def deploy(self):
        """Deploy the ostree repo."""
        print("📦  Deploying ostree repo...", color=Color.BLACK, bg_color=BgColor.BLUE)
        print("please wait...")

        # the _ostree_deploy path has the hash tainted in it
        # we need to get the father
        # _deploy_path = f"{self._root_dir}ostree/deploy/phobos/deploy"
        _deploy_path = f"{self._root_dir}"

        sudo ostree \
            --sysroot=@(_deploy_path) \
            admin deploy \
            --os=phobos \
            --no-merge \
            @(self._machine)

        sudo ostree \
            --repo=@(self._ostree_repo) \
            summary \
            -u

        print("📦  Deployed ostree repo", color=Color.BLACK, bg_color=BgColor.GREEN)
