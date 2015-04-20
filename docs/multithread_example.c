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

#define NUM_THREADS     20


/* This is our thread function.  It is like main(), but for a thread */
void *longParallelComputation1(void *arg)
{
    char name[64];
    sprintf(name, "myparworker/%d", (int)arg);
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


/* This is our thread function.  It is like main(), but for a thread */
void *longParallelComputation2(void *arg)
{
    char name[64];
    sprintf(name, "threadtype2/%d", (int)arg);
    prctl(PR_SET_NAME,name,0,0,0);
      
    int i = 0;
    while(i<10)         // exit after 10sec
    {
        sleep(1);
        ++i;
    }

    return NULL;
}

int main(void)
{
    pthread_t pth;  // this is our thread identifier
    int i = 0, n = 0;

    /* Create worker threads */
    for (n=0; n < NUM_THREADS/2; n++)
        pthread_create(&pth,NULL,longParallelComputation1, (void*)n);

    while (1)
    {
        usleep(10000 /* 10 ms */);
        ++i;
        
        if ((i%5000)==0)
        {
            // from time to time, spawn other threads:
            for (n=0; n < NUM_THREADS/2; n++)
                pthread_create(&pth,NULL,longParallelComputation2, (void*)n);
        }
    }

    // a program written in the good way, should do pthread_join() on each launched thread!
    
    return 0;
}
