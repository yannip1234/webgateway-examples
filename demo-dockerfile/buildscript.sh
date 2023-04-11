#/bin/bash

# Build variables
IMAGE=docker.iscinternal.com/intersystems/iris:2023.2.0NOPWS.105.0
APACHE_URL="https://dlcdn.apache.org/httpd/httpd-2.4.57.tar.gz"
APACHE_FOLDER="httpd-2.4.57"
WEB_GATEWAY_FOLDER="WebGateway-2023.2.0NOPWS.105.0-lnxubuntu2204x64"
PLATFORM="lnxubuntu2204x64"
TAG=local:iris-demo-image

docker build . -t $TAG --build-arg IMAGE=$IMAGE --build-arg APACHE_URL=$APACHE_URL \
    --build-arg APACHE_FOLDER=$APACHE_FOLDER \
    --build-arg WEB_GATEWAY_FOLDER=$WEB_GATEWAY_FOLDER \
    --build-arg PLATFORM=$PLATFORM


# Runtime variables
SS_PORT="-p 5551:1972"
WEB_PORT="-p 5552:8080"
# $PWD should refer to this (current) directory with the Dockerfile
BASEDIR=$PWD
VOLUME="iris-persistent"
NAME="iris-demo"
BINDMOUNT="-v $BASEDIR/$VOLUME:/$VOLUME"
unit_test_dir="-v /nethome/ypang/perforce/projects/nopws.1/internal/testing/unit_tests/:/unit_tests"
DURABLESYS="-e ISC_DATA_DIRECTORY=/$VOLUME/durable -e ISC_SENTINEL_DIR=/$VOLUME"
FLAGS="--cap-add IPC_LOCK --init --detach"
KEY="--key /$VOLUME/iris.key"

docker stop $NAME
sudo rm -rf iris-persistent
docker rm $NAME

# ensure mount directory exists for license key and durable SYS
mkdir iris-persistent && chmod 777 iris-persistent
cp iris.key iris-persistent/iris.key

docker run --name $NAME $WEB_PORT $SS_PORT $BINDMOUNT $unit_test_dir $DURABLESYS $FLAGS $TAG $KEY

# Ordinarily starting the web server is handled by the ENTRYPOINT executable,
# but we need the ENTRYPOINT to be iris-main, so instead we call exec after
# the container is launched to start the web server and activate the CSP.conf.
#
# If you must have the web server launch in the image's init, one option is to
# create an executable that wrappers the iris-main invocation (["/tini", "--", "/iris-main"]) 
# and starts apachectl, and make that the entrypoint. Otherwise, this is simpler.
docker exec $NAME /home/irisowner/apache2/bin/apachectl -k start

# Run unit test
sleep 30
docker exec -it $NAME bash -c 'echo -e "s ^UnitTestRoot=\"/unit_tests\"\nw ^UnitTestRoot\nd ##class(%UnitTest.Manager).RunTest(\"CSP\")\nh" | iris session iris'




