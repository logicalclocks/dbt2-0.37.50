sudo perf stat -e l2_cache_req_stat.ls_rd_blk_x -e l2_cache_req_stat.ls_rd_blk_l_hit_x -e l2_cache_req_stat.ls_rd_blk_l_hit_s -e l2_cache_req_stat.ls_rd_blk_cs -e l2_cache_req_stat.ls_rd_blk_c -t $1 -- sleep $2
echo "Analysis of L2 DC accesses"
echo "l2_cache_req_stat.ls_rd_blk_x: L2 Hits for Store access"
echo "l2_cache_req_stat.ls_rd_blk_l_hit_x: L2 Hits for Exclusive Reads found exclusive line"
echo "l2_cache_req_stat.ls_rd_blk_l_hit_s: L2 Hits for Exclusive Read found shared line"
echo "l2_cache_req_stat.ls_rd_blk_cs: L2 Hits for Shared Read accesses"
echo "l2_cache_req_stat.ls_rd_blk_c: L2 Misses"
