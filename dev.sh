APPLICATION_NAME=nginx
CURRENT_PORT=$(docker ps -a --format "table {{.Ports}}\t{{.Image}}" | grep $APPLICATION_NAME | grep tcp | grep -v ^$ | awk '{ print substr($2,15,4) }')
BLUE_PORT=8080
GREEN_PORT=8081

###
echo "> 현재 구동중인 애플리케이션 PORT : $CURRENT_PORT"
echo "> 현재 구동중인 애플리케이션 PID : $CURRENT_PORT"

if [ "$CURRENT_PORT" == $BLUE_PORT ]; then
  echo "> 기존 애플리케이션의 포트는 $BLUE_PORT입니다."
  TARGET_PORT=$BLUE_PORT
elif [ "$CURRENT_PORT" == $GREEN_PORT ]; then
  echo "> 기존 애플리케이션의 포트는 $GREEN_PORT입니다."
  TARGET_PORT=$GREEN_PORT
else
  echo "> 현재 구동 중인 애플리케이션의 포트를 찾는데 실패하였습니다."
  echo "> $BLUE_PORT 포트를 할당합니다."
  TARGET_PORT=$BLUE_PORT
fi

###
echo "> 새 애플리케이션 배포 - 포트번호 : $TARGET_PORT"
#JAR_NAME=$(ls -tr $REPOSITORY/ | grep jar | tail -n 1)

###
echo "> $TARGET_PORT 10초 후 Health check 시작"
echo "> curl -s http://localhost:$TARGET_PORT/infra/health "
sleep 10

for retry_count in {1..10}
do
  response=$(curl -s http://localhost:$TARGET_PORT/infra/health)
  up_count=$(echo "$response" | grep 'UP' | wc -l)

  if [ "$up_count" -ge 1 ]
  then # $up_count >= 1 ("UP" 문자열이 있는지 검증)
      echo "> Health check 성공"
      break
  else
      echo "> Health check의 응답을 알 수 없거나 혹은 status가 UP이 아닙니다."
      echo "> Health check: ${response}"
  fi

  if [ "$retry_count" -eq 10 ]
  then
    echo "> Health check 실패. "
    echo "> Nginx에 연결하지 않고 배포를 종료합니다."
    exit 1
  fi

  echo "> Health check 연결 실패. 재시도..."
  sleep 10
done

###
echo "> Change Port"
echo "sed -i 's/localhost:..../localhost:$TARGET_PORT/g' ./conf/default.conf"

###
echo "> Nginx Reload"
NGINX_PORT=$(docker ps |grep nginx | awk '$0=$1')
docker exec "$NGINX_PORT" service nginx reload

###
CURRENT_PID=$(docker ps | grep $APPLICATION_NAME | awk '$0=$1')
echo "Pid Kill: $CURRENT_PID"
if [ -z "$CURRENT_PID" ]; then
        echo "> 현재 구동 중인 애플리케이션이 없으므로 종료하지 않습니다."
else
        echo "> docker kill $CURRENT_PID"
        docker kill "$CURRENT_PID"

#        # shellcheck disable=SC2086
#        while kill -0 $CURRENT_PID; do
#                sleep 5
#                echo "> 프로세스가 아직 종료되지 않았습니다."
#        done
        echo "> $CURRENT_PID 종료 완료"
fi
