import os
import time
import re
import socket
import json
import platform
import multiprocessing
import getpass

# Set this to the value of the statsd backend
# Consider:
# - allowing the user to specify this as a config
# - adding the ability to load hooks as an external repo.
TSD_HOST = ""
TSD_PORT = 80
TSD_TIMEOUT_SEC = 5
INVALID_LABEL_REG = re.compile(r"[^\._a-zA-Z0-9]")


def extract_profile_line(line, item):
    if item in line:
        result = line.split(item + ": ")
        if len(result) > 1:
            return result[1]
    return None

# Memoize calls to system_profiler
PROFILE_INFO = None

def get_system_profile():
    global PROFILE_INFO
    if PROFILE_INFO:
        return PROFILE_INFO

    process = os.popen("system_profiler SPHardwareDataType")
    result = process.read()
    lines = result.split("\n")
    output = {}
    for line in lines:
        memory = extract_profile_line(line, "Memory")
        if memory:
            output["memory"] = memory

        model_identifier = extract_profile_line(line, "Model Identifier")
        if model_identifier:
            output["model_identifier"] = model_identifier

        processor_speed  = extract_profile_line(line, "Processor Speed")
        if processor_speed:
            output["processor_speed"] = processor_speed

        processor_name  = extract_profile_line(line, "Processor Name")
        if processor_name:
            output["processor_name"] = processor_name

    # Get some stats about the host
    output["os_version"] = platform.mac_ver()[0]

    # This will optionally print the number of virtual cores - see docs for more info
    output["cpu_count"] = multiprocessing.cpu_count()

    output["host"] = socket.gethostname()

    output["username"] = getpass.getuser()
    PROFILE_INFO = output
    return output


def get_tsd(tags_dict):
    items = []
    for key, value in tags_dict.items():
        str_val = str(value)
        items.append("{}={}".format(key, INVALID_LABEL_REG.sub("_", str_val)))
    return " ".join(items)


def write_tsd(metric, delta):
    timestamp = int(round(time.time()))
    tags_dict = get_system_profile()
    tags = get_tsd(tags_dict)
    tsd = "put {metric} {timestamp} {delta} {tags}\n".format(
        metric=metric,
        timestamp=timestamp,
        delta=delta,
        tags=tags)
    try:
        sock = socket.create_connection(
            (TSD_HOST, TSD_PORT),
            timeout=TSD_TIMEOUT_SEC)
        sock.sendall(tsd)
        sock.close()
    except Exception:
        print("failed to write '{}' to {}:{}".format(tsd, TSD_HOST, TSD_PORT))


def write_build_metric():
    start_time_f = os.path.join(
        os.environ.get("TARGET_BUILD_DIR"), "xchammer.build_start")
    start_time = os.path.getmtime(start_time_f)
    delta = ((time.time()-start_time)*1000)
    metric = "xchammer.build"
    build_target = os.environ.get("TARGET_NAME")
    if build_target:
        metric += "." + build_target

    write_tsd(metric, delta)


def write_last_generation_metric():
    build_dir = os.environ.get("OBJROOT")
    if build_dir:
        base_path = build_dir
    else:
        base_path = "/private/var/tmp"

    last_generation_log = os.path.join(base_path, "xchammer.log")
    with open(last_generation_log, "r") as f:
        for l, i in enumerate(f):
            json_str = i.split("\n")[0]
            trace_entry = json.loads(json_str)
            write_tsd(trace_entry["name"], trace_entry["ts"])

