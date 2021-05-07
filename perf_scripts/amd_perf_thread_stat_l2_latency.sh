sudo perf stat -e l2_request_g2.group1 -e l2_latency.l2_cycles_waiting_on_fills -e l2_fill_pending.l2_fill_busy -t $1 -- sleep $2
echo "Can be used to calculate average L2 latency."
