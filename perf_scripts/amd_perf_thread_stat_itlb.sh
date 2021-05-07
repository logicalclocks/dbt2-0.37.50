sudo perf stat -e bp_l1_tlb_fetch_hit -e bp_l1_tlb_fetch_hit.if2m -e bp_l1_tlb_fetch_hit.if4k -e bp_l1_tlb_miss_l2_hit -e bp_l1_tlb_miss_l2_tlb_miss -e bp_l1_tlb_miss_l2_tlb_miss.if2m -e bp_l1_tlb_miss_l2_tlb_miss.if4k -t $1 -- sleep $2
echo "IC accesses that result in ITLB hits and misses"
