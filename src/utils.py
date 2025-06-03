"""Utility functions for the application."""

import os
import time
import glob
import hashlib


def create_cache(task: str):
    """Create the cache directory structure if it doesn't exist."""
    os.makedirs(f"./.opus/{task}", exist_ok=True)


def cached(task: str, action: str, timeout: int = 86400) -> bool:
    """Check if the cache for a task and action is still valid."""
    if not os.path.exists(f"./.opus/{task}/{action}"):
        # If the cache file does not exist, create it
        os.makedirs(f"./.opus/{task}", exist_ok=True)
        return False

    with open(f"./.opus/{task}/{action}", "r", encoding="utf-8") as f:
        last_action = int(f.read().strip())

    return (time.time() - last_action) < timeout


def write_cache(task: str, action: str):
    """write the timespamp of the last action"""
    with open(f"./.opus/{task}/{action}", "w", encoding="utf-8") as f:
        f.write(str(int(time.time())))


def cached_f(task: str, action: str, file: str) -> bool:
    """Check if the cache for a file is still valid."""
    # get the hash of the file contents
    with open(file, "rb") as f:
        file_contents = f.read()
    file_hash = hashlib.md5(file_contents).hexdigest()

    # check if the cache file exists
    cache_file = f"./.opus/{task}/{action}/{file_hash}.cache"
    if not os.path.exists(cache_file):
        os.makedirs(f"./.opus/{task}/{action}", exist_ok=True)
        return False

    # read the hash from the cache
    with open(cache_file, "r", encoding="utf-8") as f:
        cached_hash = f.read().strip()

    return cached_hash == file_hash


def write_cache_f(task: str, action: str, file: str):
    """Write the hash of the file to the cache."""
    # get the hash of the file contents
    with open(file, "rb") as f:
        file_contents = f.read()
    file_hash = hashlib.md5(file_contents).hexdigest()

    # write the hash to the cache
    cache_file = f"./.opus/{task}/{action}/{file_hash}.cache"
    os.makedirs(f"./.opus/{task}/{action}", exist_ok=True)

    # delete all cache files from the cache directory
    cache_files = glob.glob(f"./.opus/{task}/{action}/*.cache")
    for cache_file in cache_files:
        os.remove(cache_file)

    with open(cache_file, "w", encoding="utf-8") as f:
        f.write(file_hash)
