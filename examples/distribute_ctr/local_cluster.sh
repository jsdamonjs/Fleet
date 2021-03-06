#!/bin/bash
echo "WARNING: This script only for run PaddlePaddle Fluid on one node"

if [ ! -d "./model" ]; then
  mkdir ./model
  echo "Create model folder for store infer model"
fi

if [ ! -d "./log" ]; then
  mkdir ./log
  echo "Create log floder for store running log"
fi

if [ ! -d "./output" ]; then
  mkdir ./output
  echo "Create output floder"
fi

# environment variables for fleet distribute training
export PADDLE_TRAINER_ID=0

export PADDLE_TRAINERS_NUM=2
export CPU_NUM=2
export OUTPUT_PATH="output"

export FLAGS_communicator_thread_pool_size=5
export FLAGS_communicator_fake_rpc=0
export FLAGS_communicator_is_sgd_optimizer=0
export FLAGS_rpc_retry_times=3
export PADDLE_PSERVERS_IP_PORT_LIST="127.0.0.1:36011,127.0.0.1:36012"
export PADDLE_PSERVER_PORT_ARRAY=(36011 36012)

export PADDLE_PSERVER_NUMS=2
export PADDLE_TRAINERS=2

export TRAINING_ROLE=PSERVER
export GLOG_v=0
export GLOG_logtostderr=1
ps -ef|grep python|awk '{print $2}'|xargs kill -9

train_mode=$1

for((i=0;i<$PADDLE_PSERVER_NUMS;i++))
do
    cur_port=${PADDLE_PSERVER_PORT_ARRAY[$i]}
    echo "PADDLE WILL START PSERVER "$cur_port
    export PADDLE_PORT=${cur_port}
    export POD_IP=127.0.0.1
    python -u ${train_mode}_train.py --test=True --cloud=0 &> ./log/pserver.$i.log &
done

export TRAINING_ROLE=TRAINER
export GLOG_v=0
export GLOG_logtostderr=1

for((i=0;i<$PADDLE_TRAINERS;i++))
do
    echo "PADDLE WILL START Trainer "$i
    PADDLE_TRAINER_ID=$i
    python -u ${train_mode}_train.py --test=True --cloud=0 &> ./log/trainer.$i.log &
done

echo "Training log stored in ./log/"