"""Task for image classification using a custom model."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order
# pylint: disable=line-too-long

import os
import re
import subprocess
import src.i_custom as i_custom
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
        self._version_path = self.config.version.replace(".", "-")


    def _extract(self):
        """Extract the image."""
        print("📦  Extracting image...", color=Color.BLACK, bg_color=BgColor.BLUE)

        # pylint: disable=line-too-long
        _archive_file = f"./.{self.config.machine}/{self.config.machine}-ota-{self._version_path}.img.tar.xz"
        _target_dir = f"./.{self.config.machine}"
        _target_img = f"./.{self.config.machine}/{self.config.machine}-ota-{self._version_path}.img"

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
        """Download the image."""
        print("☁️  Downloading image...", color=Color.BLACK, bg_color=BgColor.BLUE)
        _url = f"{self._base_url}{self.config.machine}-ota-{self._version_path}.img.tar.xz"
        print(f"Image URL: {_url}")

        # only if the file does not exist
        if not os.path.exists(
            f"./.{self.config.machine}/{self.config.machine}-ota-{self._version_path}.img.tar.xz"
        ):
            print("Downloading image...")
            wget @(_url)
        else:
            print(
                "Image already downloaded. Use --no-cache to force download.",
                color=Color.BLACK,
                bg_color=BgColor.YELLOW
            )

        self._extract()


    def _expand(self):
        """Expand the image. OSTree needs 3% of the image size to be free."""
        # calc % of the image size
        _pctg_str = self.config.increase

        # check if the image is already expanded
        if os.path.exists(f"./.{self.config.machine}/.image.lock"):
            with open(f"./.{self.config.machine}/.image.lock", "r", encoding="utf-8") as f:
                _pctg_str_stored = f.read()
                if _pctg_str_stored == _pctg_str:
                    print(
                        f"Image already expanded to {_pctg_str_stored}. No need to expand.",
                        color=Color.BLACK,
                        bg_color=BgColor.YELLOW
                    )
                    return

        if _pctg_str is not None:
            print(f"📏  Expanding image in {_pctg_str}...", color=Color.BLACK, bg_color=BgColor.BLUE)

            # get the str% as int
            _pctg_regex = re.search(r'\d+', str(_pctg_str))
            _pctg = 0
            if _pctg_regex:
                _pctg = int(_pctg_regex.group(0))

            # get the size of the image
            if _pctg > 0:
                _image_size = os.path.getsize(
                    f"./.{self.config.machine}/{self.config.machine}-ota-{self._version_path}.img"
                )
                _expand_size = int(_image_size * (_pctg / 100))
                print(f"Image size: {_image_size} bytes")
                print(f"Expand size: {_expand_size} bytes")

                # expand the image
                qemu-img \
                    resize \
                    -f raw \
                    @(f"./.{self.config.machine}/{self.config.machine}-ota-{self._version_path}.img") \
                    +@(_expand_size)B

                # update the partition table
                sudo parted \
                    -s \
                    @(f"./.{self.config.machine}/{self.config.machine}-ota-{self._version_path}.img") \
                    resizepart 2 100%

                # add a lock so the system knows that the image was already expanded
                with open(f"./.{self.config.machine}/.image.lock", "w", encoding="utf-8") as f:
                    f.write(f"{_pctg_str}")
            else:
                print("Image increase size is 0%. No need to expand.", color=Color.BLACK, bg_color=BgColor.YELLOW)


    def mount(self):
        """Mount the image."""
        print("📁  Mounting image...", color=Color.BLACK, bg_color=BgColor.BLUE)
        self._image_file = f"./.{self.config.machine}/{self.config.machine}-ota-{self._version_path}.img"
        _mnt_dir = f"./.{self.config.machine}/mnt/"
        self._boot_dir = f"./.{self.config.machine}/mnt/boot/"
        self._root_dir = f"./.{self.config.machine}/mnt/rootfs/"

        mkdir -p \
            @(_mnt_dir)
        mkdir -p \
            @(self._boot_dir)
        mkdir -p \
            @(self._root_dir)

        # before to bind the partitions, we need to expand the image
        self._expand()

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
