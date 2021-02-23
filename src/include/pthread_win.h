/*
   Copyright (c) 2000, 2012, Oracle and/or its affiliates. All rights reserved.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
*/

#ifndef _PTHREAD_WIN_
#define _PTHREAD_WIN_

#include <process.h>
#include <Windows.h>
#include <errno.h>
#include <stdint.h>

#define PTHREAD_MUTEX_INITIALIZER {0}

typedef unsigned int pthread_t;
typedef CRITICAL_SECTION pthread_mutex_t;

#define pthread_mutex_init(A,B)  (InitializeCriticalSection(A),0)
#define pthread_mutex_lock(A)	 (EnterCriticalSection(A),0)
#define pthread_mutex_unlock(A)  (LeaveCriticalSection(A), 0)
#define pthread_mutex_destroy(A) (DeleteCriticalSection(A), 0)

#define pthread_self() GetCurrentThreadId()
#define pthread_handler_t EXTERNC void * __cdecl

typedef void * (__cdecl *pthread_handler)(void *);
typedef struct { int dummy; } pthread_condattr_t;

typedef struct thread_attr {
    DWORD dwStackSize ;
    DWORD dwCreatingFlag ;
} pthread_attr_t ;

struct  timespec
{
  time_t     tv_sec;
  long long  tv_nsec;
};

/**
  Implementation of Windows condition variables.
  We use native conditions on Vista and later.
*/
typedef union
{
  CONDITION_VARIABLE native_cond;
} pthread_cond_t;

struct thread_start_parameter
{
  pthread_handler func;
  void *arg;
};

int pthread_create(pthread_t *thread_id, const pthread_attr_t *attr,
                   pthread_handler func, void *param);
unsigned int __stdcall pthread_start(void *p);
int pthread_join(pthread_t thread, void **value_ptr);
void pthread_exit(void *a);

int pthread_attr_setstacksize(pthread_attr_t *connect_att,DWORD stack);
int pthread_attr_init(pthread_attr_t *connect_att);
int pthread_attr_destroy(pthread_attr_t *connect_att);

int pthread_cond_destroy(pthread_cond_t *cond);
int pthread_cond_signal(pthread_cond_t *cond);
int pthread_cond_broadcast(pthread_cond_t *cond);
int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr);
int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex);
int pthread_cond_timedwait(pthread_cond_t *cond, pthread_mutex_t *mutex,
                           struct timespec *abstime);

int gettimeofday(struct timeval *tp, void *tzp);

#endif