SRC = $(shell find src)

all: ./infrastructure/build/lambda.json

./dependencies/aws-lambda-cpp ./dependencies/aws-sdk-cpp: .gitmodules
	git submodule update --init 

/usr/local/include/aws/lambda-runtime: ./dependencies/aws-lambda-cpp
	cd ./dependencies/aws-lambda-cpp \
		&& mkdir -p build && cd build \
		&& cmake3 .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
		&& make && sudo make install

/usr/local/include/aws/sqs /usr/local/include/aws/dynamodb: ./dependencies/aws-sdk-cpp
	git submodule update --init
	cd ./dependencies/aws-sdk-cpp \
		&& mkdir -p build && cd build \
		&& cmake3 .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_ONLY="sqs;dynamodb" -DCPP_STANDARD=17 \
		&& make && sudo make install

./build/sqs-persist.zip: ./CMakeLists.txt ${SRC} /usr/local/include/aws/lambda-runtime /usr/local/include/aws/sqs
	mkdir -p build && cd build \
		&& cmake3 .. \
		&& make aws-lambda-package-sqs-persist

./infrastructure/build/role.json:
	aws iam create-role \
		--role-name lambda-cpp-demo \
		--assume-role-policy-document file://infrastructure/src/trust-policy.json > $@
	aws iam attach-role-policy \
		--role-name lambda-cpp-demo \
		--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
	aws iam attach-role-policy \
		--role-name lambda-cpp-demo \
		--policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

./infrastructure/build/lambda.json: ./build/sqs-persist.zip ./infrastructure/build/role.json
	aws lambda create-function \
		--function-name sqs-persist \
		--role "$$(cat $(word 2,$^) | jq -r '.Role.Arn')" \
		--runtime provided \
		--timeout 3 \
		--memory-size 128 \
		--environment "Variables={QUEUE_URL=\"https://sqs.us-east-1.amazonaws.com/833072764296/simple-test\",TABLE_NAME=test}" \
		--handler sqs-persist \
		--zip-file fileb://$< > $@ \
	 || aws lambda update-function-code \
		--function-name sqs-persist \
		--zip-file fileb://$< > $@

output.txt: ./infrastructure/build/lambda.json
	aws lambda invoke --function-name $$(cat $< | jq -r '.FunctionName') --payload '{ }' $@

build: ./build/sqs-persist.zip

run:
	-@rm -f output.txt
	${MAKE} output.txt

clean: 
	-rm -rf build
	-aws lambda delete-function --function-name sqs-persist
	-aws iam detach-role-policy \
		--role-name lambda-cpp-demo \
		--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
	-aws iam detach-role-policy \
		--role-name lambda-cpp-demo \
		--policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
	-aws iam delete-role --role-name lambda-cpp-demo
	-rm -rf infrastructure/build/*.json
	-rm -f output.txt


.PHONY: build run clean

include container.mk
