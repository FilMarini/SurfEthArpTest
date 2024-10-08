set -o errexit
set -o nounset
set -o xtrace

NET_IFC=enxf4a80db020cf
PORT_NUM=8192
IMAGE_NAME=ethernet-test
DOCKER_NETWORK=mymacvlan
CONTAINER_NET="192.168.2.0/24"
CONTAINER_CLIENT_IP="192.168.2.10"
CONTAINER_SERVER0_IP="192.168.2.11"
CONTAINER_SERVER1_IP="192.168.2.12"

# Create docker image
# docker build -f ./build_docker/Dockerfile -t ethernet-test ./build_docker

# Create MacVLAN docker network
docker network create -d macvlan --subnet=$CONTAINER_NET --ip-range=$CONTAINER_NET -o macvlan_mode=bridge -o parent=$NET_IFC $DOCKER_NETWORK

# Run server containers
docker run --rm -d -v `pwd`:`pwd` -w `pwd` --net=mymacvlan --ip=$CONTAINER_SERVER0_IP --name exch_server0 $IMAGE_NAME python3 cocotb-test/cocotb/SurfArpLoopback.py $CONTAINER_SERVER0_IP $PORT_NUM
docker run --rm -d -v `pwd`:`pwd` -w `pwd` --net=mymacvlan --ip=$CONTAINER_SERVER1_IP --name exch_server1 $IMAGE_NAME python3 cocotb-test/cocotb/SurfArpLoopback.py $CONTAINER_SERVER1_IP $PORT_NUM

# Wait a while for server to ready
sleep 1 

# Run client container
docker run --rm -v `pwd`:`pwd` -w `pwd` --net=mymacvlan --ip=$CONTAINER_CLIENT_IP --name exch_client $IMAGE_NAME make run

# Clean containers and delete network
docker kill `docker ps -a -q` || true
docker network rm $DOCKER_NETWORK
