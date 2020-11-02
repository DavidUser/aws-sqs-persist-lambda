SRC = $(shell find src)

all: ./infrastructure/build/lambda.json

/usr/local/include/aws/lambda-runtime:
	git submodule update --init
	cd ./dependencies/aws-lambda-cpp \
		&& mkdir -p build && cd build \
		&& cmake3 .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF
		&& make && make install

/usr/local/include/aws/sqs /usr/local/include/aws/dynamodb:
	git submodule update --init
	cd ./dependencies/aws-sdk-cpp \
		&& mkdir -p build && cd build \
		&& cmake3 .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_ONLY="sqs;dynamodb" -DCPP_STANDARD=17 \
		&& make && make install

./build/sqs-persist.zip: ./CMakeLists.txt ${SRC} /usr/local/include/aws/lambda-runtime /usr/local/include/aws/sqs
	mkdir -p build && cd build \
		&& cmake .. \
		&& make aws-lambda-package-sqs-persist

./infrastructure/build/role.json:
	aws iam create-role \
		--role-name lambda-cpp-demo \
		--assume-role-policy-document file://infrastructure/src/trust-policy.json > $@

./infrastructure/build/lambda.json: ./build/sqs-persist.zip ./infrastructure/build/role.json
	aws lambda create-function \
		--function-name sqs-persist \
		--role "$$(cat $(word 2,$^) | jq -r '.Role.Arn')" \
		--runtime provided \
		--timeout 15 \
		--memory-size 128 \
		--handler sqs-persist \
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
	-aws iam delete-role --role-name lambda-cpp-demo
	-rm -rf infrastructure/build/*.json
	-rm -f output.txt


.PHONY: build run clean
