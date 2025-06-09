# pylint: disable=missing-function-docstring
import debugpy # type: ignore

DEBUG_INITIALIZED = False

def init():
    print("__debugpy__")
    debugpy.listen(("0.0.0.0", 5678))
    print("__debugpy__ go")
    debugpy.wait_for_client()

# we are redefining the breakpoint function to be able to debug with IDE
# pylint: disable=redefined-builtin
def breakpoint():
    # pylint: disable=global-statement
    global DEBUG_INITIALIZED

    if not DEBUG_INITIALIZED:
        init()
        DEBUG_INITIALIZED = True

    debugpy.breakpoint()
