#!/bin/sh

VERSION=1.3.16-amd64

clean() {
    if [ $(docker images -q | wc -l) -gt 0 ]
    then
        docker rmi $(docker images -q) -f
    else
        echo "No Docker Images"
    fi
}

clean

while [ -z $(docker images | grep quay.io/nuclio/controller) ]; do
    docker pull quay.io/nuclio/controller:$VERSION
done
while [ -z $(docker images | grep quay.io/nuclio/dashboard) ]; do
    docker pull quay.io/nuclio/dashboard:$VERSION
done
while [ -z $(docker images | grep quay.io/nuclio/autoscaler) ]; do
    docker pull quay.io/nuclio/autoscaler:$VERSION
done
while [ -z $(docker images | grep quay.io/nuclio/dlx) ]; do
    docker pull quay.io/nuclio/dlx:$VERSION
done
while [ -z $(docker images | grep quay.io/nuclio/processor) ]; do
    docker pull quay.io/nuclio/processor:$VERSION
done
 while [ -z $(docker images | grep quay.io/nuclio/handler-builder-python-onbuild) ]; do
    docker pull quay.io/nuclio/handler-builder-python-onbuild:$VERSION
done
while [ -z $(docker images | grep quay.io/nuclio/handler-builder-java-onbuild) ]; do
    docker pull quay.io/nuclio/handler-builder-java-onbuild:$VERSION
done
while [ -z $(docker images | grep quay.io/nuclio/handler-builder-nodejs-onbuild) ]; do
    docker pull quay.io/nuclio/handler-builder-nodejs-onbuild:$VERSION
done