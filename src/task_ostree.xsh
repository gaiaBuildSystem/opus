"""Task for ostree commands."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order
# pylint: disable=broad-exception-caught

import os
import json
from torizon_templates_utils.errors import Error_Out, Error
# we are redefining the print to have colors
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print, Color, BgColor


class TaskOstree():
    """Tasks for the ostree properties."""


    def __init__(self, boot_dir: str, root_dir: str, machine: str, version: str = "0.0.0"):
        self._boot_dir = boot_dir
        self._root_dir = root_dir
        self._machine = machine
        self._version = version
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

        _commit = None
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


    def push_to_torizon(self):
        """Push the ostree repo to Torizon."""
        print("📦  Pushing ostree repo to Torizon...", color=Color.BLACK, bg_color=BgColor.BLUE)

        _ostree_repo_z2 = f"./.{self._machine}/ostree/repo.z2"
        _cred_path = "./credentials.zip"
        _tuf_path = f".{self._machine}"
        _package_name = f"{self._machine}-opus"

        # check if the credentials file exists
        if not os.path.exists(_cred_path):
            print(
                "⚠️ Credentials file not found, skipping push to torizon.io",
                color=Color.BLACK,
                bg_color=BgColor.YELLOW
            )
            return

        # check if the repo z2 exists
        if not os.path.exists(_ostree_repo_z2):
            # ceate it then
            print("Creating the OSTree z2 folder ...")
            sudo mkdir -p @(f"./.{self._machine}/ostree/repo.z2")
            print("Initializing the OSTree z2 repository ...")
            sudo ostree init --repo=@(f"{_ostree_repo_z2}") --mode=archive-z2

        # sync repo
        sudo ostree -v \
            --repo=@(_ostree_repo_z2) \
            pull-local \
            @(f"{self._ostree_repo}") \
            @(f"{self._machine}")

        # get the commit
        _commit = self.get_deployed_commit()

        # push to torizon
        print("Pushing OTA to Torizon Cloud:")
        print(f"Module: {self._machine}")
        print(f"Commit: {_commit}")

        sudo garage-push \
            --credentials @(f"{_cred_path}") \
            --repo @(f"{_ostree_repo_z2}") \
            --ref @(f"{_commit}")

        # sign
        print("prepare metadata ...")
        _meta = {
            "commitBody": "",
            "commitSubject": f"{self._machine}-{_commit}-opus-custom",
            "ostreeMetadata": {
                "gaia.arch": "unknown",
                "gaia.distro": "phobos",
                "gaia.distro-codename": "lion-killer",
                "gaia.image": "phobos-ota-opus",
                "gaia.machine": self._machine,
                "gaia.build-purpose": "development",
                "gaia.debian-major": "12",
                "ostree.ref.binding": [
                    f"{self._machine}"
                ],
                "version": f"{self._version}-opus"
            }
        }
        _meta_json = json.dumps(_meta)

        print("initializing metadata ...")
        sudo uptane-sign \
            init \
            --credentials @(_cred_path) \
            --repo @(_tuf_path) \
            --verbose

        print("Pulling targets ...")
        sudo uptane-sign \
            targets \
            pull \
            --repo @(_tuf_path) \
            --verbose

        print("Adding targets ...")
        sudo uptane-sign \
            targets \
            add \
            --repo @(_tuf_path) \
            --name @(_package_name) \
            --format OSTREE \
            --version @(self._version) \
            --length 0 \
            --sha256 @(_commit) \
            --hardwareids @(self._machine) \
            --customMeta @(_meta_json) \
            --verbose

        print("Signing targets ...")
        sudo uptane-sign \
            targets \
            sign \
            --repo @(_tuf_path) \
            --key-name targets \
            --verbose

        print("Pushing targets ...")
        sudo uptane-sign \
            targets \
            push \
            --repo @(_tuf_path) \
            --verbose

        print("📦  Pushed ostree repo to Torizon", color=Color.BLACK, bg_color=BgColor.GREEN)
