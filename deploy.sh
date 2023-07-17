image_name="ai-tools-srv"

# 停止并删除 Docker 容器
if docker ps -aq -f name=$image_name > /dev/null; then
    if docker inspect -f '{{.State.Running}}' $image_name > /dev/null; then
        docker stop $image_name > /dev/null
    fi
    docker rm $image_name > /dev/null
    echo "已删除容器 $image_name。"
fi

# 删除 Docker 镜像
if docker images --format "{{.Repository}}" | grep -q "^$image_name$"; then
    docker rmi $image_name > /dev/null
    echo "已删除镜像 $image_name。"
fi

docker build -t $image_name .

docker run -itd \
-p 7001:7001 \
-e OPENAI_ACCESS_TOKEN=$OPENAI_ACCESS_TOKEN \
--name $image_name \
$image_name

echo "已启动容器 $image_name。"

docker rmi $(docker images | grep '<none>' | awk '{print $3}')