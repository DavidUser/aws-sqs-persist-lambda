docker_image.json: ./Dockerfile | ./dependencies/aws-lambda-cpp ./dependencies/aws-sdk-cpp
	-rm -rf ./dependencies/*/build
	DOCKER_BUILDKIT=1 docker build -t aws-cpp-build .
	docker inspect aws-cpp-build > $@

container-build: docker_image.json
	docker run --rm -it -v$$(pwd):/app:Z -u1000:1000 aws-cpp-build

.PHONY: container-build
