#!/usr/bin/env bash

for protodir in $(find $PROTOPATHPRJ -name "*.proto" | xargs -n1 dirname | uniq); do
    echo "Processing project proto folder:" $protodir
    if [ -f $protodir/.singlefilecompilation ]; then
        for protofile in $(find $protodir -name "*.proto"); do
            echo "Processing project proto file:" $protofile
            protoc $PROTOPATHFLAGS --go_out=plugins=grpc:$PROTOOUT --grpc-gateway_out=logtostderr=true:$PROTOOUT/$PROJECT --swagger_out=logtostderr=true:$PROTOSWAGGER/$PROJECT $protofile
        done
    else
        protoc $PROTOPATHFLAGS --go_out=plugins=grpc:$PROTOOUT --grpc-gateway_out=logtostderr=true:$PROTOOUT/$PROJECT --swagger_out=logtostderr=true:$PROTOSWAGGER/$PROJECT $protodir/*.proto
    fi
done
for protodir in $(find $PROTOPATHVENDOR -name "*.proto" | xargs -n1 dirname | uniq); do
    echo "Processing vendor  proto folder:" $protodir
    if [ -f $protodir/.singlefilecompilation ]; then
        for protofile in $(find $protodir -name "*.proto"); do
            echo "Processing vendor  proto file:  " $protofile
            protoc $PROTOPATHFLAGS --go_out=plugins=grpc:$PROTOOUT/vendor $protofile
        done
    else
        protoc $PROTOPATHFLAGS --go_out=plugins=grpc:$PROTOOUT/vendor $protodir/*.proto
    fi
done
