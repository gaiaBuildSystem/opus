"""Interface for custom schema."""
import os
from typing import List, Optional
from jsonschema import validate # type: ignore
import yaml # type: ignore

class AptConfig:
    """Configuration for apt package management."""
    install: Optional[List[str]] = None
    install_debug: Optional[List[str]] = None
    remove: Optional[List[str]] = None

    def __init__(
        self,
        install: Optional[List[str]] = None,
        install_debug: Optional[List[str]] = None,
        remove: Optional[List[str]] = None
    ):
        self.install = install
        self.install_debug = install_debug
        self.remove = remove

class RootfsConfig:
    """Configuration for root filesystem modifications."""
    merge: Optional[List[str]] = None
    remove: Optional[List[str]] = None
    chroot_debug: Optional[List[str]] = None
    chroot: Optional[List[str]] = None
    copy: Optional[List[str]] = None

    def __init__(
            self,
            merge: Optional[List[str]] = None,
            remove: Optional[List[str]] = None,
            chroot_debug: Optional[List[str]] = None,
            chroot: Optional[List[str]] = None,
            copy: Optional[List[str]] = None
    ):
        self.merge = merge
        self.remove = remove
        self.chroot_debug = chroot_debug
        self.chroot = chroot
        self.copy = copy

class KernelConfig:
    """Configuration for kernel properties."""
    cmdline: Optional[List[str]] = None
    devicetree: Optional[List[str]] = None
    devicetree_overlays: Optional[List[str]] = None
    config: Optional[dict] = None
    out_of_tree_modules: Optional[List[str]] = None

    def __init__(
            self,
            cmdline: Optional[List[str]] = None,
            devicetree: Optional[List[str]] = None,
            devicetree_overlays: Optional[List[str]] = None,
            config: Optional[dict] = None,
            out_of_tree_modules: Optional[List[str]] = None
    ):
        self.cmdline = cmdline
        self.devicetree = devicetree
        self.devicetree_overlays = devicetree_overlays
        self.config = config
        self.out_of_tree_modules = out_of_tree_modules

class DebugDevice:
    """Configuration for debug device."""
    ip: str
    port: str

    def __init__(self, ip: str, port: str):
        self.ip = ip
        self.port = port

class DebugConfig:
    """Configuration for debug mode."""
    enable: Optional[bool] = None
    device: Optional[DebugDevice] = None

    def __init__(self, enable: Optional[bool] = None, device: Optional[dict] = None):
        self.enable = enable
        self.device = DebugDevice(**device) if device else None

class ServicesConfig:
    """Configuration for systemd services."""
    enable: Optional[List[str]] = None
    disable: Optional[List[str]] = None

    def __init__(
            self,
            enable: Optional[List[str]] = None,
            disable: Optional[List[str]] = None
    ):
        self.enable = enable
        self.disable = disable

class SecurityConfig:
    """Configuration for security settings."""
    hardened: bool

    def __init__(self, hardened: bool):
        self.hardened = hardened

class ImageConfig:
    """Detailed configuration for the image."""
    machine: str
    version: str
    increase: Optional[str] = None
    debug: Optional[DebugConfig] = None
    apt: Optional[AptConfig] = None
    rootfs: Optional[RootfsConfig] = None
    services: Optional[ServicesConfig] = None
    kernel: Optional[KernelConfig] = None
    security: Optional[SecurityConfig] = None

    def __init__(
            self,
            machine: str,
            version: str,
            increase: Optional[str] = None,
            debug: Optional[dict] = None,
            apt: Optional[dict] = None,
            rootfs: Optional[dict] = None,
            services: Optional[dict] = None,
            kernel: Optional[dict] = None,
            security: Optional[dict] = None
    ):
        self.machine = machine
        self.version = version
        self.increase = increase
        self.debug = DebugConfig(**debug) if debug else None
        self.apt = AptConfig(**apt) if apt else None
        self.rootfs = RootfsConfig(**rootfs) if rootfs else None
        self.services = ServicesConfig(**services) if services else None
        self.kernel = KernelConfig(**kernel) if kernel else None
        self.security = SecurityConfig(**security) if security else None

class CustomSchemaInterface:
    """
    Interface for custom schema, reflecting the nested structure of the YAML
    as defined in custom.json.
    """
    image: ImageConfig

    def __init__(self, image: dict):
        self.image = ImageConfig(**image)

    def summary(self) -> None:
        """
        Generate a summary of the configuration.
        """
        print(f"Machine: {self.image.machine}")
        print(f"Version: {self.image.version}")
        if self.image.apt:
            if self.image.apt.install:
                print(f"Pkgs to Install: {len(self.image.apt.install)}")
            if self.image.apt.install_debug:
                print(f"Pkgs to Install (Debug): {len(self.image.apt.install_debug)}")
            if self.image.apt.remove:
                print(f"Pkgs to Remove: {len(self.image.apt.remove)}")
        if self.image.rootfs:
            if self.image.rootfs.merge:
                print(f"Rootfs to Merge: {len(self.image.rootfs.merge)}")
            if self.image.rootfs.remove:
                print(f"Rootfs to Remove: {len(self.image.rootfs.remove)}")
            if self.image.rootfs.chroot_debug:
                print(f"Rootfs to Chroot Debug: {len(self.image.rootfs.chroot_debug)}")
            if self.image.rootfs.chroot:
                print(f"Rootfs to Chroot: {len(self.image.rootfs.chroot)}")
        if self.image.kernel:
            if self.image.kernel.cmdline:
                print(f"Kernel Cmdline to apply: {len(self.image.kernel.cmdline)}")
            if self.image.kernel.devicetree:
                print(f"Kernel Devicetree to apply: {len(self.image.kernel.devicetree)}")
            if self.image.kernel.devicetree_overlays:
                # pylint: disable=line-too-long
                print(f"Kernel Devicetree Overlays to apply: {len(self.image.kernel.devicetree_overlays)}")
            if self.image.kernel.config:
                print(f"Kernel Config options to apply: {len(self.image.kernel.config)}")
            if self.image.kernel.out_of_tree_modules:
                # pylint: disable=line-too-long
                print(f"Kernel Out-of-tree modules to apply: {len(self.image.kernel.out_of_tree_modules)}")
        if self.image.security:
            print(f"Security Hardened: {self.image.security.hardened}")
        if self.image.debug:
            print(f"Debug Enabled: {self.image.debug.enable}")

    @staticmethod
    def from_yaml() -> 'CustomSchemaInterface':
        """
        Load the YAML configuration from a file and return an instance of
        CustomSchemaInterface.
        """
        # get the script directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        # get the schema
        with open(os.path.join(script_dir, 'schema/custom.json'), 'r', encoding='utf-8') as f:
            schema = yaml.safe_load(f)

        # read from the pwd the ./custom.yaml file
        with open('./custom.yaml', 'r', encoding='utf-8') as f:
            data_dict = yaml.safe_load(f)
        if not isinstance(data_dict, dict):
            raise TypeError(f"Expected YAML to load as a dictionary, but got {type(data_dict)}")

        # Validate the data against the schema
        validate(instance=data_dict, schema=schema)

        return CustomSchemaInterface(**data_dict)
