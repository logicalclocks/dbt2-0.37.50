# Calling structure
# ./amd_perf_thread_stat_l3.sh TIME
# ./amd_perf_thread_stat_l3.sh TIME > file
sudo perf stat  -e l3_lookup_state.all_l3_req_typs -e l3_comb_clstr_state.other_l3_miss_typs -e l3_comb_clstr_state.request_miss -e l3_request_g1.caching_l3_cache_accesses -e xi_ccx_sdp_req1.all_l3_miss_req_typs -e xi_sys_fill_latency sleep $1
