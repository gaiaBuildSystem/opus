#!/usr/bin/env xonsh

# Copyright (c) 2025 Matheus Castello
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$RAISE_SUBPROC_ERROR = True
$XONSH_SHOW_TRACEBACK = True

import os
import sys
from pathlib import Path
from torizon_templates_utils.errors import Error_Out, Error
from torizon_templates_utils.colors import print, Color, BgColor

# to import the local modules
script_path = Path(__file__).resolve().parent
sys.path.append(str(script_path))

from src.task_stubs import (
    TaskImage,
    TaskOstree,
    TaskChroot,
    TaskSshChroot,
    TaskApt,
    TaskRootfs,
    TaskSshRootfs,
    TaskServices,
    TaskKernel,
    TaskSecurity
)
import src.debug as debug
import src.utils as utils
from src.i_custom import CustomSchemaInterface

# xonsh import
source @(script_path)/src/task_image.xsh
source @(script_path)/src/task_ostree.xsh
source @(script_path)/src/task_chroot.xsh
source @(script_path)/src/task_sshchroot.xsh
source @(script_path)/src/task_apt.xsh
source @(script_path)/src/task_rootfs.xsh
source @(script_path)/src/task_sshrootfs.xsh
source @(script_path)/src/task_services.xsh
source @(script_path)/src/task_kernel.xsh
source @(script_path)/src/task_security.xsh

###
# Main expects to read the ./custom.yaml file
# and then generate the custom image
##
def _main():
    """
    Main function to generate the custom image
    """

    # For breakpoint debugging
    # debug.__breakpoint()

    # read the custom.yaml file
    config: CustomSchemaInterface = CustomSchemaInterface.from_yaml()
    config.summary()

    # to check if is all ok
    # sys.exit(0)

    # edge case for debug
    if config.image.debug and config.image.debug.enable == True:
        print("⚠️ Debug mode enabled, skipping image generation.", color=Color.BLACK, bg_color=BgColor.YELLOW)

        # for debug we need dinamically load the sshchroot task
        # source @(script_path)/src/task_sshchroot.xsh
        try:
            _task_ssh = TaskSshChroot(config.image.debug.device, config.image)
            _task_apt = TaskApt(config.image.apt, _task_ssh, config.image.debug)

            _task_apt.remove()
            _task_apt.update()
            _task_apt.install()
            _task_apt.install_debug()

            # rootfs
            _task_rootfs = TaskSshRootfs(config.image.rootfs, _task_ssh)

            _task_rootfs.remove()
            _task_rootfs.merge()
            _task_rootfs.copy()
        except Exception as e:
            Error_Out(
                f"Error: {e}",
                Error.EABORT
            )

        print("🪳 Debug commands ran successfully!", color=Color.BLACK, bg_color=BgColor.GREEN)
        sys.exit(0)
    # edge case for debug


    # tasks
    # image
    _task_image = TaskImage(config.image)
    _task_image.download()

    try:
        _task_image.mount()

        # ostree
        _task_ostree = TaskOstree(
            boot_dir=_task_image._boot_dir,
            root_dir=_task_image._root_dir,
            machine=config.image.machine,
            version=config.image.version
        )
        _task_ostree.get_deployed_commit()
        _task_ostree.mount_virtualfs()

        # chroot
        _task_chroot = TaskChroot(_task_ostree._ostree_deploy)

        # kernel need to be build from source so, let's do it first
        _task_kernel = TaskKernel(config.image.kernel)
        _task_kernel.config()
        _task_kernel.out_of_tree_modules()
        _task_kernel.cmdline()
        _task_kernel.devicetree()
        _task_kernel.devicetree_overlays()

        # apt
        _task_apt = TaskApt(config.image.apt, _task_chroot)
        _task_apt.update()
        _task_apt.install()
        _task_apt.remove()

        # rootfs
        _task_rootfs = TaskRootfs(config.image.rootfs, _task_chroot)
        _task_rootfs.remove()
        _task_rootfs.merge()
        _task_rootfs.copy()

        # services
        _task_services = TaskServices(config.image.services, _task_chroot)
        _task_services.disable()
        _task_services.enable()

        # security
        _task_security = TaskSecurity(config.image.security, _task_chroot)
        _task_security.hardened()

        # finally commit the changes
        _task_chroot.reconfigure()
        _task_ostree.umount_virtualfs()
        _task_ostree.commit()
        _task_ostree.deploy()
        _task_ostree.push_to_torizon()

    except Exception as e:
        print(f"Error: {e}", color=Color.RED)

        # this is ok to fail, can be a null ref if we do not have inst ostree
        try:
            _task_ostree.umount_virtualfs()
        except Exception as e:
            print(f"Error unmounting virtual fs: {e}", color=Color.RED)
            print("The above error is ok to ignore, the cleanup tryed to clean something that was not mounted", color=Color.YELLOW)

        _task_image.unmount()

        Error_Out(
            "Error while generating the custom image.",
            Error.EINVAL
        )

    # unmount the image
    _task_ostree.umount_virtualfs()
    _task_image.unmount()

    print("Custom image generated successfully!", color=Color.BLACK, bg_color=BgColor.GREEN)


# support for multiple arch
utils.create_cache("binfmt")
if not utils.cached("binfmt", "run"):
    sudo docker run --rm -it --privileged pergamos/binfmt:9.0.2
    utils.write_cache("binfmt", "run")

# call the main function
_main()
# exit the script
