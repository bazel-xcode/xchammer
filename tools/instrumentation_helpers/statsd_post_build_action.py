import os
import time
import socket
import json

TSD_HOST = ""
TSD_PORT = 80

TSD_TIMEOUT_SEC = 5

def write_tsd(metric, delta):
    timestamp = int(round(time.time()))
    tags = "host={}".format(socket.gethostname())
    tsd = "put {metric} {timestamp} {delta} {tags}\n".format(metric=metric,
                                                           timestamp=timestamp,
                                                           delta=delta,
                                                           tags=tags)
    try:
        sock = socket.create_connection((TSD_HOST, TSD_PORT),
                                        timeout=TSD_TIMEOUT_SEC)
        sock.sendall(tsd)
        sock.close()
    except Exception:
        print("failed to write '{}' to {}:{}".format(tsd, TSD_HOST, TSD_PORT))


def write_build_metric():
    start_time_f = os.path.join(
        os.environ.get('TARGET_BUILD_DIR'),'xchammer.build_start')
    start_time = os.path.getmtime(start_time_f)
    delta = ((time.time()-start_time)*1000)
    write_tsd("xchammer.build", delta)


def write_last_generation_metric():
    build_dir = os.environ.get('OBJROOT')
    if build_dir:
        base_path = build_dir
    else:
        base_path = "/private/var/tmp"

    last_generation_log = os.path.join(base_path, 'xchammer.log')
    with open(last_generation_log, "r") as f:
        for l, i in enumerate(f):
            json_str = i.split("\n")[0]
            trace_entry = json.loads(json_str)
            write_tsd(trace_entry["name"], trace_entry["ts"])


# Write the build metric and then write the last generation metric
write_build_metric()
write_last_generation_metric()

