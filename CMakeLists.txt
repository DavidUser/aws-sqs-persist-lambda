cmake_minimum_required(VERSION 3.5)

list(APPEND CMAKE_PREFIX_PATH "/usr/local")
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_STANDARD 20)
project(sqs-persist LANGUAGES CXX)

find_package(aws-lambda-runtime REQUIRED)
find_package(AWSSDK COMPONENTS sqs dynamodb)

add_executable(${PROJECT_NAME} "./src/main.cc")
target_include_directories(${PROJECT_NAME} PRIVATE "./include")
target_link_libraries(${PROJECT_NAME} PUBLIC AWS::aws-lambda-runtime)
target_link_libraries(${PROJECT_NAME} PUBLIC ${AWSSDK_LINK_LIBRARIES})
aws_lambda_package_target(${PROJECT_NAME})
