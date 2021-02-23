# This script is used to provide a call graph of the most common stack traces
# a specific thread is located in. It checks call traces at a frequency of
# 99 Hz to avoid overloading the thread.
#
# Calling structure
# ./perf_thread_exec_graph.sh TID TIME
# ./perf_thread_exec_graph.sh TID TIME > file
# The easiest way to discover the TID is by using top -H to see all threads
# that use most of the CPUs.
sudo perf record -e LLC-store-misses -t $1 -g -- sleep $2
sudo perf report
