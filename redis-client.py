#!/bin/python2

import redis
import sys 
import time

max_retries = 10
count = 0
HOST = sys.argv[1]
PORT = sys.argv[2]

r = redis.Redis(host= HOST, port = PORT, db=0)

def try_command(f, *args, **kwargs):
    while True:
        try:
            return f(*args, **kwargs)
        except redis.ConnectionError:
            count += 1

            # re-raise the ConnectionError if we've exceeded max_retries
            if count > max_retries:
                raise         
            backoff = count * 5 
            
            print('Retrying in {} seconds'.format(backoff))
            time.sleep(10)
            r = redis.Redis(host=HOST, port = PORT, db=0)

# this will retry until a result is returned
# or will re-raise the final ConnectionError
def _main_():
	try_command(ping)
	try_command(r.hset, field, keys, 1)



