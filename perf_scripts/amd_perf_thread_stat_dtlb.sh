sudo perf stat -e ls_l1_d_tlb_miss.all -e ls_l1_d_tlb_miss.tlb_reload_2m_l2_hit -e ls_l1_d_tlb_miss.tlb_reload_4k_l2_hit -e ls_l1_d_tlb_miss.tlb_reload_2m_l2_miss -e ls_l1_d_tlb_miss.tlb_reload_4k_l2_miss -e ls_l1_d_tlb_miss.tlb_reload_coalesced_page_hit -e ls_l1_d_tlb_miss.tlb_reload_coalesced_page_miss  -t $1 -- sleep $2
echo "Analysis of DTLB accesses"
