"""Task stubs for the image properties."""
# pylint: disable=import-error
import src.i_custom as i_custom

class TaskImage():
    """Tasks for the image properties."""
    config: i_custom.ImageConfig
    _base_url: str = "https://br-se1.magaluobjects.com/gaia-imgs/"
    _version_path: str
    _loopdev: str
    _image_file: str
    _boot_dir: str
    _root_dir: str

    def __init__(self, config: i_custom.ImageConfig):
        self.config = config
        self._version_path = self.config.version.replace(".", "-")

    def _extract(self):
        """Extract the image."""
        raise NotImplementedError

    def _expand(self):
        """Expand the image. OSTree needs 3% of the image size to be free."""
        raise NotImplementedError

    def download(self):
        """Download the image."""
        raise NotImplementedError

    def mount(self):
        """Mount the image."""
        raise NotImplementedError

    def unmount(self):
        """Unmount the image."""
        raise NotImplementedError


class TaskEnv():
    """Tasks for the environment variables properties."""
    _env: list
    _skip: bool
    _chroot: 'TaskChroot'

    def __init__(
        self,
        env: list,
        task_chroot: 'TaskChroot',
        device: i_custom.DebugDevice | None = None
    ):
        self._env = env
        self._skip = False
        self._chroot = task_chroot
        self._device = device  # Device is used for SSH tasks, if applicable

    def inject(self) -> bool:
        """Set environment variables."""
        raise NotImplementedError


class TaskOstree():
    """Tasks for the ostree properties."""
    _boot_dir: str
    _root_dir: str
    _machine: str
    _ostree_repo: str
    _ostree_deploy: str
    _deploy_commit_hash: str
    _mounted: bool

    def __init__(self, boot_dir: str, root_dir: str, machine: str, version: str):
        self._boot_dir = boot_dir
        self._root_dir = root_dir
        self._machine = machine
        self._ostree_repo = f"{self._root_dir}ostree/repo"
        self._deploy_commit_hash = ""
        self._ostree_deploy = ""
        self._mounted = False
        self._version = version

    def mount_virtualfs(self):
        """mount the virtual fs"""
        raise NotImplementedError

    def umount_virtualfs(self):
        """unmount the virtual fs"""
        raise NotImplementedError

    def get_deployed_commit(self) -> str:
        """Get the deployed commit."""
        raise NotImplementedError

    def commit(self):
        """Commit the ostree repo."""
        raise NotImplementedError

    def deploy(self):
        """Deploy the ostree repo."""
        raise NotImplementedError

    def push_to_torizon(self):
        """Push the ostree repo to Torizon."""
        raise NotImplementedError


class TaskChroot():
    """Tasks for the chroot properties."""
    _root_dir: str

    def __init__(self, root_dir: str):
        self._root_dir = root_dir

    def reconfigure(self):
        """Reconfigure the chroot config mess."""
        raise NotImplementedError

    def run(self, cmd: str) -> int:
        """Run a command in chroot."""
        raise NotImplementedError


class TaskApt():
    """Tasks for the apt packages properties."""
    _apt: i_custom.AptConfig
    _skip: bool
    _chroot: TaskChroot

    def __init__(
        self,
        apt: i_custom.AptConfig,
        task_chroot: TaskChroot,
        device: i_custom.DebugDevice | None = None
    ):
        self._apt = apt
        self._skip = False
        self._chroot = task_chroot
        self._device = device  # Device is used for SSH tasks, if applicable

    def update(self) -> bool:
        """Update the apt packages."""
        raise NotImplementedError

    def install(self) -> bool:
        """Install the apt packages."""
        raise NotImplementedError

    def install_debug(self) -> bool:
        """Install the debug apt packages."""
        raise NotImplementedError

    def remove(self) -> bool:
        """Remove the apt packages."""
        raise NotImplementedError


class TaskRootfs():
    """Tasks for the rootfs properties."""
    _rootfs: i_custom.RootfsConfig
    _skip: bool
    _chroot: TaskChroot

    def __init__(self, rootfs: i_custom.RootfsConfig, task_chroot: TaskChroot):
        self._rootfs = rootfs
        self._skip = False
        self._chroot = task_chroot

    def remove(self):
        """Remove the rootfs configurations."""
        raise NotImplementedError

    def mkdir(self):
        """Create the path uses mkdir -p"""
        raise NotImplementedError

    def merge(self):
        """Merge the rootfs configurations."""
        raise NotImplementedError

    def chroot_debug(self):
        """Run script under the rootfs in debug mode."""
        raise NotImplementedError

    def chroot(self):
        """Run script under the rootfs."""
        raise NotImplementedError

    def copy(self):
        """Copy a file or folder from source to the rootfs."""
        raise NotImplementedError


class TaskServices():
    """Tasks for managing systemd services."""
    _services: i_custom.ServicesConfig
    _skip: bool
    _chroot: TaskChroot

    def __init__(
        self, services: i_custom.ServicesConfig,
        task_chroot: TaskChroot,
        debug: bool = False
    ):
        self._services = services
        self._skip = False
        self._chroot = task_chroot
        self._debug = debug

    def enable(self):
        """Enable the systemd services."""
        raise NotImplementedError

    def disable(self):
        """Disable the systemd services."""
        raise NotImplementedError


class TaskKernel():
    """Tasks for managing kernel tasks."""
    _kernel: i_custom.KernelConfig
    _skip: bool

    def __init__(self, kernel: i_custom.KernelConfig):
        self._kernel = kernel
        self._skip = False

    def cmdline(self):
        """Kernel command line."""
        raise NotImplementedError

    def devicetree(self):
        """Kernel device tree."""
        raise NotImplementedError

    def devicetree_overlays(self):
        """Kernel device tree overlay."""
        raise NotImplementedError

    def config(self):
        """Kernel configuration."""
        raise NotImplementedError

    def out_of_tree_modules(self):
        """Kernel out of tree modules."""
        raise NotImplementedError


class TaskSecurity():
    """Tasks for managing security tasks."""
    _security: i_custom.SecurityConfig
    _skip: bool
    _chroot: TaskChroot

    def __init__(self, security: i_custom.SecurityConfig, task_chroot: TaskChroot):
        self._security = security
        self._skip = False
        self._chroot = task_chroot

    def hardened(self):
        """Apply security hardening measures."""
        raise NotImplementedError


class TaskSshChroot():
    """
    Tasks for the chroot properties via SSH.
    ⚠️ This only works with the insecure dev mode images ⚠️
    """
    _device: i_custom.DebugDevice

    def __init__(self, device: i_custom.DebugDevice, image: i_custom.ImageConfig):
        self._device = device
        self._image = image

    def reconfigure(self):
        """Reconfigure the chroot config mess."""
        raise NotImplementedError

    def copy(self, path: str):
        """Copy a file or folder from source to the rootfs via SSH."""
        raise NotImplementedError

    def run(self, cmd: str) -> int:
        """Run a command in chroot."""
        raise NotImplementedError


class TaskSshRootfs():
    """Tasks for the debug rootfs properties via SSH."""
    _rootfs: i_custom.RootfsConfig
    _skip: bool
    _chroot: TaskChroot
    _device: i_custom.DebugDevice

    def __init__(self, rootfs: i_custom.RootfsConfig, task_chroot: TaskChroot):
        self._rootfs = rootfs
        self._skip = False
        self._chroot = task_chroot
        # Note: _device should be extracted from task_chroot in real implementation

    def mkdir(self):
        """Create the path uses mkdir -p"""
        raise NotImplementedError

    def remove(self):
        """Remove the rootfs configurations."""
        raise NotImplementedError

    def merge(self):
        """Merge the rootfs configurations."""
        raise NotImplementedError

    def chroot_debug(self):
        """Run script under the rootfs in debug mode."""
        raise NotImplementedError

    def chroot(self):
        """Run script under the rootfs."""
        raise NotImplementedError

    def copy(self):
        """Copy a file or folder from source to the rootfs."""
        raise NotImplementedError
