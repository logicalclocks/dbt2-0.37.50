# This script checks CPU counters for a specific thread
# Call structure:
# ./perf_thread_stat.sh TID TIME or
# ./perf_thread_stat.sh TID TIME 2> file
sudo perf stat -d -d -d -t $1 -- sleep $2
