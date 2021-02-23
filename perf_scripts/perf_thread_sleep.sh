# This script provides information about a specific thread on where it is spending its sleep time.
# So every time a thread goes to sleep (sleep, pthread_cond_wait, select, mutex lock and so forth)
# this script measures the time of the sleep and provides the stack traces of the most common reasons
# for sleeping of the thread.
#
# This is very useful in discovering if there are certain bottlenecks that hurt the thread execution.
# E.g. if a thread spends a lot of time in sleeping on a mutex lock it would be noticelable here.
#
# Calling structure:
# ./perf_thread_sleep.sh TID TIME or
# ./perf_thread_sleep.sh TID TIME > file
# TID can easily be found using top -H that displays the most active threads.
echo 1 | sudo tee /proc/sys/kernel/sched_schedstats
sudo perf record -e sched:sched_stat_sleep -e sched:sched_switch  -e sched:sched_process_exit -g -t $1 -o perf_raw.data -- sleep $2
echo 0 | sudo tee /proc/sys/kernel/sched_schedstats
sudo perf inject -v -s -i perf_raw.data -o perf.data
sudo perf report --stdio --show-total-period -i perf.data
