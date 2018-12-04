# If the user provides a statsd client, then run that
CLIENT="$SRCROOT/tools/instrumentation_helpers/statsd_client"
if [[ ! -x $CLIENT ]]; then
    exit 0
fi

# Compute the delta from the build_start sentenial
python  << EOF
import os
import time
start_time_f = os.path.join(
os.environ.get('TARGET_BUILD_DIR'),'xchammer.build_start')
start_time = os.path.getmtime(start_time_f)
print((time.time()-start_time)*1000)
EOF

# Write XCHammer builds to the statsd client
echo "put xchammer.build.${TARGETNAME} $(date +%s) $ELAPSED host=$(hostname)" \
    | $CLIENT &
