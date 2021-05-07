sudo perf stat -e l2_request_g1.cacheable_ic_read -e l2_request_g1.change_to_x -e l2_request_g1.l2_hw_pf -e l2_request_g1.ls_rd_blk_c_s -e l2_request_g1.rd_blk_l -e l2_request_g1.rd_blk_x -t $1 -- sleep $2
echo "Total number of L2 accesses"
echo "l2_request_g1.cacheable_ic_read: L2 IC accesses"
echo "l2_request_g1.change_to_x: L2 Request to change state of cache line"
echo "l2_request_g1.l2_hw_pf: L2 Prefetch accesses"
echo "l2_request_g1.ls_rd_blk_c_s: L2 Shared read accesses"
echo "l2_request_g1.rd_blk_l: L2 DC Reads (includes HW/SW prefetch)"
echo "l2_request_g1.rd_blk_x: L2 DC Stores"
