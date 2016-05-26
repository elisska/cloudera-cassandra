#!/bin/bash
CMD=$1

_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$child" 2>/dev/null
}

trap _term SIGTERM

RETVAL=0
PROG="Cassandra"
NAME="cassandra"

if [ -z $CASSANDRA_HOME ] 
	then
	CASSANDRA_HOME=/opt/cloudera/parcels/DATASTAX_CASSANDRA
fi

export CASSANDRA_CONF=$CONF_DIR

adjust_config() {

   echo "$PROG conf directory is:" $CASSANDRA_CONF
   echo "Adjusting config files in" $CASSANDRA_CONF
   sed -i 's|=|: |g' $CASSANDRA_CONF/cassandra.yaml

   DATA_DIRS_EXIST=`grep 'data_file_directories:' $CASSANDRA_CONF/cassandra.yaml | wc -l`

   if [ $DATA_DIRS_EXIST -ne 0 ]
      then
       sed -i '/data_file_directories:/d' $CASSANDRA_CONF/cassandra.yaml
       sed -i "\|$CASSANDRA_DATA_DIR|d" $CASSANDRA_CONF/cassandra.yaml
       cat >>$CASSANDRA_CONF/cassandra.yaml <<EOL
data_file_directories:
  - $CASSANDRA_DATA_DIR
EOL
   fi

   if [ -f $CASSANDRA_CONF/$SEEDS_FILE ]
      then
      SEEDS=`cat $CASSANDRA_CONF/$SEEDS_FILE | cut -d':' -f1 | xargs | sed -e 's/ /,/g'`
   fi

   SEED_EXISTS=`grep seed_provider $CASSANDRA_CONF/cassandra.yaml | wc -l`

   if [ $SEED_EXISTS -eq 0 ]
     then
      cat >>$CASSANDRA_CONF/cassandra.yaml <<EOL
seed_provider:
  - class_name: ${SEED_PROVIDER}
    parameters:
         - seeds: "${SEEDS}"
EOL
  fi
}

case $CMD in
  (deploy)
  
   adjust_config

   cp $CASSANDRA_CONF/cassandra.yaml $CASSANDRA_CONF/$CLIENT_CONFIG_DIR/

  ;;
  (start)
   
   adjust_config

   echo "$PROG user is:" $CASSANDRA_USER
   echo "$PROG log directory is:" $CASSANDRA_LOG_DIR
   echo "$PROG data directory is:" $CASSANDRA_DATA_DIR
   echo "$PROG commitlog directory is:" $CASSANDRA_COMMITLOG_DIR
   echo "$PROG saved caches directory is:" $CASSANDRA_SAVED_CACHES_DIR
   echo "Ensuring that $PROG directories are in place"
   mkdir -p $CASSANDRA_LOG_DIR
   mkdir -p $CASSANDRA_DATA_DIR
   mkdir -p $CASSANDRA_COMMITLOG_DIR
   mkdir -p $CASSANDRA_SAVED_CACHES_DIR
   chown -R $CASSANDRA_USER:$CASSANDRA_USER $CASSANDRA_LOG_DIR
   chown -R $CASSANDRA_USER:$CASSANDRA_USER $CASSANDRA_DATA_DIR
   chown -R $CASSANDRA_USER:$CASSANDRA_USER $CASSANDRA_COMMITLOG_DIR
   chown -R $CASSANDRA_USER:$CASSANDRA_USER $CASSANDRA_SAVED_CACHES_DIR

   cd $CASSANDRA_HOME
   rm -rf logs   
   ln -s $CASSANDRA_LOG_DIR logs 

   echo "Starting $PROG on" `hostname`
   $CASSANDRA_HOME/bin/cassandra -f &
   child=$! 
   wait "$child"
   ;;
  (stop)

    echo "$PROG run directory is:" $CASSANDRA_RUN_DIR
    echo "Shutting down $PROG on" `hostname`
    
    export CLASSPATH="$CASSANDRA_CONF:$CASSANDRA_HOME/bin/cassandra"
    for jar in "$CASSANDRA_HOME"/lib/*.jar; do export CLASSPATH="$CLASSPATH:$jar"; done
    
    nodetool disablegossip
    nodetool disablethrift
    nodetool drain

    pkill -P `pgrep -f "cassandra_control.sh start"`
    ;;
  (*)
    echo "Don't understand [$CMD]"
    ;;
esac
