#!/bin/bash
# 
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2002-2008 Open Source Development Labss, Inc.
#               2002-2014 Mark Wong
#               2014      2ndQuadrant, Ltd.
#               2018 Oracle and/or its affiliates. All rights reserved.
#
# mysql_load_dbt3.sh

usage() {

  if [ "$1" != "" ]; then
    echo ''
    echo "error: $1"
  fi

  echo ''
  echo 'usage: mysql_load_dbt3.sh [options]'
  echo 'options:'
  echo 'Mandatory option:'
  echo '----------------'
  echo '       --data-file-path <path to dataset files> (mandatory unless only-create)'
  echo ''
  echo 'Configuration options:'
  echo '----------------------'
  echo '       --mysql-path <path to mysql client binary.'
  echo '         (default /usr/local/mysql/bin)>'
  echo '       --database <database name> (default dbt3)'
  echo '       --socket <database socket> (default /tmp/mysql.sock)'
  echo '       --host <database host> (default localhost)'
  echo '       --port <database port> (default 3306)'
  echo '       --user <database user> (default root)'
  echo '       --password <database password> (default not specified)'
  echo ''
  echo 'MySQL Cluster Disk Data options:'
  echo '--------------------------------'
  echo '       --use-disk-cluster (if this is not set the other options in this'
  echo '         section will be ignored)'
  echo ''
  echo 'Table options:'
  echo '--------------'
  echo '       --engine <storage engine: [INNODB|NDB]. (default INNODB)>'
  echo '       --use-partition-key'
  echo ''
  echo 'Runtime options:'
  echo '----------------'
  echo '       --parallel-load'
  echo '         (only load data, if data-files use different'
  echo '          warehouses parallel load is possible)'
  echo '       --verbose'
  echo '       --help'
  echo ''
  echo 'Example: sh mysql_load_dbt3.sh --data-file-path /tmp/dbt2-w3'
  echo ''
}

validate_parameter()
{
  if [ "$2" != "$3" ]; then
    usage "wrong argument '$2' for parameter '-$1'"
    exit 1
  fi
}


command_exec()
{
  if [ "x${VERBOSE}" != "x" ]; then
    echo "Execute command: $1"
  fi

  eval "$1"

  rc=$?
  if [ ${rc} -ne 0 ]; then
   echo "ERROR: rc=${rc}"
   case ${rc} in
     127) echo "COMMAND NOT FOUND"
          ;;
       *) echo "SCRIPT INTERRUPTED"
          ;;
    esac
    exit 255
  fi
}

analyze_table()
{
  LOC_TABLE="$1"
  command_exec "${MYSQL} ${DB_NAME} -e \"analyze table ${LOC_TABLE}\""
}

analyze_tables()
{
  TABLES="customer lineitem nation orders part partsupp region supplier"
  for TABLE in ${TABLES} ; do
    analyze_table ${TABLE}
  done
}

load_table()
{
  LOC_TABLE="$1"
  command_exec "${MYSQL_IMPORT} ${DB_NAME} ${DB_PATH}/${LOC_TABLE}.tbl"
}

load_tables()
{
  TABLES="customer lineitem nation orders part partsupp region supplier"
  for TABLE in ${TABLES} ; do
    load_table ${TABLE} &
  done
  wait
}

create_tables()
{
CUSTOMER="CREATE TABLE customer (
        c_custkey INTEGER,
        c_name VARCHAR(25),
        c_address VARCHAR(40),
        c_nationkey INTEGER,
        c_phone CHAR(15),
        c_acctbal DECIMAL(10,2),
        c_mktsegment CHAR(10),
        c_comment VARCHAR(117),
        PRIMARY KEY (c_custkey),
        KEY (c_nationkey)
)"

LINEITEM="CREATE TABLE lineitem (
        l_orderkey INTEGER,
        l_partkey INTEGER,
        l_suppkey INTEGER,
        l_linenumber INTEGER,
        l_quantity DECIMAL(10,2),
        l_extendedprice DECIMAL(10,2),
        l_discount DECIMAL(10,2),
        l_tax DECIMAL(10,2),
        l_returnflag CHAR(1),
        l_linestatus CHAR(1),
        l_shipDATE DATE,
        l_commitDATE DATE,
        l_receiptDATE DATE,
        l_shipinstruct CHAR(25),
        l_shipmode CHAR(10),
        l_comment VARCHAR(44),
        PRIMARY KEY (l_orderkey, l_linenumber),
        KEY (l_shipdate),
        KEY (l_partkey, l_suppkey),
        KEY (l_partkey),
        KEY (l_suppkey),
        KEY (l_receiptdate),
        KEY (l_orderkey),
        KEY (l_orderkey, l_quantity),
        KEY (l_commitdate)
)"

NATION="CREATE TABLE nation (
        n_nationkey INTEGER,
        n_name CHAR(25),
        n_regionkey INTEGER,
        n_comment VARCHAR(152),
        PRIMARY KEY (n_nationkey),
        KEY (n_regionkey)
)"

ORDERS="CREATE TABLE orders (
        o_orderkey INTEGER,
        o_custkey INTEGER,
        o_orderstatus CHAR(1),
        o_totalprice DECIMAL(10,2),
        o_orderDATE DATE,
        o_orderpriority CHAR(15),
        o_clerk CHAR(15),
        o_shippriority INTEGER,
        o_comment VARCHAR(79),
        PRIMARY KEY (o_orderkey),
        KEY (o_orderdate),
        KEY (o_custkey)
)"

PART="CREATE TABLE part (
        p_partkey INTEGER,
        p_name VARCHAR(55),
        p_mfgr CHAR(25),
        p_brand CHAR(10),
        p_type VARCHAR(25),
        p_size INTEGER,
        p_container CHAR(10),
        p_retailprice DECIMAL(10,2),
        p_comment VARCHAR(23),
        PRIMARY KEY (p_partkey)
)"

PARTSUPP="CREATE TABLE partsupp (
        ps_partkey INTEGER,
        ps_suppkey INTEGER,
        ps_availqty INTEGER,
        ps_supplycost DECIMAL(10,2),
        ps_comment VARCHAR(199),
        PRIMARY KEY (ps_partkey, ps_suppkey),
        KEY (ps_partkey),
        KEY (ps_suppkey)
)"

REGION="CREATE TABLE region (
        r_regionkey INTEGER,
        r_name CHAR(25),
        r_comment VARCHAR(152),
        PRIMARY KEY (r_regionkey)
)"

SUPPLIER="CREATE TABLE supplier (
        s_suppkey  INTEGER,
        s_name CHAR(25),
        s_address VARCHAR(40),
        s_nationkey INTEGER,
        s_phone CHAR(15),
        s_acctbal DECIMAL (10,2),
        s_comment VARCHAR(101),
        PRIMARY KEY (s_suppkey),
        KEY (s_nationkey)
)"

if test "x$DB_PARTITION_BALANCE" != "x" ; then
  EXTRA_INFO="COMMENT='NDB_TABLE=PARTITION_BALANCE=${DB_PARTITION_BALANCE},READ_BACKUP=${DB_READ_BACKUP}'"
else
  EXTRA_INFO="COMMENT='NDB_TABLE=READ_BACKUP=${DB_READ_BACKUP}'"
fi
echo "Creating table CUSTOMER in ${DB_ENGINE}"
command_exec "${MYSQL} ${DB_NAME} -e \"${CUSTOMER} ${NDB_DISK_DATA} ENGINE=${DB_ENGINE} ${EXTRA_INFO}\""
echo "Creating table SUPPLIER in ${DB_ENGINE}"
command_exec "${MYSQL} ${DB_NAME} -e \"${SUPPLIER} ${NDB_DISK_DATA} ENGINE=${DB_ENGINE} ${EXTRA_INFO}\""
echo "Creating table PART in ${DB_ENGINE}"
command_exec "${MYSQL} ${DB_NAME} -e \"${PART} ${NDB_DISK_DATA} ENGINE=${DB_ENGINE} ${EXTRA_INFO}\""
echo "Creating table PARTSUPP in ${DB_ENGINE}"
PARTITION_KEY=
if test "x$USE_PARTITION_KEY" = "xyes" ; then
  if test "x$DB_ENGINE" = "xndb" || \
     test "x$DB_ENGINE" = "xNDB" ; then
    PARTITION_KEY="PARTITION BY KEY (ps_partkey)"
  fi
fi
command_exec "${MYSQL} ${DB_NAME} -e \"${PARTSUPP} ${NDB_DISK_DATA} ENGINE=${DB_ENGINE} ${EXTRA_INFO} ${PARTITION_KEY}\""
echo "Creating table REGION in ${DB_ENGINE}"
command_exec "${MYSQL} ${DB_NAME} -e \"${REGION} ${NDB_DISK_DATA} ENGINE=${DB_ENGINE} ${EXTRA_INFO}\""
echo "Creating table NATION in ${DB_ENGINE}"
command_exec "${MYSQL} ${DB_NAME} -e \"${NATION} ${NDB_DISK_DATA} ENGINE=${DB_ENGINE} ${EXTRA_INFO}\""
PARTITION_KEY=
if test "x$USE_PARTITION_KEY" = "xyes" ; then
  if test "x$DB_ENGINE" = "xndb" || \
     test "x$DB_ENGINE" = "xNDB" ; then
    PARTITION_KEY="PARTITION BY KEY (l_orderkey)"
  fi
fi
echo "Creating table LINEITEM in ${DB_ENGINE}"
command_exec "${MYSQL} ${DB_NAME} -e \"${LINEITEM} ${NDB_DISK_DATA} ENGINE=${DB_ENGINE} ${EXTRA_INFO} ${PARTITION_KEY}\""
echo "Creating table ORDERS in ${DB_ENGINE}"
command_exec "${MYSQL} ${DB_NAME} -e \"${ORDERS} ${NDB_DISK_DATA} ENGINE=${DB_ENGINE} ${EXTRA_INFO}\""
}

#DEFAULTs

LOAD_TABLES="1"
VERBOSE=""
DB_PASSWORD=""
DB_PATH=""
DB_NAME="dbt3"
DB_PARALLEL="0"

MYSQL_PATH="/usr/local/mysql/bin"
DB_HOST="localhost"
DB_PORT="3306"
DB_SOCKET=""
DB_USER="root"
DB_ENGINE="INNODB"
NDB_DISK_DATA=""
USE_PARTITION_KEY=
DB_PARTITION_BALANCE=
DB_READ_BACKUP="1"

while test $# -gt 0
do
  case $1 in
   --mysql-path )
     shift
     MYSQL_PATH=$1
     ;;
   --database )
     shift
     DB_NAME=$1
     ;;
   --engine )
     shift
      DB_ENGINE=$1
      ;;
    --read-backup )
      shift
      DB_READ_BACKUP=$1
      ;;
    --partition-balance )
      shift
      DB_PARTITION_BALANCE=$1
      ;;
    --data-file-path )
      shift
      DB_PATH=$1
      ;;
    --use-disk-cluster )
      NDB_DISK_DATA="1"
      ;;
    --host )
      shift
      DB_HOST=$1
      ;;
    --parallel-load )
      DB_PARALLEL="1"
      ;;
    --use-partition-key )
      USE_PARTITION_KEY="yes"
      ;;
    --only-create )
      LOAD_TABLES="0"
      ;;
    --password )
      shift
      DB_PASSWORD=$1
      ;;
    --socket )
      shift
      DB_SOCKET=$1
      ;;
    --port )
      opt=$1
      shift
      DB_PORT=`echo $1 | egrep "^[0-9]+$"`
      validate_parameter $opt $1 ${DB_PORT}
      ;;
    --user )
      shift
      DB_USER=$1
      ;;
    --verbose )
      VERBOSE=1
      ;;
    --help )
      usage
      exit 1
      ;;
    * )
      usage
      exit 1
      ;;
  esac
  shift
done

# Check parameters.
if [ "${LOAD_TABLES}" == "1" ]; then
  if [ "${DB_PATH}" == "" ]; then
    usage "specify path where dataset txt files are located - using --data-file-path #"
    exit 1
  fi

  if [ ! -d "${DB_PATH}" ]; then
    usage "Directory '${DB_PATH}' not exists. Please specify
         correct path to data files using --data-file-path #"
    exit 1
  fi
fi

if [ "${DB_HOST}" != "localhost" -a "${DB_HOST}" != "127.0.0.1" ]; then
  DB_SOCKET=""
fi

if [ "${DB_ENGINE}" != "INNODB" -a "${DB_ENGINE}" != "NDB" ]; then
  usage "${DB_ENGINE}. Please specify correct storage engine [INNODB|NDB]"
  exit 1
fi

if [ ! -f "${MYSQL_PATH}/mysql" ]; then
  usage "MySQL client binary '${MYSQL_PATH}/mysql' not exists.
       Please specify correct one using --mysql-path #"
  exit 1
fi

if [ "${DB_PASSWORD}" != "" ]; then
  MYSQL_ARGS="-p ${DB_PASSWORD}"
fi

MYSQL_ARGS="${MYSQL_ARGS} -h ${DB_HOST} -u ${DB_USER}"
if [ "${DB_SOCKET}" != "" ]; then
  MYSQL_ARGS="${MYSQL_ARGS} --socket=${DB_SOCKET}"
else
  MYSQL_ARGS="${MYSQL_ARGS} --protocol=tcp"
fi
MYSQL_ARGS="${MYSQL_ARGS} --port ${DB_PORT}"
MYSQL="${MYSQL_PATH}/mysql ${MYSQL_ARGS}"
MYSQL_IMPORT="${MYSQL_PATH}/mysqlimport --fields-terminated-by='|'"
MYSQL_IMPORT="${MYSQL_IMPORT} --use-threads=40 ${MYSQL_ARGS}"

echo ""
echo "Loading of DBT3 dataset located in $DB_PATH to database ${DB_NAME}."
echo ""
echo "DB_ENGINE:      ${DB_ENGINE}"
echo "DB_HOST:        ${DB_HOST}"
echo "DB_PORT:        ${DB_PORT}"
echo "DB_USER:        ${DB_USER}"
echo "DB_SOCKET:      ${DB_SOCKET}"
echo "NDB_DISK_DATA:  ${NDB_DISK_DATA}"

echo "DROP/CREATE Database"
command_exec "${MYSQL} -e \"drop database if exists ${DB_NAME}\" "
command_exec "${MYSQL} -e \"create database ${DB_NAME}\" "
if [ "$NDB_DISK_DATA" != "" ]; then
  NDB_DISK_DATA="tablespace ts1 STORAGE DISK"
fi

# Create tables
echo "Create tables"
create_tables

# Load tables
if [ "$LOAD_TABLES" == "1" ]; then
  echo "Load tables"
  load_tables
  analyze_tables
fi
