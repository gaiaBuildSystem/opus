"""Task for image classification using a custom model."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order
# pylint: disable=line-too-long

import os
import re
import subprocess
# Even thouhg the pylint complains about the src. it need to be this way
# becuase we are sourcing this file in the main.xsh
import src.i_custom as i_custom # pylint: disable=no-name-in-module
from torizon_templates_utils.errors import Error_Out, Error
# we are redefining the print to have colors
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print, Color, BgColor


class TaskImage():
    """Tasks for the image properties."""
    config: i_custom.ImageConfig
    _base_url: str = "https://br-se1.magaluobjects.com/gaia-imgs/"
    _version_path = ""
    _loopdev = ""
    _image_file = ""
    _boot_dir = ""
    _root_dir = ""


    def __init__(self, config: i_custom.ImageConfig):
        self.config = config
        # TODO: I'm adding this hard coded for now
        # self._version_path = self.config.version.replace(".", "-")
        self._version_path = "0-0-0"
        self._image_file_raw = f"{self.config.name}-{self.config.machine}-ota-{self._version_path}.img"
        self._image_file = f"./.{self.config.machine}/{self._image_file_raw}"


    def _extract(self):
        """Extract the image."""
        print("📦  Extracting image...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # pylint: disable=line-too-long
        _archive_file = f"{self._image_file}.tar.xz"
        _target_dir = f"./.{self.config.machine}"
        _target_img = f"{self._image_file}"

        if os.path.exists(_target_img):
            print(f"Image {_target_img} already exists. Use --no-cache to force a fresh download/extract.", color=Color.BLACK, bg_color=BgColor.YELLOW)
            return

        mkdir -p \
            @(_target_dir)

        tar -xvJf @(_archive_file) \
            --checkpoint=1000 \
            --checkpoint-action=echo="Extracted %u records" \
            -C @(_target_dir)


    def download(self):
        """Download the image or use local image if image_path is provided."""
        # Check if image_path is provided
        if self.config.image_path:
            print("📂  Using local image...", color=Color.BLACK, bg_color=BgColor.BLUE)

            # Ensure the path is relative to workspace (for container compatibility)
            _source_path = os.path.abspath(self.config.image_path)
            print(f"Image path: {_source_path}")

            # Validate that the image filename matches the machine name
            _actual_filename = os.path.basename(_source_path)
            if _actual_filename.find(self.config.machine) == -1:
                Error_Out(
                    f"Image filename {_actual_filename} does not contain the machine name '{self.config.machine}'. Have you sure you provided the correct image_path?",
                    Error.EINVAL
                )

            _target_dir = f"./.{self.config.machine}"
            _target_img = f"{self._image_file}"

            # Ensure the target directory exists
            if not os.path.exists(_target_dir):
                os.makedirs(_target_dir)

            # Check if source image exists
            if not os.path.exists(_source_path):
                Error_Out(
                    f"Image file not found: {_source_path}",
                    Error.ENOFOUND
                )

            # If target doesn't exist, copy the image
            if not os.path.exists(_target_img):
                print(f"Copying image from {self.config.image_path} to {_target_img}...")
                cp @(self.config.image_path) @(_target_img)

                print("Image copied successfully!", color=Color.BLACK, bg_color=BgColor.GREEN)
            else:
                print(
                    f"Image {_target_img} already exists. Use --no-cache to force copy.",
                    color=Color.BLACK,
                    bg_color=BgColor.YELLOW
                )

            return

        # Original download logic
        print("☁️  Downloading image...", color=Color.BLACK, bg_color=BgColor.BLUE)
        _url = f"{self._base_url}{self._image_file_raw}.tar.xz"
        print(f"Image URL: {_url}")

        # only if the file does not exist
        if not os.path.exists(
            f"{self._image_file}.tar.xz"
        ):
            print("Downloading image...")

            # Ensure the target directory exists
            _target_dir = f"./.{self.config.machine}"
            if not os.path.exists(_target_dir):
                os.makedirs(_target_dir)

            # Download the file to the correct directory
            wget -P @(_target_dir) @(_url)
        else:
            print(
                "Image already downloaded. Use --no-cache to force download.",
                color=Color.BLACK,
                bg_color=BgColor.YELLOW
            )

        self._extract()


    def mount(self):
        """Mount the image."""
        print("📁  Mounting image...", color=Color.BLACK, bg_color=BgColor.BLUE)
        _mnt_dir = f"./.{self.config.machine}/mnt/"
        self._boot_dir = f"./.{self.config.machine}/mnt/boot/"
        self._root_dir = f"./.{self.config.machine}/mnt/rootfs/"

        mkdir -p \
            @(_mnt_dir)
        mkdir -p \
            @(self._boot_dir)
        mkdir -p \
            @(self._root_dir)

        _kpartxret = ""
        _kpartxret=$(sudo kpartx -av @(self._image_file))
        _match_parts = re.search(r'loop.', _kpartxret)
        if _match_parts:
            self._loopdev = _match_parts.group(0)
            print(f"Loop device: {self._loopdev}", color=Color.BLACK, bg_color=BgColor.BLUE)

            # fill the rootfs
            try:
                print("Filling rootfs from loop device partitions...")
                sudo e2fsck -fy /dev/mapper/@(self._loopdev)p2
            except subprocess.CalledProcessError as e:
                # get the ret code
                print(f"e2fsc returned: {e.returncode}", color=Color.YELLOW)
            sudo resize2fs -f /dev/mapper/@(self._loopdev)p2

            # mount the image
            sudo mount /dev/mapper/@(self._loopdev)p1 @(self._boot_dir)
            sudo mount /dev/mapper/@(self._loopdev)p2 @(self._root_dir)
        else:
            Error_Out(
                f"Error mounting image: {self._image_file}",
                Error.ENOFOUND
            )


    def unmount(self):
        """Unmount the image."""
        print("📂  Unmounting image...", color=Color.BLACK, bg_color=BgColor.BLUE)

        if not self._loopdev:
            print(
                "No loop device found. Nothing to unmount.",
                color=Color.BLACK,
                bg_color=BgColor.YELLOW
            )
            return

        # sync data to disk
        sync

        # unmount the image, these are ok to fail
        try:
            print("Unmounting boot and rootfs partitions...")
            sudo umount @(self._boot_dir)
            sudo umount @(self._root_dir)
            sleep 1
        # pylint: disable=broad-exception-caught
        except Exception as e:
            print(f"Error unmounting image: {e}", color=Color.YELLOW)

        sudo kpartx -dv @(self._image_file)
        sleep 1

        # detach from the loop device
        sudo losetup -d /dev/@(self._loopdev)
        sleep 1
        sudo dmsetup remove /dev/mapper/@(self._loopdev)p1
        sudo dmsetup remove /dev/mapper/@(self._loopdev)p2
