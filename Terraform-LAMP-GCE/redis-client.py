#!/bin/python2

import redis
import sys 
import time

max_retries = 10
HOST = sys.argv[1]
PORT = int(sys.argv[2])

print "host", HOST
print "port", PORT

r = redis.Redis(host= HOST, port = PORT, db=0)
r.ping()
r.ping()

count = 0
backoff = 0


def count_inc():
	return count+1

def try_command(f, *args, **kwargs):

	while True:
		try:
			return f(*args, **kwargs)
			
		except redis.ConnectionError:
            
			count_inc()

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
	target = open("log.txt", 'w')
	for x in xrange(23):
		target.write(str(r.ping()))
		target.write(str(r.echo("String")))
		target.write("\n")
		#print try_command(r.ping)
		time.sleep(1)
	target.close()
		
_main_()	



