APPLICATION_NAME=nginx
CURRENT_PID=$(docker ps -a --format "table {{.Ports}}\t{{.Image}}" | grep $APPLICATION_NAME | grep tcp | grep -v ^$ | awk '{ print substr($2,15,4) }')
BLUE_PORT=8080
GREEN_PORT=8081

echo "> 현재 구동중인 애플리케이션 PID : $CURRENT_PID"

if [ "$CURRENT_PID" == $BLUE_PORT ]; then
  echo "> 기존 애플리케이션의 포트는 $BLUE_PORT입니다."
  TARGET_PORT=$BLUE_PORT
elif [ "$CURRENT_PID" == $GREEN_PORT ]; then
  echo "> 기존 애플리케이션의 포트는 $GREEN_PORT입니다."
  TARGET_PORT=$GREEN_PORT
else
  echo "> 현재 구동 중인 애플리케이션의 포트를 찾는데 실패하였습니다."
  echo "> $BLUE_PORT 포트를 할당합니다."
  TARGET_PORT=$BLUE_PORT
fi


echo "sed -e 's/3000/$TARGET_PORT/g' ./nginx/default.conf > /dev/null"
