name=irisNOPWS
com_version=2023.2.0NOPWS.105.0
host_superserver_port=1974
host_webserver_port=5556
unit_test_dir=/nethome/ypang/perforce/projects/nopws.1/internal/testing/unit_tests/
volume=/nethome/ypang/webgateway-examples/demo-dockerfile/iris-persistent-community/
docker stop $name
docker rm $name
docker run --name $name -d --publish $host_superserver_port:1972 --publish $host_webserver_port:52773 -v $unit_test_dir:/unit_tests -v $volume:/ipc  docker.iscinternal.com/intersystems/iris-community:$com_version
# Run unit test
sleep 15
docker exec -it $name bash -c 'echo -e "s ^UnitTestRoot=\"/unit_tests\"\nw ^UnitTestRoot\nd ##class(%UnitTest.Manager).RunTest(\"CSP\")\nh" | iris session iris'
