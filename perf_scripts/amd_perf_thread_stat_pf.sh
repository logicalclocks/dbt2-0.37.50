sudo perf stat -e l2_pf_hit_l2 -e l2_pf_miss_l2_hit_l3 -e l2_pf_miss_l2_l3 -e l2_request_g1.l2_hw_pf -t $1 -- sleep $2
echo "l2_pf_hit_l2: Prefetch accesses that hit in L2"
echo "l2_pf_miss_l2_hit_l3: Prefetch accesses that hit in L3 after missing in L2"
echo "l2_pf_miss_l2_l3: Prefetch accesses that miss in both L2 and L3"
echo "l2_request_g1.l2_hw_pf: Prefetch accesses in total to L2, hit or miss"
