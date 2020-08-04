#!/usr/bin/python
try:
    from typing import List
except ImportError:
    pass

import json

import os
import sys


def _main():
    # type: () -> None
    if sys.argv[1:] == ["-v"]:
        os.system("swiftc -v")
        return
    _touch_deps_files(sys.argv)
    _touch_swiftmodule_files(sys.argv)


def _touch_deps_files(args):
    # type: (List[str]) -> None
    "Touch the Xcode-required .d files"
    flag = args.index("-output-file-map")
    output_file_map_path = args[flag + 1]
    with open(output_file_map_path) as f:
        output_file_map = json.load(f)
    d_files = [
        entry["dependencies"]
        for entry in output_file_map.values()
        if "dependencies" in entry
    ]
    for d_file in d_files:
        _touch(d_file)


def _touch_swiftmodule_files(args):
    # type: (List[str]) -> None
    "Touch the Xcode-required .swiftmodule and .swiftdoc files"
    flag = args.index("-emit-module-path")
    swiftmodule_path = args[flag + 1]
    swiftdoc_path = _replace_ext(swiftmodule_path, "swiftdoc")
    swiftsourceinfo_path = _replace_ext(swiftmodule_path, "swiftsourceinfo")
    _touch(swiftmodule_path)
    _touch(swiftdoc_path)
    _touch(swiftsourceinfo_path)
    header_path = swiftmodule_path.replace((".swiftmodule"), "-Swift.h")
    _touch(header_path)


def _touch(path):
    # type: (str) -> None
    open(path, "a")


def _replace_ext(path, extension):
    # type: (str, str) -> str
    name, _ = os.path.splitext(path)
    return ".".join((name, extension))


if __name__ == "__main__":
    _main()
