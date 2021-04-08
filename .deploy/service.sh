#!/bin/bash
#这里可替换为你自己的执行程序，其他代码无需更改
source /etc/profile

#使用说明，用来提示输入参数
usage() {
    echo "Usage: sh service.sh [jar包名称] [start|stop|restart] [port] [env]"
    echo "Usage: sh service.sh code-quality-veryfy-demo start 4000 dev"
    exit 1
}

if [ $# -eq 0 ];
then
    usage
fi
PROJECT_NAME=""
if [ ! $1 ]; then
  echo "待执行的jar名称 IS NULL"
  exit 1
else
    PROJECT_NAME=$1".jar"
fi
EXECUTE_TYPE=""
if [ ! $2 ]; then
  echo "执行类型  [start|stop|restart] IS NULL"
  exit 1
else
    EXECUTE_TYPE=$2
fi
EXECUTE_PORT=""
if [ ! $3 ]  && [ "$EXECUTE_TYPE" != "stop" ]; then
  echo "端口号 IS NULL"
  exit 1
else
    EXECUTE_PORT=$3
fi
EXECUTE_ENV=""
if [ ! $4 ] && [ "$EXECUTE_TYPE" != "stop" ]; then
  echo "执行环境 IS NULL"
  exit 1
else
    EXECUTE_ENV=$4
fi

echo "接收到的参数如下：PROJECT_NAME="$PROJECT_NAME ",EXECUTE_TYPE="$EXECUTE_TYPE ",EXECUTE_PORT="$EXECUTE_PORT "EXECUTE_ENV="$EXECUTE_ENV

echo "2、判断进程是否存在"
CURRENT_THREAD_COUNT=`ps -ef | grep $PROJECT_NAME | grep $PROJECT_NAME | grep -v "grep" |wc -l`

#echo "run command : ps -ef | grep $PROCESS_PID | grep $PROCESS_PID | grep -v "grep" |wc -l"
echo "当前"$PROJECT_NAME"的进程个数为："$CURRENT_THREAD_COUNT
PROJECT_THREAD_PID=`ps -ef |grep "$PROJECT_NAME" |grep "$PROJECT_NAME" |grep -v "grep" |awk '{print $2}'`

echo "当前"$PROJECT_NAME"的进程ID="$PROJECT_THREAD_PID

#CURRENT_THREAD_PID=$(netstat -nlp | grep :$EXECUTE_PORT | awk '{print $7}' | awk -F"/" '{ print $1 }');
CURRENT_THREAD_PID=
if [ -n "$EXECUTE_PORT" ];then
    CURRENT_THREAD_PID=$(netstat -nlp | grep :$EXECUTE_PORT | awk '{print $7}' |sed 's/\([0-9]*\).*/\1/g');
    echo "执行shell命令：netstat -nlp | grep :$EXECUTE_PORT | awk '{print $7}' |sed 's/\([0-9]*\).*/\1/g'"
    echo "根据端口号 $EXECUTE_PORT 获取的进程号为 $CURRENT_THREAD_PID"
else
    echo "端口号为空，不执行根据端口号获取进程ID的命令。"
fi

#启动方法
start(){
    echo "3、启动服务"
    if [ "$EXECUTE_TYPE" == "restart" ]; then
        CURRENT_THREAD_PID=$(netstat -nlp | grep :$EXECUTE_PORT | awk '{print $7}' |sed 's/\([0-9]*\).*/\1/g');
    fi

    if [  -n  "$CURRENT_THREAD_PID"  ];  then
        echo "服务名称：$PROJECT_NAME ,端口号为:$EXECUTE_PORT ,进程号为：$CURRENT_THREAD_PID 的服务正在运行中....."
        echo "本次启动请求拒绝执行."
        exit 1
    fi

    echo -n "开始启动 $PROJECT_NAME"
    nohup java -server -jar -Dserver.port=$EXECUTE_PORT -Dspring.profiles.active=$EXECUTE_ENV  -XX:MaxMetaspaceSize=256m   -Xmx2048m   -Xss256k -XX:SurvivorRatio=8  $PROJECT_NAME > /dev/null 2>&1 &

    for st in $(seq 1 20)
    do
#        PID=$(netstat -nlp | grep :$EXECUTE_PORT | awk '{print $7}' | awk -F"/" '{ print $1 }');
        PID=$(netstat -nlp | grep :$EXECUTE_PORT | awk '{print $7}' |sed 's/\([0-9]*\).*/\1/g');
        if [ $st -eq 20 ] && [ -z "$PID" ]; then
            echo "服务启动失败"             break
        fi

        if [ -z "$PID" ]; then
            sleep 3
            echo $st"服务启动中...."         else
            echo "服务名称：$PROJECT_NAME ,端口号为:$EXECUTE_PORT ,进程号为：$PID 启动成功 , 耗时：$[$[st-1]*3] seconds！！！"
            break
        fi

    done
}

stop(){
    echo "开始执行停止服务命令！！！"
    if [ -z "$CURRENT_THREAD_PID" ] && [ -z "$PROJECT_THREAD_PID" ];then
        echo "端口号或者服务名称均不正确，请修正后重试！！！"
    fi

    if [  -n  "$CURRENT_THREAD_PID"  ];  then
       kill -9 $CURRENT_THREAD_PID
       echo "根据端口号【$EXECUTE_PORT】停止进程【$CURRENT_THREAD_PID】成功!!!"
    else
                if [ -n "$PROJECT_THREAD_PID" ]; then
            if [ $CURRENT_THREAD_COUNT -ne 1 ]; then
                echo "批量执行进程 kill 命令"
                for tpid in $PROJECT_THREAD_PID
                do
                    kill -9 $tpid
                    echo "根据服务名称【$PROJECT_NAME】 停止进程【$tpid】成功!!!"
                done
            else
                kill -9 $PROJECT_THREAD_PID
                echo "根据服务名称【$PROJECT_NAME】 停止进程【$PROJECT_THREAD_PID】成功!!!"
            fi
        fi
    fi
}
restart(){
    stop
    start
}
case "$EXECUTE_TYPE" in
  "start")
    start
    ;;
  "stop")
    stop
    ;;
  "status")
    status
    ;;
  "restart")
    restart
    ;;
  *)
    usage
    ;;
esac