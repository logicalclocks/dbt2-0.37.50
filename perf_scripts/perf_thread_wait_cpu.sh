# This script measures the amount of time the thread had to wait due to
# no CPU being available to run on.
#
# Call structure:
# ./perf_thread_wait_cpu.sh TID TIME or
# ./perf_thread_wait_cpu.sh TID TIME 2> file
sudo perf stat -e sched:sched_stat_wait -e task-clock -t $1 -- sleep $2
