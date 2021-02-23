/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2002 Mark Wong & Open Source Development Lab, Inc.
 *
 * 25 june 2002
 * Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved
 *
 * Ensured that pid files were deleted after completion of running test
 * Fixed spelling error
 * Used unsigned int for counter variables (previously int)
 * 14 mar 2011
 * 
 * Merged in Windows portability changes
 * 16 jun 2015
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#ifndef WIN32
#include <unistd.h>
#endif
#include <string.h>
#include <getopt.h>
#include <errno.h>

#ifdef WIN32
#include <pthread_win.h>
#else
#include <pthread.h>
#endif

#include "common.h"
#include "logging.h"
#include "db_threadpool.h"
#include "listener.h"
#include "_socket.h"
#include "transaction_queue.h"

/* Function Prototypes */
int parse_arguments(int argc, char *argv[]);
int parse_command(char *command);
int create_pid_file();
void delete_pid_file();

/* Global Variables */
char sname[32] = "";
int port = CLIENT_PORT;
int sockfd;
int exiting = 0;
int force_sleep = 0;

#if defined(LIBMYSQL) || defined(ODBC)
char dbt2_user[128] = DB_USER;
char dbt2_pass[128] = DB_PASS;
#endif

#ifdef LIBMYSQL
char dbt2_mysql_host[128];
char dbt2_mysql_port[32];
char dbt2_mysql_socket[256];
#endif /* LIBMYSQL */


int startup();

int main(int argc, char *argv[])
{
        unsigned int count;
        char command[128];

        init_common();

        if (parse_arguments(argc, argv) != OK) {
                printf("usage: %s -d <db_name> -c # [-p #]\n", argv[0]);
                printf("\n");
                printf("-f\n");
                printf("\tset force sleep\n");
                printf("-c #\n");
                printf("\tnumber of database connections\n");
                printf("-p #\n");
                printf("\tport to listen for incoming connections, default %d\n",
                        CLIENT_PORT);
#ifdef ODBC
                printf("-d <db_name>\n");
                printf("\tdatabase connect string\n");
#endif /* ODBC */
#ifdef LIBMYSQL
                printf("-h <hostname of mysql server>\n");
                printf("\tname of host where mysql server is running\n");
                printf("-d <db_name>\n");
                printf("\tdatabase name\n");
                printf("-l #\n");
                printf("\tport number to use for connection to mysql server\n");
                printf("-t <socket>\n");
                printf("\tsocket for connection to mysql server\n");
#endif /* LIBMYSQL */
                printf("-s #\n");
                printf("\tseconds to sleep between openning db connections, default 1 s\n");
#if defined(LIBMYSQL) || defined(ODBC)
                printf("-u <db user>\n");
                printf("-a <db password>\n");
#endif
                return 1;
        }

        /* Check to see if the required flags were used. */
        if (strlen(sname) == 0) {
                printf("-d not used\n");
                return 2;
        }
        if (db_connections == 0) {
                printf("-c not used\n");
                return 3;
        }

#if defined(LIBMYSQL) || defined(ODBC)
        printf("User %s Pass %s\n", dbt2_user, dbt2_pass);
#endif

        /* Ok, let's get started! */
        init_logging();

        printf("opening %d connection(s) to %s...\n", db_connections, sname);
        if (startup() != OK) {
                LOG_ERROR_MESSAGE("startup() failed\n");
                printf("startup() failed\n");
                return 4;
        }
        printf("client has started\n");

        LOG_ERROR_MESSAGE("%d DB worker threads have started", db_connections);
        create_pid_file();

        /* Wait for command line input. */
        do {
                if (force_sleep == 1) {
                        sleep(600);
                        continue;
                }
                scanf("%s", command);
                if (parse_command(command) == EXIT_CODE) {
                        break;
                }
        } while(1);

        printf("closing socket...\n");
        close(sockfd);

#ifdef WIN32
        WSACleanup();
#endif
        printf("waiting for threads to exit... [NOT!]\n");

        /*
         * There are threads waiting on a semaphore that won't exit and I
         * haven't looked into how to get around that so I'm forcing an exit.
         */
        delete_pid_file();
        exit(0);
        do {
                /* Loop until all the DB worker threads have exited. */
                sem_getvalue(&db_worker_count, &count);
                sleep(1);
        } while (count > 0);

        /* Let everyone know we exited ok. */
        printf("exiting...\n");

        return 0;
}

int parse_arguments(int argc, char *argv[])
{
  int c = 0;
  int argvIndex;

  if (argc < 3)
  {
    return ERROR;
  }

  for(argvIndex= 1 ; argvIndex < argc ; ++argvIndex)
  {
    if(!strcmp(argv[argvIndex],"-c"))
      db_connections= (++argvIndex < argc) ? atoi(argv[argvIndex]) : 0;
    else if(!strcmp(argv[argvIndex],"-d"))
      strcpy(sname, (++argvIndex < argc) ? argv[argvIndex] : "");
    else if(!strcmp(argv[argvIndex],"-f"))
      force_sleep= 1;
    else if(!strcmp(argv[argvIndex],"-l"))
    {
#if defined(LIBMYSQL)
      strcpy(dbt2_mysql_port, (++argvIndex < argc) ? argv[argvIndex] : "");
#endif
    }
    else if(!strcmp(argv[argvIndex],"-h"))
    {
#if defined(LIBMYSQL)
      strcpy(dbt2_mysql_host, (++argvIndex < argc) ? argv[argvIndex] : "");
#endif
    }
    else if(!strcmp(argv[argvIndex],"-o"))
      strcpy(output_path, (++argvIndex < argc) ? argv[argvIndex] : "");
    else if(!strcmp(argv[argvIndex],"-p"))
      port= (++argvIndex < argc) ? atoi(argv[argvIndex]) : 0;
    else if(!strcmp(argv[argvIndex],"-s"))
      db_conn_sleep= (++argvIndex < argc) ? atoi(argv[argvIndex]) : 0;
    else if(!strcmp(argv[argvIndex],"-t"))
    {
#if defined(LIBMYSQL)
      strcpy(dbt2_mysql_socket, (++argvIndex < argc) ? argv[argvIndex] : "");
#endif
    }
    else if(!strcmp(argv[argvIndex],"-u"))
    {
#if defined(LIBMYSQL) || defined(ODBC)
      strcpy(dbt2_user, (++argvIndex < argc) ? argv[argvIndex] : "");
#endif
    }
    else if(!strcmp(argv[argvIndex],"-a"))
    {
#if defined(LIBMYSQL) || defined(ODBC)
      strcpy(dbt2_pass, (++argvIndex < argc) ? argv[argvIndex] : "");
#endif
    }
    else
    {
      printf("get params  returned character code 0%o ??\n", c);
    }
  }
  return OK;
}

int parse_command(char *command)
{
        int i, j;
        unsigned int count;
        int stats[2][TRANSACTION_MAX];

        if (strcmp(command, "status") == 0) {
                time_t current_time;
                printf("------\n");
                sem_getvalue(&queue_length, &count);
                printf("transactions waiting = %d\n", count);
                sem_getvalue(&db_worker_count, &count);
                printf("db connections = %d\n", count);
                sem_getvalue(&listener_worker_count, &count);
                printf("terminal connections = %d\n", count);
                for (i = 0; i < 2; i++) {
                        for (j = 0; j < TRANSACTION_MAX; j++) {
                                pthread_mutex_lock(
                                        &mutex_transaction_counter[i][j]);
                                stats[i][j] = transaction_counter[i][j];
                                pthread_mutex_unlock(
                                        &mutex_transaction_counter[i][j]);
                        }
                }
                printf("transaction   queued  executing\n");
                printf("------------  ------  ---------\n");
                for (i = 0; i < TRANSACTION_MAX; i++) {
                        printf("%12s  %6d  %9d\n", transaction_name[i],
                                stats[REQ_QUEUED][i], stats[REQ_EXECUTING][i]);
                }
                printf("------------  ------  ---------\n");
                printf("------  ------------  --------\n");
                printf("Thread  Transactions  Last (s)\n");
                printf("------  ------------  --------\n");
                time(&current_time);
                for (i = 0; i < db_connections; i++) {
                        printf("%6d  %12d  %8d\n", i, worker_count[i],
                                (int) (current_time - last_txn[i]));
                }
                printf("------  ------------  --------\n");
        } else if (strcmp(command, "exit") == 0 ||
                strcmp(command, "quit") == 0) {
                exiting = 1;
                return EXIT_CODE;
        } else if (strcmp(command, "help") == 0 || strcmp(command, "?") == 0) {
                printf("help or ?\n");
                printf("status\n");
                printf("exit or quit\n");
        } else {
                printf("unknown command: %s\n", command);
        }
        return OK;
}

int startup()
{
        pthread_t tid;
        int ret;

#ifdef WIN32
        WSADATA wsaData = {0};
        int result= WSAStartup(MAKEWORD(2, 2), &wsaData);^M
        if (result)
        {
          printf("Socket initialization failed\n");
          return ERROR;
        }
#endif

        sockfd = _listen(port);
        if (sockfd < 1) {
                printf("_listen() failed on port %d\n", port);
                return ERROR;
        }
        if (init_transaction_queue() != OK) {
                LOG_ERROR_MESSAGE("init_transaction_queue() failed");
                return ERROR;
        }
        ret = pthread_create(&tid, NULL, &init_listener, &sockfd);
        if (ret != 0) {
                LOG_ERROR_MESSAGE(
                        "pthread_create() error with init_listener()");
                if (ret == EAGAIN) {
                        LOG_ERROR_MESSAGE("not enough system resources");
                }
                return ERROR;
        }
        printf("listening to port %d\n", port);

        if (db_threadpool_init() != OK) {
                LOG_ERROR_MESSAGE("db_thread_pool_init() failed");
                return ERROR;
        }

        return OK;
}

void delete_pid_file()
{
  char pid_filename[1024]; 
  sprintf(pid_filename, "%s%s", output_path, CLIENT_PID_FILENAME);
  unlink(pid_filename);
}

int create_pid_file()
{
  FILE * fpid;
  char pid_filename[1024]; 

  sprintf(pid_filename, "%s%s", output_path, CLIENT_PID_FILENAME);
 
  fpid = fopen(pid_filename,"w");
  if (!fpid)
  {
    printf("cann't create pid file: %s\n", pid_filename);
    return ERROR;
  }

  fprintf(fpid,"%d", getpid());
  fclose(fpid);

  return OK;
}
