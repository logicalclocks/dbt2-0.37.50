sudo perf stat -e l2_cache_req_stat.ic_fill_hit_s -e l2_cache_req_stat.ic_fill_miss -e l2_request_g1.cacheable_ic_read -t $1 -- sleep $2
echo "l2_cache_req_stat.ic_fill_hit_s: L2 hit for IC access"
echo "l2_cache_req_stat.ic_fill_miss: L2 Miss for IC access"
echo "l2_request_g1.cacheable_ic_read: Total number of L2 IC accesses"
