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

#include <pthread_win.h>

#ifdef WIN32

void pthread_exit(void *a)
{
  _endthreadex(0);
}

int pthread_join(pthread_t thread, void **value_ptr)
{
  DWORD  ret;
  HANDLE handle;

  handle= OpenThread(SYNCHRONIZE, FALSE, thread);
  if (!handle)
  {
    errno= EINVAL;
    goto error_return;
  }

  ret= WaitForSingleObject(handle, INFINITE);

  if(ret != WAIT_OBJECT_0)
  {
    errno= EINVAL;
    goto error_return;
  }

  CloseHandle(handle);
  return 0;

error_return:
  if(handle)
    CloseHandle(handle);
  return -1;
}

int pthread_attr_setstacksize(pthread_attr_t *connect_att,DWORD stack)
{
  connect_att->dwStackSize=stack;
  return 0;
}

int pthread_attr_init(pthread_attr_t *connect_att)
{
  connect_att->dwStackSize	= 0;
  connect_att->dwCreatingFlag	= 0;
  return 0;
}

unsigned int __stdcall pthread_start(void *p)
{
  struct thread_start_parameter *par= (struct thread_start_parameter *)p;
  pthread_handler func= par->func;
  void *arg= par->arg;
  free(p);
  (*func)(arg);
  return 0;
}

int pthread_create(pthread_t *thread_id, const pthread_attr_t *attr,
                   pthread_handler func, void *param)
{
  uintptr_t handle;
  struct thread_start_parameter *par;
  unsigned int  stack_size;

  par= (struct thread_start_parameter *)malloc(sizeof(*par));
  if (!par)
   goto error_return;

  par->func= func;
  par->arg= param;
  stack_size= attr?attr->dwStackSize:0;

  handle= _beginthreadex(NULL, stack_size , pthread_start, par, 0, thread_id);
  if (!handle)
    goto error_return;

  /* Do not need thread handle, close it */
  CloseHandle((HANDLE)handle);
  return 0;

error_return:
  return -1;
}

int pthread_attr_destroy(pthread_attr_t *connect_att)
{
  memset(connect_att, 0, sizeof(*connect_att));
  return 0;
}

int pthread_cond_destroy(pthread_cond_t *cond)
{
  return 0;
}

int pthread_cond_signal(pthread_cond_t *cond)
{
  WakeConditionVariable(&cond->native_cond);	  
  return 0;
}

int pthread_cond_broadcast(pthread_cond_t *cond)
{
  WakeConditionVariable(&cond->native_cond);
  return 0;
}

int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr)
{
  InitializeConditionVariable(&cond->native_cond);
  return 0;
}

int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex)
{
  if (!SleepConditionVariableCS(&cond->native_cond, mutex, INFINITE))
    return ETIMEDOUT;
  return 0;  
}

int gettimeofday(struct timeval *tp, void *tzp)
{
  unsigned int ticks;
  ticks= GetTickCount();
  tp->tv_sec= ticks/1000;
  tp->tv_usec= (ticks%1000)*1000;
  return 0;
}

#endif