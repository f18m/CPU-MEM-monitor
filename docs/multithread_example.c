/*
 * multithread example, compile in linux with:
 *       gcc -o multithread -Wall multithread_example.c -lpthread -lm
 */
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <stdint.h>
#include <math.h>
#include <sys/prctl.h>

#define NUM_THREADS		20


/* This is our thread function.  It is like main(), but for a thread */
void *threadFunc(void *arg)
{
	char name[64];
	sprintf(name, "multithread/%d", (int)arg);
	prctl(PR_SET_NAME,name,0,0,0);
	  
	int i = 0;
	while(1)
	{
		usleep(1000);
		if ((i%10000)==0)
		{
            // make the CPU busy for some time, to show in TOP some % of use:
			double tmp;
			uint64_t j;
			for (j=0; j<10000000;j++)
				tmp = pow(tmp, 3);
		}
		++i;
	}

	return NULL;
}

int main(void)
{
	pthread_t pth;	// this is our thread identifier
	int i = 0;

	/* Create worker thread */
	for (i=0; i < NUM_THREADS; i++)
		pthread_create(&pth,NULL,threadFunc, (void*)i);

	/* wait for our thread to finish before continuing */
	pthread_join(pth, NULL /* void ** return value could go here */);

	while (1)
	{
		usleep(1);
		++i;
	}

	return 0;
}
