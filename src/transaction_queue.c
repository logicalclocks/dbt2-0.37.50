/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2002 Mark Wong & Open Source Development Lab, Inc.
 *
 * 5 august 2002
 *
 * Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved
 *
 * Windows portability changes
 *
 * 26 jun 2015
 */

#include <common.h>
#include <logging.h>
#include <transaction_queue.h>
#ifdef DEBUG
#ifndef WIN32
#include <unistd.h>
#include <string.h>
#endif

int dump_queue();
#endif /* DEBUG */

sem_t queue_length;
struct transaction_queue_node_t *transaction_head, *transaction_tail;
pthread_mutex_t mutex_queue = PTHREAD_MUTEX_INITIALIZER;
int transaction_id;
int transaction_counter[2][TRANSACTION_MAX] = {
	{ 0, 0, 0, 0, 0 },
	{ 0, 0, 0, 0, 0 }
};
pthread_mutex_t mutex_transaction_counter[2][TRANSACTION_MAX] = {
	{ PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER,
	  PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER,
	  PTHREAD_MUTEX_INITIALIZER },
	{ PTHREAD_MUTEX_INITIALIZER,
	  PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER,
	  PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER }
};

#ifdef DEBUG
int dump_queue()
{
	struct transaction_queue_node_t *node;
	char list[1024] = "";
	char trans[2] = "a";

	node = transaction_head;
	strcat(list, "HEAD");
	while (node != NULL) {
		strcat(list, " <- ");
		trans[0] =
			transaction_short_name[node->client_data.transaction];
		strcat(list, trans);
		node = node->next;
	}
	strcat(list, " <- TAIL");
	LOG_ERROR_MESSAGE(list);

	return OK;
}
#endif /* DEBUG */

/* Dequeue from the head. */
struct transaction_queue_node_t *dequeue_transaction()
{
	struct transaction_queue_node_t *node;

	sem_wait(&queue_length);
	pthread_mutex_lock(&mutex_queue);
	node = transaction_head;
	if (transaction_head == NULL) {
		pthread_mutex_unlock(&mutex_queue);
		return NULL;
	} else if (transaction_head->next == NULL) {
		transaction_head = transaction_tail = NULL;
	} else {
		transaction_head = transaction_head->next;
	}
#ifdef DEBUG
	LOG_ERROR_MESSAGE("dequeue [%d] %c transaction", node->id,
		transaction_short_name[node->client_data.transaction]);
	dump_queue();
#endif /* DEBUG */
	pthread_mutex_unlock(&mutex_queue);

	pthread_mutex_lock(&mutex_transaction_counter[REQ_QUEUED][
		node->client_data.transaction]);
	--transaction_counter[REQ_QUEUED][node->client_data.transaction];
	pthread_mutex_unlock(&mutex_transaction_counter[REQ_QUEUED][
		node->client_data.transaction]);
	pthread_mutex_lock(&mutex_transaction_counter[REQ_EXECUTING][
		node->client_data.transaction]);
	++transaction_counter[REQ_EXECUTING][node->client_data.transaction];
	pthread_mutex_unlock(&mutex_transaction_counter[REQ_EXECUTING][
		node->client_data.transaction]);

	return node;
}

/* Enqueue to the tail. */
int enqueue_transaction(struct transaction_queue_node_t *node)
{
	pthread_mutex_lock(&mutex_transaction_counter[REQ_QUEUED][
		node->client_data.transaction]);
	++transaction_counter[REQ_QUEUED][node->client_data.transaction];
	pthread_mutex_unlock(&mutex_transaction_counter[REQ_QUEUED][
		node->client_data.transaction]);

	pthread_mutex_lock(&mutex_queue);
	node->next = NULL;
	node->id = ++transaction_id;
	if (transaction_tail != NULL) {
		transaction_tail->next = node;
		transaction_tail = node;
	} else {
		transaction_head = transaction_tail = node;
	}
#ifdef DEBUG
	LOG_ERROR_MESSAGE("enqueue [%d] %c transaction", node->id,
		transaction_short_name[node->client_data.transaction]);
	dump_queue();
#endif /* DEBUG */
	sem_post(&queue_length);
	pthread_mutex_unlock(&mutex_queue);

	return OK;
}

int init_transaction_mutex()
{
#ifdef WIN32
  unsigned int i,j;
  for (i = 0; i < 2; i++) 
  {
    for (j = 0; j < TRANSACTION_MAX; j++) 
    {
      pthread_mutex_init(&mutex_transaction_counter[i][j], 0);
    }
  }
  pthread_mutex_init(&mutex_queue, 0);
#endif
  return 0;
}

int init_transaction_queue()
{
        init_transaction_mutex();
	transaction_id = 0;
	transaction_head = transaction_tail = NULL;
	if (sem_init(&queue_length, 0, 0) != 0) {
		LOG_ERROR_MESSAGE("cannot init queue_length");
		return ERROR;
	}

	return OK;
}
