#!/bin/bash

replace () {
   file=$1
   var=$2
   new_value=$3
   awk -v var="$var" -v new_val="$new_value" 'BEGIN{FS=OFS="="}match($1, "^\\s*" var "\\s*") {$2=" " new_val}1' "$file"
}

sudo apt-get update
sudo apt-get install build-essential tcl
mkdir /tmp/redis
cd /tmp/redis
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-stable
make
make test
make install
cd /tmp/redis


SCRIPT=$(readlink -f $0)
SCRIPTPATH="/tmp/redis/redis-stable"

REDIS_PORT=6379
REDIS_CONFIG_FILE="/etc/redis/$REDIS_PORT.conf"
REDIS_DATA_DIR="/var/lib/redis/$REDIS_PORT"
REDIS_LOG_FILE="/var/log/redis_$REDIS_PORT.log"
REDIS_EXECUTABLE=`command -v redis-server`
CLI_EXEC=`command -v redis-cli`
INIT_SCRIPT_DEST="/etc/init.d/redis_${REDIS_PORT}"

mkdir -p `dirname "$REDIS_CONFIG_FILE"`
mkdir -p `dirname "$REDIS_LOG_FILE"`
mkdir -p "$REDIS_DATA_DIR"

cd /tmp/redis/redis-stable
cp redis.conf ${REDIS_CONFIG_FILE}
replace ${REDIS_CONFIG_FILE} "port" ${REDIS_PORT}

cd /tmp/redis/redis-stable/utils
cp redis_init_script ${INIT_SCRIPT_DEST}
replace ${INIT_SCRIPT_DEST} "REDISPORT" ${REDIS_PORT}

