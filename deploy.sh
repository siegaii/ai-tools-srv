image_name="ai-tools-srv"

if docker ps -aq -f name=$image_name > /dev/null; then
    if docker inspect -f '{{.State.Running}}' $image_name > /dev/null; then
        docker stop $image_name > /dev/null
    fi
    docker rm $image_name > /dev/null
    echo "Removed container: $image_name。"
fi

if docker images --format "{{.Repository}}" | grep -q "^$image_name$"; then
    docker rmi $image_name > /dev/null
    echo "Removed image: $image_name。"
fi

docker build -t $image_name .

docker run -itd \
-p 7002:7002 \
-e OPENAI_ACCESS_TOKEN=$OPENAI_ACCESS_TOKEN \
-v /etc/letsencrypt/archive/siegaii.com:/etc/nginx/certs \
--name $image_name \
$image_name

echo "Container Starting $image_name。"

docker rmi $(docker images | grep '<none>' | awk '{print $3}')