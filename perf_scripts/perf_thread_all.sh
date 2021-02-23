# This script runs a number of perf scripts on a specific thread.
# Call structure:
# ./perf_thread_all.sh TID TIME FILE
# Output is found in FILE.sleep, FILE.exec, FILE.wait_cpu, FILE.stat
LOCAL_TID="$1"
LOCAL_TIME="$2"
LOCAL_FILE="$3"
./perf_thread_sleep.sh $LOCAL_TID $LOCAL_TIME > ${LOCAL_FILE}.sleep
./perf_thread_exec_graph.sh $LOCAL_TID $LOCAL_TIME > ${LOCAL_FILE}.exec
./perf_thread_wait_cpu.sh $LOCAL_TID $LOCAL_TIME 2> ${LOCAL_FILE}.wait_cpu
./perf_thread_stat.sh $LOCAL_TID $LOCAL_TIME 2> ${LOCAL_FILE}.stat
