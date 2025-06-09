"""kernel tasks."""

# pylint: disable=import-error
# pylint: disable=wrong-import-order

import src.i_custom as i_custom
# we are redefining the print to have colors
# pylint: disable=redefined-builtin
from torizon_templates_utils.colors import print


class TaskKernel():
    """Tasks for managing kernel tasks."""

    def __init__(self, kernel: i_custom.KernelConfig):
        self._kernel = kernel
        self._skip = kernel is None

        if not self._skip:
            raise NotImplementedError(
                "Kernel configuration is not implemented yet."
            )


    def cmdline(self):
        """Kernel command line."""
        if self._skip:
            print("No kernel command line to set.")
            return


    def devicetree(self):
        """Kernel device tree."""
        if self._skip:
            print("No kernel device tree to set.")
            return


    def devicetree_overlays(self):
        """Kernel device tree overlay."""
        if self._skip:
            print("No kernel device tree overlay to set.")
            return


    def config(self):
        """Kernel configuration."""
        if self._skip:
            print("No kernel configuration to set.")
            return


    def out_of_tree_modules(self):
        """Kernel out of tree modules."""
        if self._skip:
            print("No kernel out of tree modules to set.")
            return
