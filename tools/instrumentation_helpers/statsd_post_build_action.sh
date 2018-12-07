CLIENT="$SRCROOT/tools/instrumentation_helpers/statsd_post_build_action.py"
python $CLIENT 2>&1 | cat > /tmp/x

