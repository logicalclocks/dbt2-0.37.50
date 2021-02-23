#!/bin/bash
# ----------------------------------------------------------------------
# Copyright (C) 2007 Dolphin Interconnect Solutions ASA, iClaustron  AB
#   2008, 2016 Oracle and/or its affiliates. All rights reserved.
# Copyright (c) 2021, 2021, Logical Clocks AB and/or its affiliates.
# www.dolphinics.no
# www.iclaustron.com
# ----------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; only version 2 of the License
#
# The GPL License is only valid with the above copyright notice retained.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

#Ensure all messages are sent both to the log file and to the terminal
msg_to_log()
{
  if test "x$LOG_FILE" != "x" ; then
    ${ECHO} "$MSG" >> ${LOG_FILE}
    if test "x$?" != "x0" ; then
      ${ECHO} "Failure $? unable to write $* to ${LOG_FILE}"
      exit 1
    fi
  fi
}

#Method used to write any output to log what script is doing
output_msg()
{
  ${ECHO} "$MSG"
  msg_to_log
}

set_ld_library_path()
{
  ADD_LIB_PATH="${MYSQL_PATH}/lib/mysql:${MYSQL_PATH}/lib"
  if test "x$LD_LIBRARY_PATH" = "x" ; then
    LD_LIBRARY_PATH="$ADD_LIB_PATH"
  else
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$ADD_LIB_PATH"
  fi
  if test "x$DYLD_LIBRARY_PATH" = "x" ; then
    DYLD_LIBRARY_PATH="$ADD_LIB_PATH"
  else
    DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:$ADD_LIB_PATH"
  fi
  export LD_LIBRARY_PATH
  export DYLD_LIBRARY_PATH
}

stop_mysql()
{
  MSG="Stop ${SERVER_TYPE} Server"
  output_msg
  COMMAND="${DBT2_PATH}/scripts/mgm_cluster.sh"
  COMMAND="${COMMAND} --default-directory ${DEFAULT_DIR}"
  COMMAND="${COMMAND} --stop --${SERVER_TYPE_NAME}"
  COMMAND="${COMMAND} --cluster_id 1"
  COMMAND="${COMMAND} --conf-file ${DEFAULT_CLUSTER_CONFIG_FILE}"
  COMMAND="${COMMAND} ${VERBOSE_FLAG}"
  MSG="Executing ${COMMAND}"
  output_msg
  ${COMMAND}
  RET_CODE="$?"
  if test "x$RET_CODE" = "x1" ; then
    MSG="Failed to stop ${SERVER_TYPE} Server"
    output_msg
  elif test "x$RET_CODE" = "x0" ; then
    ${SLEEP} ${AFTER_SERVER_STOP}
    MSG="Stopped ${SERVER_TYPE} Server"
    output_msg
  else
    MSG="Stopped ${SERVER_TYPE} Server"
    output_msg
  fi
}

restart_ndb_node()
{
  MSG="Restart ${SERVER_TYPE} Server"
  output_msg
  COMMAND="${DBT2_PATH}/scripts/mgm_cluster.sh"
  COMMAND="${COMMAND} --default-directory ${DEFAULT_DIR}"
  if test "x$NDB_RESTART_NODE" = "xall" ; then
    COMMAND="${COMMAND} --ndb_restart_all --${SERVER_TYPE_NAME}"
  else
    if test "x$NDB_RESTART_TEST_INITIAL" = "xyes" ; then
      COMMAND="${COMMAND} --ndb_restart_initial_node $NDB_RESTART_NODE"
      COMMAND="${COMMAND} --${SERVER_TYPE_NAME}"
    else
      COMMAND="${COMMAND} --ndb_restart_node $NDB_RESTART_NODE"
      COMMAND="${COMMAND} --${SERVER_TYPE_NAME}"
    fi
  fi
  COMMAND="${COMMAND} --cluster_id 1"
  COMMAND="${COMMAND} --conf-file ${DEFAULT_CLUSTER_CONFIG_FILE}"
  COMMAND="${COMMAND} ${VERBOSE_FLAG}"
  MSG="Executing ${COMMAND}"
  output_msg
  ${COMMAND}
  RET_CODE="$?"
  if test "x$RET_CODE" = "x1" ; then
    MSG="Failed to restart ${SERVER_TYPE} Server"
    output_msg
  else
    MSG="Restarted ${SERVER_TYPE} Server"
    output_msg
  fi
}

start_mysql()
{
  MSG="Start ${SERVER_TYPE} Server"
  output_msg
  COMMAND="${DBT2_PATH}/scripts/mgm_cluster.sh"
  COMMAND="${COMMAND} --default-directory ${DEFAULT_DIR}"
  COMMAND="${COMMAND} --start ${INITIAL_FLAG}"
  COMMAND="${COMMAND} --${SERVER_TYPE_NAME} --cluster_id 1"
  COMMAND="${COMMAND} --conf-file ${DEFAULT_CLUSTER_CONFIG_FILE}"
  COMMAND="${COMMAND} ${VERBOSE_FLAG}"
  MSG="Executing ${COMMAND}"
  output_msg
  ${COMMAND}
  RET_CODE="$?"
  if test "x$RET_CODE" = "x1" ; then
    MSG="Failed to start ${SERVER_TYPE}"
    output_msg
    exit 1
  fi
  if test "x$RET_CODE" = "x0" ; then
    echo "Start sleeping after servers started"
    ${SLEEP} ${AFTER_SERVER_START}
  fi
}

exit_func()
{
  if test "x${SKIP_STOP}" != "xyes" ; then
    stop_mysql
  fi
  echo "Exit run_oltp.sh"
  exit 1
}

edit_pfs_synch()
{
  if test "x$MYSQL_SERVER_BASE" != "x5.1" ; then
    BASE_COMMAND="${MYSQL_PATH}/bin/mysql -h ${SERVER_HOST}"
    BASE_COMMAND="$BASE_COMMAND --port=${SERVER_PORT}"
    BASE_COMMAND="$BASE_COMMAND --protocol=tcp"
      PFS_SYNCH_CMD="$BASE_COMMAND < ${DBT2_PATH}/scripts/PFS_synch_55.sql"
    fi
    if test "x${USE_DOCKER}" = "xyes" ; then
      BASE_COMMAND="$BASE_COMMAND --user=$MYSQL_USER --password=password"
    else
      BASE_COMMAND="$BASE_COMMAND --user=$MYSQL_USER"
      if test "x$MYSQL_PASSWORD" != "x" ; then
        BASE_COMMAND="$BASE_COMMAND -p'$MYSQL_PASSWORD'"
      fi
    fi
    if test "x$MYSQL_SERVER_BASE" = "x5.5" ; then
    if test "x$MYSQL_SERVER_BASE" = "x5.6" || \
       test "x$MYSQL_SERVER_BASE" = "x5.7" || \
       test "x$MYSQL_SERVER_BASE" = "x8.0" ; then
      if test "x$USE_IRONDB" != "xyes" ; then
        PFS_SYNCH_CMD="$BASE_COMMAND < ${DBT2_PATH}/scripts/PFS_synch.sql"
      else
        PFS_SYNCH_CMD="$BASE_COMMAND < ${MYSQL_PATH}/dbt2_install/scripts/PFS_synch.sql"
      fi
    fi
    if test "x${VERBOSE_FLAG}" != "x" ; then
      MSG="Executing ${PFS_SYNCH_CMD}"
      output_msg
    fi
    eval ${PFS_SYNCH_CMD}
    if test "x$?" = "x0" ; then
      MSG="Successfully changed to only tracking mutexes in PFS"
      output_msg
    fi
  fi
}

create_test_user()
{
  BASE_COMMAND="${MYSQL_PATH}/bin/mysql -h ${SERVER_HOST}"
  BASE_COMMAND="$BASE_COMMAND --port=${SERVER_PORT}"
  BASE_COMMAND="$BASE_COMMAND --protocol=tcp"
  if test "x${USE_DOCKER}" = "xyes" ; then
    BASE_COMMAND="$BASE_COMMAND --user=$MYSQL_USER --password=password"
  else
    BASE_COMMAND="$BASE_COMMAND --user=$MYSQL_USER"
    if test "x$MYSQL_PASSWORD" != "x" ; then
      BASE_COMMAND="$BASE_COMMAND -p'$MYSQL_PASSWORD'"
    fi
  fi
  CREATE_TEST_USER_CMD="$BASE_COMMAND < ${DBT2_PATH}/scripts/create_user.sql"
  if test "x${VERBOSE_FLAG}" != "x" ; then
    MSG="Executing ${CREATE_TEST_USER_CMD}"
    output_msg
  fi
  eval ${CREATE_TEST_USER_CMD}
  if test "x$?" = "x0" ; then
    MSG="Successfully create test user dim identified by dimitri"
    output_msg
  fi
}

check_test_database()
{
  BASE_COMMAND="${MYSQL_PATH}/bin/mysql -h ${SERVER_HOST}"
  BASE_COMMAND="${BASE_COMMAND} --protocol=tcp"
  BASE_COMMAND="$BASE_COMMAND --port=${SERVER_PORT}"
  if test "x${USE_DOCKER}" = "xyes" ; then
    BASE_COMMAND="$BASE_COMMAND --user=$MYSQL_USER --password=password"
  else
    BASE_COMMAND="$BASE_COMMAND --user=$MYSQL_USER"
    if test "x$MYSQL_PASSWORD" != "x" ; then
      BASE_COMMAND="$BASE_COMMAND -p'$MYSQL_PASSWORD'"
    fi
  fi
  CREATE_DB_COMMAND="${BASE_COMMAND} -e 'create database ${SYSBENCH_DB}'"
  DROP_DB_COMMAND="${BASE_COMMAND} -e 'drop database ${SYSBENCH_DB}'"
  for ((i_ctd = 0; i_ctd < NUM_CREATE_DB_ATTEMPTS ; i_ctd+=1 ))
  do
    MSG="Checking if MySQL Server is started by drop+create of test db"
    output_msg
    if test "x${VERBOSE_FLAG}" != "x" ; then
      MSG="Executing ${DROP_DB_COMMAND}"
      output_msg
    fi
    eval ${DROP_DB_COMMAND}
    if test "x${VERBOSE_FLAG}" != "x" ; then
      MSG="Executing ${CREATE_DB_COMMAND}"
      output_msg
    fi
    eval ${CREATE_DB_COMMAND}
    if test "x$?" = "x0" ; then
      MSG="Successfully started ${SERVER_TYPE} Server, test db created"
      output_msg
      return 0
    fi
    ${SLEEP} ${BETWEEN_CREATE_DB_TEST}
  done
  MSG="Failed to create test database"
  output_msg
  exit_func
}

create_test_database()
{
  CTD_BASE_COMMAND="${MYSQL_PATH}/bin/mysql -h ${SERVER_HOST}"
  CTD_BASE_COMMAND="${CTD_BASE_COMMAND} --protocol=tcp"
  CTD_BASE_COMMAND="${CTD_BASE_COMMAND} --port=${SERVER_PORT}"
  if test "x${USE_DOCKER}" = "xyes" ; then
    CTD_BASE_COMMAND="${CTD_BASE_COMMAND} --user=$MYSQL_USER --password=password"
  else
    CTD_BASE_COMMAND="${CTD_BASE_COMMAND} --user=$MYSQL_USER"
    if test "x$MYSQL_PASSWORD" != "x" ; then
      CTD_BASE_COMMAND="${CTD_BASE_COMMAND} -p'$MYSQL_PASSWORD'"
    fi
  fi
  CREATE_DB_COMMAND="${CTD_BASE_COMMAND} -e 'create database ${SYSBENCH_DB}'"
  MSG="$CREATE_DB_COMMAND"
  output_msg
  eval ${CREATE_DB_COMMAND}
  if test "x$?" != "x0" ; then
    MSG="Failed to create test database ${SYSBENCH_DB}"
    output_msg
    drop_test_database
    eval ${CREATE_DB_COMMAND}
    if test "x$?" != "x0" ; then
      MSG="Really failed to create test database ${SYSBENCH_DB}"
      output_msg
      exit_func
     fi
  fi
  MSG="Created database $SYSBENCH_DB succesfully"
  output_msg
  return 0
}

drop_test_database()
{
  DTD_BASE_COMMAND="${MYSQL_PATH}/bin/mysql -h ${SERVER_HOST}"
  DTD_BASE_COMMAND="${DTD_BASE_COMMAND} --protocol=tcp"
  DTD_BASE_COMMAND="${DTD_BASE_COMMAND} --port=${SERVER_PORT}"
  if test "x${USE_DOCKER}" = "xyes" ; then
    DTD_BASE_COMMAND="${DTD_BASE_COMMAND} --user=$MYSQL_USER --password=password"
  else
    DTD_BASE_COMMAND="${DTD_BASE_COMMAND} --user=$MYSQL_USER"
    if test "x$MYSQL_PASSWORD" != "x" ; then
      DTD_BASE_COMMAND="${DTD_BASE_COMMAND} -p'$MYSQL_PASSWORD'"
    fi
  fi
  DROP_DB_COMMAND="${DTD_BASE_COMMAND} -e 'drop database ${SYSBENCH_DB}'"
  MSG="$DROP_DB_COMMAND"
  output_msg
  eval ${DROP_DB_COMMAND}
  if test "x$?" != "x0" ; then
    MSG="Failed to drop test database ${SYSBENCH_DB}"
    output_msg
    return 0
  fi
  MSG="Dropped database $SYSBENCH_DB succesfully"
  output_msg
  return 0
}

setup_replication()
{
  BASE_COMMAND="${MYSQL_PATH}/bin/mysql -h ${SLAVE_HOST}"
  BASE_COMMAND="${BASE_COMMAND} --protocol=tcp"
  BASE_COMMAND="$BASE_COMMAND --port=${SLAVE_PORT}"
  if test "x${USE_DOCKER}" = "xyes" ; then
    BASE_COMMAND="$BASE_COMMAND --user=$MYSQL_USER --password=password"
  else
    BASE_COMMAND="$BASE_COMMAND --user=$MYSQL_USER"
    if test "x$MYSQL_PASSWORD" != "x" ; then
      BASE_COMMAND="${BASE_COMMAND} -p'$MYSQL_PASSWORD'"
    fi
  fi
  CM_COMMAND="${BASE_COMMAND} -e 'CHANGE MASTER TO "
  CM_COMMAND="${CM_COMMAND} MASTER_HOST=\"${SERVER_HOST}\","
  CM_COMMAND="${CM_COMMAND} MASTER_PORT=${SERVER_PORT},"
  CM_COMMAND="${CM_COMMAND} MASTER_USER=\"${MYSQL_USER}\","
  CM_COMMAND="${CM_COMMAND} MASTER_PASSWORD=\"${MYSQL_PASSWORD}\","
  CM_COMMAND="${CM_COMMAND} MASTER_LOG_FILE=\"${BINLOG}_1.000001\","
  CM_COMMAND="${CM_COMMAND} MASTER_LOG_POS=4"
  CM_COMMAND="${CM_COMMAND} '"
  SS_COMMAND="${BASE_COMMAND} -e 'START SLAVE'"
  for ((i_sr = 0; i_sr < NUM_CHANGE_MASTER_ATTEMPTS ; i_sr+=1 ))
  do
    MSG="Setting up replication from slave to master server"
    output_msg
    if test "x${VERBOSE_FLAG}" != "x" ; then
      MSG="Executing ${CM_COMMAND}"
      output_msg
    fi
    eval ${CM_COMMAND}
    if test "x$?" = "x0" ; then
      MSG="Successfully setup replication in slave server"
      output_msg
      MSG="Start slave"
      output_msg
      eval ${SS_COMMAND}
      if test "x$?" = "x0" ; then
        MSG="Successfully started slave"
        output_msg
        return 0
      else
        MSG="Failed to start slave"
        output_msg
        exit_func
      fi
    fi
    ${SLEEP} ${BETWEEN_CHANGE_MASTER_TEST}
  done
  MSG="Failed to setup replication in slave server"
  output_msg
  exit_func
}

run_oltp_complex()
{
  SYSBENCH_COMMON="--num-threads=$THREADS"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --test=oltp"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --report-interval=3"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --seed-rng=1103515245"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-user=$MYSQL_USER"
  if test "x${USE_DOCKER}" = "xyes" ; then
    SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-password=password"
  else
    if test "x$MYSQL_PASSWORD" != "x" ; then
      SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-password='$MYSQL_PASSWORD'"
    fi
  fi
  SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-db=${SYSBENCH_DB}"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-host=${SERVER_HOST}"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-port=${SERVER_PORT}"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-table-engine=${ENGINE}"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-engine-trx=${TRX_ENGINE}"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --oltp-dist-type=${SB_DIST_TYPE}"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --oltp-table-size=${SYSBENCH_ROWS}"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --oltp-auto-inc=${SB_USE_AUTO_INC}"
  SYSBENCH_COMMON="$SYSBENCH_COMMON --verbosity=${SB_VERBOSITY}"
  if test "x${SB_PARTITION_BALANCE}" != "x" ; then
    if test "x${SB_PARTITION_BALANCE}" = "xFOR_RA_BY_NODE" ; then
      SB_PARTITION_BALANCE="NDB_TABLE=PARTITION_BALANCE=FOR_RA_BY_NODE"
    elif test "x${SB_PARTITION_BALANCE}" = "xFOR_RP_BY_NODE" ; then
      SB_PARTITION_BALANCE="NDB_TABLE=PARTITION_BALANCE=FOR_RP_BY_NODE"
    elif test "x${SB_PARTITION_BALANCE}" = "xFOR_RA_BY_LDM" ; then
      SB_PARTITION_BALANCE="NDB_TABLE=PARTITION_BALANCE=FOR_RA_BY_LDM"
    elif test "x${SB_PARTITION_BALANCE}" = "xFOR_RP_BY_LDM" ; then
      SB_PARTITION_BALANCE="NDB_TABLE=PARTITION_BALANCE=FOR_RP_BY_LDM"
    else
      ${ECHO} "Not supported SB_PARTITION_BALANCE = ${SB_PARTITION_BALANCE}, ignoring, only FOR_RA_BY_NODE, FOR_RP_BY_NODE, FOR_RA_BY_LDM and FOR_RP_BY_LDM is supported"
      SB_PARTITION_BALANCE=
    fi
  fi
  if test "x${SB_PARTITION_BALANCE}" != "x" ; then
    SYSBENCH_COMMON="$SYSBENCH_COMMON --oltp-table-comment-string=${SB_PARTITION_BALANCE}"
  fi
  if test "x${SB_MAX_REQUESTS}" = "x0" ; then
    SYSBENCH_COMMON="$SYSBENCH_COMMON --max-requests=0"
    SYSBENCH_COMMON="$SYSBENCH_COMMON --max-time=${MAX_TIME}"
  else
    SYSBENCH_COMMON="$SYSBENCH_COMMON --max-requests=${SB_MAX_REQUESTS}"
  fi
  if test "x${SERVER_HOST}" = "xlocalhost" || \
     test "x${SERVER_HOST}" = "x127.0.0.1" ; then
    if test "x$SKIP_SOCKET" != "xyes" ; then
      SYSBENCH_COMMON="$SYSBENCH_COMMON --mysql-socket=${MYSQL_SOCKET}"
    fi
  fi

  SYSBENCH_COMMAND="${BENCH_TASKSET} ${SYSBENCH}"
  SYSBENCH_COMMAND="${SYSBENCH_COMMAND} ${SYSBENCH_COMMON}"

  if test "x$TEST" = "xoltp_rw" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-test-mode=complex"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-read-only=off"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-use-filter=$SB_USE_FILTER"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-point-selects=$SB_POINT_SELECTS"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-range-size=$SB_RANGE_SIZE"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-simple-ranges=$SB_SIMPLE_RANGES"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-sum-ranges=$SB_SUM_RANGES"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-order-ranges=$SB_ORDER_RANGES"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-distinct-ranges=$SB_DISTINCT_RANGES"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-use-in-statement=$SB_USE_IN_STATEMENT"
  elif test "x${TEST}" = "xoltp_rw_write_intensive" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-test-mode=complex"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-read-only=off"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-index-updates=10"
  elif test "x${TEST}" = "xoltp_ro_ps" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-test-mode=complex"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-read-only=on"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-skip-trx=on"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-point-selects=1"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-simple-ranges=0"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-sum-ranges=0"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-order-ranges=0"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-distinct-ranges=0"
  elif test "x${TEST}" = "xoltp_ro" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-test-mode=complex"
    if test "x$SB_USE_TRX" = "xyes" ; then
      SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-skip-trx=off"
    else
      SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-skip-trx=on"
    fi
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-read-only=on"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-use-filter=$SB_USE_FILTER"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-point-selects=$SB_POINT_SELECTS"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-range-size=$SB_RANGE_SIZE"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-simple-ranges=$SB_SIMPLE_RANGES"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-sum-ranges=$SB_SUM_RANGES"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-order-ranges=$SB_ORDER_RANGES"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-distinct-ranges=$SB_DISTINCT_RANGES"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-use-in-statement=$SB_USE_IN_STATEMENT"
  elif test "x${TEST}" = "xoltp_rw_less_read" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-test-mode=complex"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-read-only=off"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-point-selects=1"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-range-size=5"
  elif test "x${TEST}" = "xoltp_complex_write" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-test-mode=complex"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-point-selects=0"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-simple-ranges=0"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-sum-ranges=0"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-order-ranges=0"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-distinct-ranges=0"
  elif test "x${TEST}" = "xoltp_nontrx" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-test-mode=nontrx"
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-nontrx-mode=${SB_NONTRX_MODE}"
  else
    MSG="No test ${TEST}"
    output_msg
    exit_func
  fi
  if test "x${SB_USE_MYSQL_HANDLER}" = "xyes" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-point-select-mysql-handler"
  fi
  if test "x${SB_USE_SECONDARY_INDEX}" = "xyes" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-secondary"
  fi
  if test "x${SB_TX_RATE}" != "x" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --tx-rate=${SB_TX_RATE}"
    if test "x${SB_TX_JITTER}" != "x" ; then
      SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --tx-jitter=${SB_TX_JITTER}"
    fi
  fi
  if test "x${SB_NUM_PARTITIONS}" != "x0" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-num-partitions=${SB_NUM_PARTITIONS}"
  fi
  if test "x${SB_USE_RANGE}" = "xyes" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-use-range=on"
  fi
  if test "x$NDB_USE_DISK_DATA" = "xyes" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-use-ndb-disk-data=on"
  fi
  if test "x${SB_NUM_TABLES}" != "x1" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-num-tables=${SB_NUM_TABLES}"
  fi
  if test "x${SB_AVOID_DEADLOCKS}" = "xyes" ; then
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --oltp-avoid-deadlocks=on"
  fi
  set_ld_library_path
  PRELOAD_COMMAND=
  if test "x$USE_MALLOC_LIB" = "xyes" ; then
    MALLOC_FILE=`basename "${MALLOC_LIB}"`
    MALLOC_PATH=`dirname "${MALLOC_LIB}"`
    PRELOAD_COMMAND="export LD_PRELOAD=${MALLOC_FILE}"
    SET_LD_LIB_PATH_CMD="export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MALLOC_PATH}"
    PRELOAD_COMMAND="${SET_LD_LIB_PATH_CMD} ; ${PRELOAD_COMMAND}"
    SET_DYLD_LIB_PATH_CMD="export DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MALLOC_PATH}"
    PRELOAD_COMMAND="${SET_DYLD_LIB_PATH_CMD} ; ${PRELOAD_COMMAND} ;"
    if test "x$PREPARE_JEMALLOC" != "x" ; then
      PRELOAD_COMMAND="export MALLOC_CONF=lg_dirty_mult:-1 ; $PRELOAD_COMMAND"
    fi
    SYSBENCH_COMMAND="${PRELOAD_COMMAND} ${SYSBENCH_COMMAND}"
  fi
  if test "x${MYSQL_CREATE_OPTIONS}" != "x" ; then
    if test "x${VERBOSE}" = "xyes" ; then 
       MSG="using mysql-create-option for create table ${MYSQL_CREATE_OPTIONS}"
       output_msg
    fi
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} --mysql-create-options=\"${MYSQL_CREATE_OPTIONS}\""
  fi

  if test "x$BENCHMARK_SERVER" != "x" ; then
    SYSBENCH_COMMAND="export LD_LIBRARY_PATH=${ADD_LIB_PATH}; export DYLD_LIBRARY_PATH=${ADD_LIB_PATH} ; $SYSBENCH_COMMAND"
    SYSBENCH_COMMAND="ssh -p $SSH_PORT -n -l $SSH_USER $BENCHMARK_SERVER '$SYSBENCH_COMMAND $COMMAND' >> ${TEST_FILE}"
  else
    SYSBENCH_COMMAND="${SYSBENCH_COMMAND} ${COMMAND} >> ${TEST_FILE}"
  fi

  MSG="Executing ${SYSBENCH_COMMAND}"
  output_msg
  eval ${SYSBENCH_COMMAND}
  if test "x$?" != "x0" ; then
    MSG="Failed sysbench ${TEST} test"
    output_msg
    exit_func
  fi
}

run_sysbench()
{
  TEST_NO="${SYSBENCH_TEST_NUMBER}"
  TEST_FILE="${RESULT_DIR}/${SYSBENCH_TEST}_${BENCHMARK_INSTANCE}_${TEST_NO}.res"
  if test "x${BENCHMARK_STEP}" = "xanalyze" ; then
    $ECHO "Running analyze step for ${SYSBENCH_TEST}"
    analyze_results
  else
    $ECHO "Running ${BENCHMARK_STEP} step in instance ${BENCHMARK_INSTANCE} for ${SYSBENCH_TEST} with ${THREAD_COUNT} threads"
    if test "x${BENCHMARK_STEP}" = "xprepare" ; then
      ${ECHO} "Running $TEST using $THREADS threads" >> ${TEST_FILE}
      create_test_database
    fi
    COMMAND="${BENCHMARK_STEP}"
    THREADS="$THREAD_COUNT"
    TEST="${SYSBENCH_TEST}"
    run_oltp_complex
    if test "x${BENCHMARK_STEP}" = "xcleanup" ; then
      drop_test_database
    fi
  fi
}

initial_test()
{
  MSG="Run initial test that gives consistently low results"
  output_msg
  SAVE_SYSBENCH_ROWS="$SYSBENCH_ROWS"
  SAVE_SB_NUM_TABLES="$SB_NUM_TABLES"
  SYSBENCH_ROWS="500000"
  SB_NUM_TABLES="4"
  TEST="oltp_rw"
  TEST_NO="1"
  TEST_FILE="${RESULT_DIR}/init_${TEST}_${TEST_NO}.res"
  THREADS="16"
  COMMAND="prepare"
  SAVE_MAX_TIME="$MAX_TIME"
  MAX_TIME="60"
  run_oltp_complex
  ${SLEEP} ${BETWEEN_RUNS} 
  COMMAND="run"
  run_oltp_complex
  COMMAND="cleanup"
  run_oltp_complex
  MAX_TIME="$SAVE_MAX_TIME"
  SYSBENCH_ROWS="$SAVE_SYSBENCH_ROWS"
  SB_NUM_TABLES="$SAVE_SB_NUM_TABLES"
  ${SLEEP} ${AFTER_INITIAL_RUN}
}

create_intermediate_result_files()
{
  for ((i_cirf = 0; i_cirf < NUM_TEST_RUNS; i_cirf+= 1 ))
  do
    while read NUM_THREADS
    do
      TEST_FILE_NAME="${RESULT_DIR}/${TEST_NAME}_${BENCHMARK_INSTANCE}_${i_cirf}.res"
      CAT_COMMAND="${CAT} ${TEST_FILE_NAME}"
      ${CAT_COMMAND} | grep "Intermediate results: ${NUM_THREADS} threads" | \
        ${NAWK} 'BEGIN{SEC=0}{SEC=SEC+3;printf "%d %d\n", SEC, $7}' > \
          ${RESULT_DIR}/${TEST_NAME}_intermediate_${i_cirf}_${NUM_THREADS}.res
    done < ${THREAD_FILE_NAME}
  done
}

handle_jpeg_run()
{
  PLOT_CMD_FILE="${RESULT_DIR}/tmp_gnuplot_${BENCHMARK_INSTANCE}.input"
  INTERMED_JPEG_FILE="${RESULT_DIR}/${TEST_NAME}_gnuplot_${BENCHMARK_INSTANCE}_${i_hjr}.jpg"
  FIRST_LOOP="1"
  ${ECHO} "set terminal jpeg large size 1024,768 \\" > $PLOT_CMD_FILE
  ${ECHO} "  xffffff x000000 x404040 \\" >> $PLOT_CMD_FILE
  ${ECHO} "  xff0000 x000000 x0000ff x00ff00 \\" >> $PLOT_CMD_FILE
  ${ECHO} "  x800080 x40aa00 x9500d3 xbbbb44" >> $PLOT_CMD_FILE
  ${ECHO} "set title \"${TEST_DESCRIPTION} test case ${TEST_NAME} test run ${i_hjr}\"" >> $PLOT_CMD_FILE
  ${ECHO} "set grid xtics ytics" >> $PLOT_CMD_FILE
  ${ECHO} "set xlabel \"Seconds\"" >> $PLOT_CMD_FILE
  ${ECHO} "set ylabel \"TPS\"" >> $PLOT_CMD_FILE
  ${ECHO} "set yrange [0:]" >> $PLOT_CMD_FILE
  ${ECHO} "set output \"${INTERMED_JPEG_FILE}\"" >> $PLOT_CMD_FILE
  ${ECHO} "plot \\" >> $PLOT_CMD_FILE
  while read NUM_THREADS
  do
    if test "x${FIRST_LOOP}" = "x0" ; then
      ${ECHO} ", \\" >> $PLOT_CMD_FILE
    fi
    INTERMED_FILE="${RESULT_DIR}/${TEST_NAME}_intermediate_${BENCHMARK_INSTANCE}_${i_hjr}_${NUM_THREADS}.res"
    ${ECHO} "\"${INTERMED_FILE}\" using 1:2 title \\" >> $PLOT_CMD_FILE
    ${ECHO} "\"${NUM_THREADS} threads\" with linespoints \\" >> $PLOT_CMD_FILE
    FIRST_LOOP="0"
  done < ${THREAD_FILE_NAME}
  ${ECHO} "" >> $PLOT_CMD_FILE
  COMMAND="gnuplot $PLOT_CMD_FILE"
  $COMMAND
  #${RM} ${PLOT_CMD_FILE}
}

create_gnuplot_jpeg()
{
  CHECK_GNUPLOT=`which gnuplot`
  if test "x$CHECK_GNUPLOT" != "x" ; then
    for ((i_cgj = 0; i_cgj < NUM_TEST_RUNS; i_cgj+= 1 ))
    do
      i_hjr="$i_cgj"
      handle_jpeg_run
    done
  fi
}

analyze_results()
{
  ${ECHO} "Final results for this test run" > ${TOTAL_FINAL_RESULT_FILE}
  TEST_NAME="${SYSBENCH_TEST}"
  MSG="Analyze test case ${TEST_NAME}"
  output_msg

#
# Create thread number file, can be used by all benchmark instances
# and by all test runs.
#
  AR_BI="0"
  AR_TEST_NUMBER="0"
  TEST_FILE_NAME="${RESULT_DIR}/${TEST_NAME}_${AR_BI}_${AR_TEST_NUMBER}.res"
  ${CAT} ${TEST_FILE_NAME} | ${GREP} 'Number of threads:' | \
    ${NAWK} '{print $4}' > ${THREAD_FILE_NAME}

#Prepare num_threads array
  ((j_ar=0))
  while read NUM_THREADS
  do
    let NUM_THREADS_ARRAY[${j_ar}]="${NUM_THREADS}"
    ((j_ar+=1))
  done < ${THREAD_FILE_NAME}
  NUM_THREAD_RUNS_PER_TEST=${j_ar}

  for ((j_ar = 0; j_ar < NUM_THREAD_RUNS_PER_TEST ; j_ar+= 1 ))
  do
    ((TOT_MEAN[j_ar] = 0))
  done
#
#SYSBENCH_TEST_NUMBER used to carry number of sysbench instances
#for analyze results
#
  for ((bi_ar = 0; bi_ar < SYSBENCH_TEST_NUMBER; bi_ar++))
  do
    FINAL_RESULT_FILE="${DEFAULT_DIR}/final_result_${bi_ar}.txt"
    ${ECHO} "Final results for this test run" > ${FINAL_RESULT_FILE}
    for ((i_ar = 0; i_ar < NUM_TEST_RUNS; i_ar+= 1 ))
    do
      TEST_FILE_NAME="${RESULT_DIR}/${TEST_NAME}_${bi_ar}_${i_ar}.res"
      RESULT_FILE_NAME="${RESULT_NAME}_${bi_ar}_${i_ar}.txt"
      ${CAT} ${TEST_FILE_NAME} | ${GREP} 'transactions:' | ${SED} 's/ (/ /' | \
      ${NAWK} '{print $3}' | sed 's/\..*//' >> ${RESULT_FILE_NAME}
    done
    create_intermediate_result_files
    create_gnuplot_jpeg
    for ((i_ar = 0; i_ar < NUM_TEST_RUNS; i_ar+= 1 ))
    do
      RESULT_FILE_NAME="${RESULT_NAME}_${bi_ar}_${i_ar}.txt"
      ((j_ar=0))
      while read RESULT
      do
        ((index=i_ar*NUM_THREAD_RUNS_PER_TEST+j_ar))
        let RESULT_ARRAY[${index}]="${RESULT}"
        ((j_ar+=1))
      done < ${RESULT_FILE_NAME}
    done
#
# Calculate the mean value and standard deviation per thread count
#
    for ((j_ar = 0; j_ar < NUM_THREAD_RUNS_PER_TEST ; j_ar+= 1 ))
    do
      let TOTAL_TRANS="0"
      for ((i_ar = 0; i_ar < NUM_TEST_RUNS ; i_ar+= 1 ))
      do
        ((index=i_ar*NUM_THREAD_RUNS_PER_TEST+j_ar))
        ((TOTAL_TRANS+=RESULT_ARRAY[index]))
      done
      ((MEAN_TRANS[j_ar]=TOTAL_TRANS/NUM_TEST_RUNS))
      ((TOTAL_SQUARE_TRANS = 0))
      for ((i_ar = 0; i_ar < NUM_TEST_RUNS ; i_ar+= 1 ))
      do
        ((index=i_ar*NUM_THREAD_RUNS_PER_TEST+j_ar))
        ((DIFF=RESULT_ARRAY[index] - MEAN_TRANS[j_ar]))
        ((TOTAL_SQUARE_TRANS+=DIFF*DIFF))
      done
      ((TOTAL_SQUARE_TRANS_MEAN=TOTAL_SQUARE_TRANS/NUM_TEST_RUNS))
      STD=$(${ECHO} "sqrt(${TOTAL_SQUARE_TRANS_MEAN})" | ${BC} -l)
      STD_DEV[j_ar]=`${ECHO} ${STD} | sed 's/\..*//'`
    done
    ${ECHO} "Results for ${TEST_NAME}" >> $FINAL_RESULT_FILE
    for ((j_ar = 0; j_ar < NUM_THREAD_RUNS_PER_TEST ; j_ar+= 1 ))
    do
      ((NUM_THREADS=NUM_THREADS_ARRAY[j_ar]))
      RESULT_LINE="Threads: $NUM_THREADS Results:"
      for ((i_ar = 0; i_ar < NUM_TEST_RUNS ; i_ar+= 1 ))
      do
        ((index=i_ar*NUM_THREAD_RUNS_PER_TEST+j_ar))
        ((RESULT = RESULT_ARRAY[index]))
        RESULT_LINE="$RESULT_LINE $RESULT"
      done
      ${ECHO} "$RESULT_LINE" >> $FINAL_RESULT_FILE
    done
    ${ECHO} "Mean value and standard deviation of results" >> $FINAL_RESULT_FILE
    for ((j_ar = 0; j_ar < NUM_THREAD_RUNS_PER_TEST ; j_ar+= 1 ))
    do
      ((NUM_THREADS=NUM_THREADS_ARRAY[j_ar]))
      ((MEAN=MEAN_TRANS[j_ar]))
      ((TOT_MEAN[j_ar] = TOT_MEAN[j_ar] + MEAN))
      ((NUM_THREADS=NUM_THREADS_ARRAY[j_ar]))
      ((STD=STD_DEV[j_ar]))
      RESULT_LINE="Threads: $NUM_THREADS Mean: $MEAN StdDev: $STD"
      ${ECHO} "${RESULT_LINE}" >> $FINAL_RESULT_FILE
    done
    for ((j_ar = 0; j_ar < NUM_TEST_RUNS ; j_ar+= 1 ))
    do
      RESULT_FILE_NAME="${RESULT_NAME}_${bi_ar}_${j_ar}.txt"
      ${RM} ${RESULT_FILE_NAME}
    done
  done
  for ((j_ar = 0; j_ar < NUM_THREAD_RUNS_PER_TEST ; j_ar+= 1 ))
  do
    ((NUM_THREADS=NUM_THREADS_ARRAY[j_ar]))
    ((MEAN=TOT_MEAN[j_ar]))
    RESULT_LINE="Threads: $NUM_THREADS Mean: $MEAN"
    ${ECHO} "${RESULT_LINE}" >> $TOTAL_FINAL_RESULT_FILE
  done
  ${RM} ${THREAD_FILE_NAME}
}

load_dbt3_database()
{
  echo "load DBT3 database"
  FILL_CMD="${DBT2_PATH}/scripts/mysql_load_dbt3.sh"
  FILL_CMD="${FILL_CMD} --host ${SERVER_HOST}"
  FILL_CMD="${FILL_CMD} --port ${SERVER_PORT}"
  if test "x${SERVER_HOST}" = "xlocalhost" || \
     test "x${SERVER_HOST}" = "x127.0.0.1" ; then
    if test "x$SKIP_SOCKET" != "xyes" ; then
      FILL_CMD="${FILL_CMD} --socket ${MYSQL_SOCKET}"
    fi
  fi
  FILL_CMD="${FILL_CMD} --engine ${STORAGE_ENGINE}"
  FILL_CMD="${FILL_CMD} --database dbt3"
  FILL_CMD="${FILL_CMD} --data-file-path ${DBT3_DATA_PATH}"
  FILL_CMD="${FILL_CMD} --mysql-path ${MYSQL_PATH}/bin"
  if test "x${NDB_USE_DISK_DATA}" = "xyes" ; then
    FILL_CMD="${FILL_CMD} --use-disk-cluster"
  fi
  if test "x${DBT3_PARALLEL_LOAD}" = "xyes" ; then
    FILL_CMD="${FILL_CMD} --parallel-load"
  fi
  if test "x${DBT3_ONLY_CREATE}" = "xyes" ; then
    FILL_CMD="${FILL_CMD} --only-create"
  fi
  if test "x${DBT3_USE_PARTITION_KEY}" = "xyes" ; then
    FILL_CMD="${FILL_CMD} --use-partition-key"
  fi
  if test "x${USE_DOCKER}" = "xyes" ; then
    FILL_CMD="${FILL_CMD} --user $MYSQL_USER --password password"
  else
    FILL_CMD="${FILL_CMD} --user $MYSQL_USER"
    if test "x$MYSQL_PASSWORD" != "x" ; then
      FILL_CMD="${FILL_CMD} -p'$MYSQL_PASSWORD'"
    fi
  fi
  FILL_CMD="${FILL_CMD} --read-backup ${DBT3_READ_BACKUP}"
  if test "x${DBT3_PARTITION_BALANCE}" != "x" ; then
    FILL_CMD="${FILL_CMD} --partition-balance ${DBT3_PARTITION_BALANCE}"
  fi

# Set up paths to MySQL libraries
  if test "x$LD_LIBRARY_PATH" = "x" ; then
    LD_LIBRARY_PATH="$MYSQL_PATH/lib/mysql"
  else
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$MYSQL_PATH/lib/mysql"
  fi
  LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$MYSQL_PATH/lib"
  export LD_LIBRARY_PATH

  if test "x$DYLD_LIBRARY_PATH" = "x" ; then
    DYLD_LIBRARY_PATH="$MYSQL_PATH/lib/mysql"
  else
    DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:$MYSQL_PATH/lib/mysql"
  fi
  DYLD_LIBRARY_PATH="$LD_LIBRARY_PATH:$MYSQL_PATH/lib"
  export DYLD_LIBRARY_PATH

  if test "x${VERBOSE_FLAG}" != "x" ; then
    FILL_CMD="${FILL_CMD} --verbose"
  fi
  MSG="${FILL_CMD}"
  output_msg
  eval ${FILL_CMD}
}

create_dbt2_sp()
{
FILL_CMD="${DBT2_PATH}/scripts/dbt2.sh"
FILL_CMD="${FILL_CMD} --default-directory ${DEFAULT_DIR}"
FILL_CMD="${FILL_CMD} --cluster_id 1"
FILL_CMD="${FILL_CMD} --perform-create-sp"
FILL_CMD="${FILL_CMD} --num-warehouses ${DBT2_WAREHOUSES}"
FILL_CMD="${FILL_CMD} --num-servers ${NUM_MYSQL_SERVERS}"
if test "x${VERBOSE_FLAG}" != "x" ; then
  FILL_CMD="${FILL_CMD} --verbose"
fi
MSG="${FILL_CMD}"
output_msg
eval ${FILL_CMD}
}

load_dbt2_database()
{
FILL_CMD="${DBT2_PATH}/scripts/dbt2.sh"
FILL_CMD="${FILL_CMD} --default-directory ${DEFAULT_DIR}"
FILL_CMD="${FILL_CMD} --cluster_id 1"
FILL_CMD="${FILL_CMD} --perform-all --partition $DBT2_PARTITION_TYPE"
FILL_CMD="${FILL_CMD} --num-warehouses ${DBT2_WAREHOUSES}"
FILL_CMD="${FILL_CMD} --num-servers ${NUM_MYSQL_SERVERS}"
if test "x${VERBOSE_FLAG}" != "x" ; then
  FILL_CMD="${FILL_CMD} --verbose"
fi
MSG="${FILL_CMD}"
output_msg
eval ${FILL_CMD}
}

run_dbt2()
{
RUN_CMD="${DBT2_PATH}/scripts/dbt2.sh"
RUN_CMD="${RUN_CMD} --default-directory ${DEFAULT_DIR}"
RUN_CMD="${RUN_CMD} --run-test 1"
RUN_CMD="${RUN_CMD} --instance 1"
RUN_CMD="${RUN_CMD} --time ${DBT2_TIME}"
RUN_CMD="${RUN_CMD} --num-warehouses ${DBT2_WAREHOUSES}"
RUN_CMD="${RUN_CMD} --cluster_id 1"
if test "x$DBT2_SPREAD" != "x" ; then
  RUN_CMD="${RUN_CMD} ${DBT2_SPREAD}"
fi
if test "x${VERBOSE_FLAG}" != "x" ; then
  RUN_CMD="${RUN_CMD} --verbose"
fi
MSG="${RUN_CMD}"
output_msg
eval ${RUN_CMD}
}

set_pipe_command()
{
  FILE_PIPE="> $FA_FILE_NAME 2>&1"
  COMMAND="$COMMAND $FILE_PIPE"
}

set_file_name()
{
  FA_FILE_NAME="${DEFAULT_DIR}/flex_logs/flex_asynch_out_t${TABLE_NUM}_${TABLE_OP}.txt"
}

exec_command()
{
  MSG="Execute command: $COMMAND on host $LOCAL_API_HOST"
  output_msg
  eval $COMMAND
}

set_ssh_cmd()
{
  NDB_EXPORT_CMD="NDB_CONNECTSTRING=$NDB_CONNECTSTRING;"
  NDB_EXPORT_CMD="$NDB_EXPORT_CMD export NDB_CONNECTSTRING;"
  NDB_EXPORT_CMD="$NDB_EXPORT_CMD LD_LIBRARY_PATH=$LD_LIBRARY_PATH;"
  NDB_EXPORT_CMD="$NDB_EXPORT_CMD DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH;"
  NDB_EXPORT_CMD="$NDB_EXPORT_CMD export LD_LIBRARY_PATH;"
  NDB_EXPORT_CMD="$NDB_EXPORT_CMD export DYLD_LIBRARY_PATH;"
  SSH_CMD="$SSH -p $SSH_PORT -n -l $SSH_USER $LOCAL_API_HOST"
}

execute_flex_asynch_sync()
{
  set_pipe_command
  if test "x$LOCAL_API_HOST" != "x127.0.0.1" && \
     test "x$LOCAL_API_HOST" != "xlocalhost" ; then
    set_ssh_cmd
    COMMAND="$SSH_CMD '$NDB_EXPORT_CMD $COMMAND'"
  else
    COMMAND="$COMMAND"
  fi
  exec_command
}

execute_flex_asynch_async()
{
  set_pipe_command
  if test "x$LOCAL_API_HOST" != "x127.0.0.1" && \
     test "x$LOCAL_API_HOST" != "xlocalhost" ; then
    set_ssh_cmd
    COMMAND="$SSH_CMD '$NDB_EXPORT_CMD $COMMAND'&"
  else
    COMMAND="$COMMAND &"
  fi
  exec_command
}

set_flex_asynch_taskset()
{
  if test "x$BENCH_TASKSET" = "xnumactl" ; then
    if test "$BENCHMARK_BIND" = "x" ; then
      LOC_TASKSET="$BENCH_TASKSET --localalloc"
    elif test "x$BENCHMARK_MEM_POLICY" = "xlocal" ; then
      LOC_TASKSET="$BENCH_TASKSET --localalloc"
    elif test "x$BENCHMARK_MEM_POLICY" = "xinterleave" ; then
      LOC_TASKSET="$BENCH_TASKSET -i"
      LOC_TASKSET="$LOC_TASKSET ${BENCHMARK_BIND_LOC[${INDEX}]}"
    elif test "x$BENCHMARK_MEM_POLICY" = "xmembind" ; then
      LOC_TASKSET="$BENCH_TASKSET -m"
      LOC_TASKSET="$LOC_TASKSET ${BENCHMARK_BIND_LOC[${INDEX}]}"
    else
      LOC_TASKSET="$BENCH_TASKSET --localalloc"
    fi
    if test "x$BENCHMARK_BIND" != "x" ; then
      LOC_TASKSET="$LOC_TASKSET -N"
      LOC_TASKSET="$LOC_TASKSET ${BENCHMARK_BIND_LOC[${INDEX}]}"
    elif test "x$BENCHMARK_CPUS" != "x" ; then
      LOC_TASKSET="$LOC_TASKSET -C"
      LOC_TASKSET="$LOC_TASKSET ${BENCHMARK_CPUS_LOC[${INDEX}]}"
    fi
  else
    LOC_TASKSET="$BENCH_TASKSET ${BENCHMARK_CPUS_LOC[${INDEX}]}"
  fi
  FLEX_ASYNCH_TASKSET="$LOC_TASKSET $FLEX_ASYNCH_BIN"
}

set_flex_asynch_cpus()
{
  if test "x$FLEX_ASYNCH_RECV_CPUS" != "x" ; then
    COMMAND="$COMMAND -receive_cpus ${FLEX_ASYNCH_RECV_CPUS_LOC[${INDEX}]}"
  fi
  if test "x$FLEX_ASYNCH_DEF_CPUS" != "x" ; then
    COMMAND="$COMMAND -definer_cpus ${FLEX_ASYNCH_DEF_CPUS_LOC[${INDEX}]}"
  fi
  if test "x$FLEX_ASYNCH_EXEC_CPUS" != "x" ; then
    COMMAND="$COMMAND -executor_cpus ${FLEX_ASYNCH_EXEC_CPUS_LOC[${INDEX}]}"
  fi
}

run_flexAsynch()
{
  set_ld_library_path
  ${ECHO} "run_flexAsynch"
  export NDB_CONNECTSTRING
  ${MKDIR} -p ${DEFAULT_DIR}/flex_logs

  FLEX_ASYNCH_API_NODES=`${ECHO} ${FLEX_ASYNCH_API_NODES} | ${SED} -e 's!\;! !g'`
  NUM_API_NODES="0"
  for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
  do
    ((NUM_API_NODES+=1))
  done

  if test "x$BENCHMARK_CPUS" != "x" ; then
    BENCHMARK_CPUS_LOC=(`${ECHO} ${BENCHMARK_CPUS} | ${SED} -e 's!\;! !g'`)
    if test "x${#BENCHMARK_CPUS_LOC[*]}" = "x1" ; then
      for ((i_rf = 0; i_rf < NUM_API_NODES; i_rf += 1))
      do
        BENCHMARK_CPUS_LOC[${i_rf}]=${BENCHMARK_CPUS}
      done
    else
      if test "x${#BENCHMARK_CPUS_LOC[*]}" != "x$NUM_API_NODES" ; then
# Ignore BENCHMARK_CPUS if not properly set
        echo "BENCHMARK_CPUS improperly set, ignored"
        BENCHMARK_CPUS=
      fi
    fi
  fi

  if test "x$FLEX_ASYNCH_RECV_CPUS" != "x" ; then
    FLEX_ASYNCH_RECV_CPUS_LOC=(`${ECHO} ${FLEX_ASYNCH_RECV_CPUS} | ${SED} -e 's!\;! !g'`)
    if test "x${#FLEX_ASYNCH_RECV_CPUS_LOC[*]}" = "x1" ; then
      for ((i_rf = 0; i_rf < NUM_API_NODES; i_rf += 1))
      do
        FLEX_ASYNCH_RECV_CPUS_LOC[${i_rf}]=${FLEX_ASYNCH_RECV_CPUS}
      done
    else
      if test "x${#FLEX_ASYNCH_RECV_CPUS_LOC[*]}" != "x$NUM_API_NODES" ; then
# Ignore FLEX_ASYNCH_RECV_CPUS if not properly set
        echo "FLEX_ASYNCH_RECV_CPUS improperly set, ignored"
        FLEX_ASYNCH_RECV_CPUS=
      fi
    fi
  fi

  if test "x$FLEX_ASYNCH_DEF_CPUS" != "x" ; then
    FLEX_ASYNCH_DEF_CPUS_LOC=(`${ECHO} ${FLEX_ASYNCH_DEF_CPUS} | ${SED} -e 's!\;! !g'`)
    if test "x${#FLEX_ASYNCH_DEF_CPUS_LOC[*]}" = "x1" ; then
      for ((i_rf = 0; i_rf < NUM_API_NODES; i_rf += 1))
      do
        FLEX_ASYNCH_DEF_CPUS_LOC[${i_rf}]=${FLEX_ASYNCH_DEF_CPUS}
      done
    else
      if test "x${#FLEX_ASYNCH_DEF_CPUS_LOC[*]}" != "x$NUM_API_NODES" ; then
# Ignore FLEX_ASYNCH_DEF_CPUS if not properly set
        echo "FLEX_ASYNCH_DEF_CPUS improperly set, ignored"
        FLEX_ASYNCH_DEF_CPUS=
      fi
    fi
  fi
  if test "x$FLEX_ASYNCH_EXEC_CPUS" != "x" ; then
    FLEX_ASYNCH_EXEC_CPUS_LOC=(`${ECHO} ${FLEX_ASYNCH_EXEC_CPUS} | ${SED} -e 's!\;! !g'`)
    if test "x${#FLEX_ASYNCH_EXEC_CPUS_LOC[*]}" = "x1" ; then
      for ((i_rf = 0; i_rf < NUM_API_NODES; i_rf += 1))
      do
        FLEX_ASYNCH_EXEC_CPUS_LOC[${i_rf}]=${FLEX_ASYNCH_EXEC_CPUS}
      done
    else
      if test "x${#FLEX_ASYNCH_EXEC_CPUS_LOC[*]}" != "x$NUM_API_NODES" ; then
# Ignore FLEX_ASYNCH_EXEC_CPUS if not properly set
        echo "FLEX_ASYNCH_EXEC_CPUS improperly set, ignored"
        FLEX_ASYNCH_EXEC_CPUS=
      fi
    fi
  fi

  if test "x$BENCHMARK_BIND" != "x" ; then
    BENCHMARK_BIND_LOC=(`${ECHO} ${BENCHMARK_BIND} | ${SED} -e 's!\;! !g'`)
    if test "x${#BENCHMARK_BIND_LOC[*]}" = "x1" ; then
      for ((i_rf = 0; i_rf < NUM_API_NODES; i_rf += 1))
      do
        BENCHMARK_BIND_LOC[${i_rf}]=${BENCHMARK_BIND}
      done
    else
      if test "x${#BENCHMARK_BIND_LOC[*]}" != "x$NUM_API_NODES" ; then
# Ignore BENCHMARK_BIND if not properly set
        echo "BENCHMARK_BIND improperly set, ignored"
        BENCHMARK_BIND=
      fi
    fi
  fi

  FLEX_ASYNCH_BIN="$MYSQL_PATH/bin/flexAsynch"

  FLEX_ASYNCH_META="-a $FLEX_ASYNCH_NUM_ATTRIBUTES"
  FLEX_ASYNCH_META="$FLEX_ASYNCH_META -s $FLEX_ASYNCH_ATTRIBUTE_SIZE"

  FLEX_ASYNCH_OPS="-t $FLEX_ASYNCH_NUM_THREADS"
  FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -p $FLEX_ASYNCH_NUM_PARALLELISM"
  FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -o $FLEX_ASYNCH_EXECUTION_ROUNDS"
  FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -c $FLEX_ASYNCH_NUM_OPS_PER_TRANS"
  if test "x$FLEX_ASYNCH_NEW" != "x" ; then
    FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS $FLEX_ASYNCH_NEW"
    FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -d $FLEX_ASYNCH_DEF_THREADS"
    FLEX_ASYNCH_META="$FLEX_ASYNCH_META -num_tables $FLEX_ASYNCH_NUM_TABLES"
    FLEX_ASYNCH_META="$FLEX_ASYNCH_META -num_indexes $FLEX_ASYNCH_NUM_INDEXES"
  fi
  if test "x$FLEX_ASYNCH_NO_LOGGING" = "xyes" ; then
    FLEX_ASYNCH_META="$FLEX_ASYNCH_META -temp"
  fi
  if test "x$FLEX_ASYNCH_NO_HINT" = "xyes" ; then
    FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -no_hint"
  fi
  if test "x$FLEX_ASYNCH_FORCE_FLAG" = "xforce" ; then
    FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -force"
  elif test "x$FLEX_ASYNCH_FORCE_FLAG" = "xadaptive" ; then
    FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -adaptive"
  elif test "x$FLEX_ASYNCH_FORCE_FLAG" = "xnon_adaptive" ; then
    FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -non_adaptive"
  fi
  if test "x$FLEX_ASYNCH_USE_WRITE" = "xyes" ; then
    FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -write"
  fi
  if test "x$FLEX_ASYNCH_USE_LOCAL" != "x0" ; then
    FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -local $FLEX_ASYNCH_USE_LOCAL"
  fi
  FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -con $FLEX_ASYNCH_NUM_MULTI_CONNECTIONS"
  FLEX_ASYNCH_OPS="$FLEX_ASYNCH_OPS -ndbrecord"

  FLEX_ASYNCH_TIMERS="$FLEX_ASYNCH_TIMERS -execution_time $FLEX_ASYNCH_EXECUTION_TIMER"
  FLEX_ASYNCH_TIMERS="$FLEX_ASYNCH_TIMERS -cooldown_time $FLEX_ASYNCH_COOLDOWN_TIMER"

  TABLE_NUM="0"
  TABLE_OP="init"
  for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
  do
    set_file_name
    ${ECHO} "flexAsynch table $TABLE_NUM" > $FA_FILE_NAME
    ((TABLE_NUM += 1))
  done
  MSG="Create tables"
  output_msg
  TABLE_NUM="0"
  TABLE_OP="create"
  INDEX="0"
  for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
  do
    set_file_name
    set_flex_asynch_taskset
    COMMAND="$FLEX_ASYNCH_TASKSET $FLEX_ASYNCH_META -table $TABLE_NUM -create_table"
    ((TABLE_NUM += 1))
    execute_flex_asynch_sync
    ((INDEX+=1))
  done

  if test "x$FLEX_ASYNCH_END_AFTER_CREATE" = "xyes" ; then
    return
  fi

  MSG="Insert into tables in parallel"
  output_msg
  TABLE_NUM="0"
  TABLE_OP="insert"
  INDEX="0"
  TMP_MAX_INSERTERS="$FLEX_ASYNCH_MAX_INSERTERS"
  for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
  do
    set_file_name
    set_flex_asynch_taskset
    COMMAND="$FLEX_ASYNCH_TASKSET $FLEX_ASYNCH_META"
    set_flex_asynch_cpus
    COMMAND="$COMMAND $FLEX_ASYNCH_OPS -table $TABLE_NUM -insert"
    ((TABLE_NUM += 1))
    execute_flex_asynch_async
    ((INDEX+=1))
    if test "x$INDEX" = "x$TMP_MAX_INSERTERS" ; then
      MSG="Max inserters reached, wait for completion"
      output_msg
      wait
      ((TMP_MAX_INSERTERS+=FLEX_ASYNCH_MAX_INSERTERS))
    fi
    sleep 1
  done
  MSG="Wait for all commands to complete"
  output_msg
  wait

  if test "x$FLEX_ASYNCH_END_AFTER_INSERT" = "xyes" ; then
    return
  fi

  if test "x$FLEX_ASYNCH_NO_UPDATE" != "xyes" ; then
    ((FLEX_ASYNCH_WARMUP_TIMER += NUM_API_NODES))
    MSG="Update tables in parallel"
    output_msg
    TABLE_NUM="0"
    TABLE_OP="update"
    INDEX="0"
    for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
    do
      set_file_name
      set_flex_asynch_taskset
      COMMAND="$FLEX_ASYNCH_TASKSET $FLEX_ASYNCH_META"
      set_flex_asynch_cpus
      COMMAND="$COMMAND $FLEX_ASYNCH_OPS -table $TABLE_NUM -update"
      COMMAND="$COMMAND -warmup_time $FLEX_ASYNCH_WARMUP_TIMER"
      COMMAND="$COMMAND $FLEX_ASYNCH_TIMERS"
      ((TABLE_NUM += 1))
      ((FLEX_ASYNCH_WARMUP_TIMER -= 1))
      execute_flex_asynch_async
      ((INDEX+=1))
      sleep 1
    done
    MSG="Wait for all commands to complete"
    output_msg
    wait
  fi
  if test "x$FLEX_ASYNCH_END_AFTER_UPDATE" = "xyes" ; then
    return
  fi

  if test "x$FLEX_ASYNCH_NO_READ" != "xyes" ; then
#    ((FLEX_ASYNCH_WARMUP_TIMER += NUM_API_NODES))
    MSG="Read tables in parallel"
    output_msg
    TABLE_NUM="0"
    TABLE_OP="read"
    INDEX="0"
    for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
    do
      set_file_name
      set_flex_asynch_taskset
      COMMAND="$FLEX_ASYNCH_TASKSET $FLEX_ASYNCH_META"
      set_flex_asynch_cpus
      COMMAND="$COMMAND $FLEX_ASYNCH_OPS -table $TABLE_NUM -read"
      COMMAND="$COMMAND -warmup_time $FLEX_ASYNCH_WARMUP_TIMER"
      COMMAND="$COMMAND $FLEX_ASYNCH_TIMERS"
      ((TABLE_NUM += 1))
#      ((FLEX_ASYNCH_WARMUP_TIMER -= 1))
      execute_flex_asynch_async
      ((INDEX+=1))
#      sleep 1
    done
    MSG="Wait for all commands to complete"
    output_msg
    wait
  fi

  if test "x$FLEX_ASYNCH_END_AFTER_READ" = "xyes" ; then
    return
  fi

  if test "x$FLEX_ASYNCH_NO_DELETE" != "xyes" ; then
    MSG="Delete from tables in parallel"
    output_msg
    TABLE_NUM="0"
    TABLE_OP="delete"
    INDEX="0"
    for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
    do
      set_file_name
      set_flex_asynch_taskset
      COMMAND="$FLEX_ASYNCH_TASKSET $FLEX_ASYNCH_META"
      set_flex_asynch_cpus
      COMMAND="$COMMAND $FLEX_ASYNCH_OPS -table $TABLE_NUM -delete"
      ((TABLE_NUM += 1))
      execute_flex_asynch_async
      ((INDEX+=1))
      sleep 1
    done
    MSG="Wait for all commands to complete"
    output_msg
    wait
  fi
  if test "x$FLEX_ASYNCH_END_AFTER_DELETE" = "xyes" ; then
    return
  fi

  if test "x$FLEX_ASYNCH_NO_DROP" != "xyes" ; then
    MSG="Drop tables"
    output_msg
    TABLE_NUM="0"
    TABLE_OP="drop"
    INDEX="0"
    for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
    do
      set_file_name
      set_flex_asynch_taskset
      COMMAND="$FLEX_ASYNCH_TASKSET $FLEX_ASYNCH_META -table $TABLE_NUM -drop_table"
      ((TABLE_NUM += 1))
      execute_flex_asynch_sync
      ((INDEX+=1))
    done
  fi

  FINAL_RESULT_FILE="$DEFAULT_DIR/final_result.txt"
  INSERT_RESULT_FILE="${DEFAULT_DIR}/flex_logs/tmp_insert_result"
  DELETE_RESULT_FILE="${DEFAULT_DIR}/flex_logs/tmp_delete_result"
  READ_RESULT_FILE="${DEFAULT_DIR}/flex_logs/tmp_read_result"
  UPDATE_RESULT_FILE="${DEFAULT_DIR}/flex_logs/tmp_update_result"

  TABLE_NUM="0"
  ${RM} ${INSERT_RESULT_FILE}
  ${RM} ${DELETE_RESULT_FILE}
  ${RM} ${READ_RESULT_FILE}
  ${RM} ${UPDATE_RESULT_FILE}
  ${RM} ${FINAL_RESULT_FILE}

  for LOCAL_API_HOST in $FLEX_ASYNCH_API_NODES
  do
    TABLE_OP="insert"
    set_file_name
    ${CAT} ${FA_FILE_NAME} | ${GREP} 'Total transactions' | \
    ${NAWK} '{ print $5 }' >> ${INSERT_RESULT_FILE}
    if test "x$FLEX_ASYNCH_NO_DELETE" != "xyes" ; then
      TABLE_OP="delete"
      set_file_name
      ${CAT} ${FA_FILE_NAME} | ${GREP} 'Total transactions' | \
      ${NAWK} '{ print $5 }' >> ${DELETE_RESULT_FILE}
    fi
    if test "x$FLEX_ASYNCH_NO_READ" != "xyes" ; then
      TABLE_OP="read"
      set_file_name
      ${CAT} ${FA_FILE_NAME} | ${GREP} 'Total transactions' | \
      ${NAWK} '{ print $5 }' >> ${READ_RESULT_FILE}
    fi
    if test "x$FLEX_ASYNCH_NO_UPDATE" != "xyes" ; then
      TABLE_OP="update"
      set_file_name
      ${CAT} ${FA_FILE_NAME} | ${GREP} 'Total transactions' | \
      ${NAWK} '{ print $5 }' >> ${UPDATE_RESULT_FILE}
    fi
    ((TABLE_NUM += 1))
  done
  TOTAL_INSERTS="0"
  TOTAL_DELETES="0"
  TOTAL_READS="0"
  TOTAL_UPDATES="0"

  while read NUM_INSERTS
  do
    ((TOTAL_INSERTS += NUM_INSERTS))
  done < ${INSERT_RESULT_FILE}
  ${ECHO} "Total inserts per second are: $TOTAL_INSERTS" > $FINAL_RESULT_FILE

  if test "x$FLEX_ASYNCH_NO_DELETE" != "xyes" ; then
    while read NUM_DELETES
    do
      ((TOTAL_DELETES += NUM_DELETES))
    done < ${DELETE_RESULT_FILE}
    ${ECHO} "Total deletes per second are: $TOTAL_DELETES" >> $FINAL_RESULT_FILE
  fi

  if test "x$FLEX_ASYNCH_NO_READ" != "xyes" ; then
    while read NUM_READS
    do
      ((TOTAL_READS += NUM_READS))
    done < ${READ_RESULT_FILE}
    ${ECHO} "Total reads per second are: $TOTAL_READS" >> $FINAL_RESULT_FILE
  fi 

  if test "x$FLEX_ASYNCH_NO_UPDATE" != "xyes" ; then
    while read NUM_UPDATES
    do
      ((TOTAL_UPDATES += NUM_UPDATES))
    done < ${UPDATE_RESULT_FILE}
    ${ECHO} "Total updates per second are: $TOTAL_UPDATES" >> $FINAL_RESULT_FILE
  fi

  ${CAT} ${FINAL_RESULT_FILE}

  ${RM} ${INSERT_RESULT_FILE}
  ${RM} ${DELETE_RESULT_FILE}
  ${RM} ${READ_RESULT_FILE}
  ${RM} ${UPDATE_RESULT_FILE}
}

CAT=cat
GREP=
SED=sed
BC=bc
ECHO=echo
RM=rm
SLEEP=sleep
MKDIR=mkdir
PWD=pwd
SSH=ssh
SSH_PORT="22"
SSH_USER=$USER
SERVER_TYPE="MySQL"
SERVER_TYPE_NAME="mysqld"
LOG_FILE=

#Sleep parameters for various sections
BETWEEN_RUNS="5"             # Time between runs to avoid checkpoints
AFTER_INITIAL_RUN="30"        # Time after initial run
AFTER_SERVER_START="90"       # Wait for Server to start
BETWEEN_CREATE_DB_TEST="10"   # Time between each attempt to create DB
NUM_CREATE_DB_ATTEMPTS="18"   # Max number of attempts before giving up
AFTER_SERVER_STOP="5"        # Time to wait after stopping Server

#Parameters normally configured
NUM_TEST_RUNS="1" # Number of loops to run tests in
MAX_TIME="60"     # Time to run each test
ENGINE="ndb"   # Engine used to run test

#Which tests should we run, default is to run all of them
RUN_RW="yes"             # Run Sysbench RW test or not
RUN_RW_WRITE_INT="no"    # Run Write Intensive RW test or not
RUN_RW_RW_LESS_READ="no" # Run RW test with less read or not
RUN_RO="no"              # Run Sysbench RO test
RUN_WRITE="no"           # Run Sysbench Write only test

#Parameters specifying where MySQL Server is hosted
SERVER_HOST=           # Hostname of MySQL Server
SERVER_PORT=           # Port of MySQL Server to connect to

#Set both taskset and CPUS to blank if no binding to CPU is wanted
TASKSET=                      # Program to bind program to CPU's
CPUS=                         # CPU's to bind to

#Default configuration file
DEFAULT_DIR="${HOME}/.build"

#Paths to MySQL, DBT2 and Sysbench installation
MYSQL_PATH=
DBT2_PATH=
SYSBENCH=

#Variables initialised
VERBOSE=
VERBOSE_FLAG=
ONLY_MYSQL="no"
SKIP_LOAD_DBT2=
SKIP_RUN="no"
SKIP_START="no"
SKIP_STOP=
INITIAL_FLAG="--initial"
SYSBENCH_DB="sbtest"
EXIT_FLAG=
MALLOC_LIB="/usr/lib64/libtcmalloc_minimal.so.0"
USE_MALLOC_LIB="no"
MYSQL_CREATE_OPTIONS=
PRELOAD_COMMAND=
MSG=
ONLY_INITIAL=
BENCHMARK_HOST=

grep --version 2> /dev/null 1> /dev/null
if test "x$?" = "x0" ; then
  GREP=grep
else
  GREP=/usr/gnu/bin/grep
  if ! test -d $GREP ; then
    GREP=ggrep
  fi
  $GREP --version 2> /dev/null 1> /dev/null
  if test "x$?" != "x0" ; then
    MSG="Didn't find a proper grep binary"
    output_msg
    exit 1
  fi
fi

NAWK="nawk"
which nawk 2> /dev/null 1> /dev/null
if test "x$?" != "x0" ; then
  NAWK="awk"
fi

if test $# -gt 1 ; then
  case $1 in
    --default-directory )
      shift
      DEFAULT_DIR="$1"
      shift
      ;;
    *)
  esac
fi
if test $# -gt 1 ; then
  case $1 in
    --benchmark )
      shift
      BENCHMARK="$1"
      shift
      ;;
    *)
  esac
fi

#
# Set up configuration files references to the default directory used
#
DEFAULT_FILE="${DEFAULT_DIR}/iclaustron.conf"
if test -f "$DEFAULT_FILE" ; then
  . ${DEFAULT_FILE}
fi
if test "x${BENCHMARK}" = "xsysbench" ; then
  DEFAULT_FILE="${DEFAULT_DIR}/sysbench.conf"
else
  DEFAULT_FILE="${DEFAULT_DIR}/dbt2.conf"
fi
#Read configuration parameters
if test -f "$DEFAULT_FILE" ; then
  . ${DEFAULT_FILE}
fi

BENCHMARK_INSTANCE="0"
BENCHMARK_STEP=
THREAD_COUNT="0"
SYSBENCH_TEST="oltp_rw"
SYSBENCH_TEST_NUMBER="0"

while test $# -gt 0
do
  case $1 in
  --database )
    shift
    SYSBENCH_DB="$1"
    ;;
  --server-host )
    shift
    SERVER_HOST="$1"
    ;;
  --server-port )
    shift
    SERVER_PORT="$1"
    ;;
  --skip-load-dbt2 )
    SKIP_LOAD_DBT2="yes"
    ;;
  --skip-run )
    SKIP_RUN="yes"
    ;;
  --only-mysql )
    ONLY_MYSQL="yes"
    ;;
  --skip-start )
    SKIP_START="yes"
    ;;
  --skip-initial )
    INITIAL_FLAG=
    ;;
  --skip-stop )
    SKIP_STOP="yes"
    ;;
  --only-initial )
    ONLY_INITIAL="yes"
    ;;
  --verbose )
    VERBOSE="yes"
    VERBOSE_FLAG="--verbose"
    ;;
  --benchmark-instance )
    shift
    BENCHMARK_INSTANCE="$1"
    ;;
  --benchmark-step )
    shift
    BENCHMARK_STEP="$1"
    ;;
  --thread-count )
    shift
    THREAD_COUNT="$1"
    ;;
  --sysbench-test )
    shift
    SYSBENCH_TEST="$1"
    ;;
  --sysbench-test-number )
    shift
    SYSBENCH_TEST_NUMBER="$1"
    ;;
  --benchmark-server )
    shift
    BENCHMARK_SERVER="$1"
    ;;
  *)
    MSG="No such option $1"
    output_msg
    exit 1
  esac
  shift
done


#
# Set up configuration files references to the default directory used
#
if test "x${BENCHMARK}" = "xsysbench" ; then
  if test "x$SKIP_RUN" != "xyes" ; then
    MSG="Starting Sysbench benchmark using directory ${DEFAULT_DIR}"
    output_msg
  fi
  DEFAULT_FILE="${DEFAULT_DIR}/sysbench.conf"
  RESULT_DIR="${DEFAULT_DIR}/sysbench_results"
  STATS_DIR="${DEFAULT_DIR}/statistics_logs"
  THREAD_FILE_NAME="${RESULT_DIR}/tmp_threads.txt"
  RESULT_NAME="${RESULT_DIR}/tmp_res_file"
  TOTAL_FINAL_RESULT_FILE="${DEFAULT_DIR}/final_result.txt"
elif test "x${BENCHMARK}" != "xdbt3" ; then
  DEFAULT_FILE="${DEFAULT_DIR}/dbt2.conf"
  if test "x$SKIP_RUN" != "xyes" ; then
    if test "x${BENCHMARK}" = "flexAsynch" ; then
      MSG="Starting flexAsynch benchmark using directory ${DEFAULT_DIR}"
    elif test "x${BENCHMARK}" = "xdbt2" ; then
      MSG="Starting DBT2 benchmark using directory ${DEFAULT_DIR}"
    else
      MSG="No $BENCHMARK benchmark exists, exiting"
      output_msg
      exit 1
    fi
    output_msg
  fi
else
  DEFAULT_FILE="${DEFAULT_DIR}/dbt2.conf"
  MSG="Starting DBT3 benchmark using directory ${DEFAULT_DIR}"
  output_msg
fi
if test -f "$DEFAULT_FILE" ; then
  MSG="Sourcing defaults from $DEFAULT_FILE"
  output_msg
else
  MSG="No $DEFAULT_FILE found, using standard defaults"
  output_msg
fi

DEFAULT_CLUSTER_CONFIG_FILE="${DEFAULT_DIR}/dis_config_c1.ini"

set_ld_library_path
if test "x$ENGINE" = "xndb" ; then
  if test "x$ONLY_MYSQL" = "xno" ; then
    SERVER_TYPE="All"
    SERVER_TYPE_NAME="all"
  fi
fi
if test "x$SKIP_RUN" != "xyes" ; then
  if test "x${BENCHMARK}" = "xsysbench" ; then
#Current directory is our run directory
#Create result directory for temporary results
#Final results is placed in run directory
    ${MKDIR} -p ${RESULT_DIR}
  fi
fi

if test "x${SKIP_START}" != "xyes" ; then
  start_mysql
  if test "x$SLAVE_HOST" != "x" ; then
    setup_replication
  fi
  if test "x${BENCHMARK}" != "xflexAsynch" ; then
    check_test_database
    create_test_user
    edit_pfs_synch
  fi
fi

if test "x${BENCHMARK}" = "xsysbench" ; then
  if test "x$ONLY_INITIAL" = "xyes" ; then
    initial_test
  elif test "x${SKIP_RUN}" != "xyes" ; then
    run_sysbench
  fi
else
  if test "x${BENCHMARK}" = "xflexAsynch" ; then
    run_flexAsynch
  elif test "x${BENCHMARK}" = "xdbt2" ; then
    if test "x${SKIP_RUN}" != "xyes" ; then
      if test "x${SKIP_LOAD_DBT2}" != "xyes" ; then
        create_dbt2_sp
        load_dbt2_database
      fi
      run_dbt2
    fi
  else
    if test "x${SKIP_RUN}" != "xyes" ; then
      load_dbt3_database
      exit 0
    fi
  fi
fi

if test "x$NDB_RESTART_TEST" = "xyes" ; then
  restart_ndb_node
fi

if test "x${SKIP_STOP}" != "xyes" ; then
  if test "x${WAIT_STOP}" != "x" ; then
    sleep ${WAIT_STOP}
  fi
  stop_mysql
fi
exit 0
