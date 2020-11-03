FROM fedora

RUN dnf install -y g++ make cmake3 jq
RUN dnf install -y zlib-devel openssl-devel libcurl-devel
RUN dnf install -y zip
RUN dnf install -y findutils
RUN dnf install -y git

VOLUME /app
WORKDIR /app

ADD Makefile /app/Makefile
ADD .gitmodules /app/.gitmodules
ADD ./dependencies /app/dependencies

RUN make /usr/local/include/aws/lambda-runtime \
      /usr/local/include/aws/sqs \
      /usr/local/include/aws/dynamodb 

CMD make build/sqs-persist.zip
