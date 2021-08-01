FROM adoptopenjdk/openjdk11:jdk-11.0.11_9-alpine-slim

RUN apk --no-cache add curl

WORKDIR /opt/

ARG MAVEN_VERSION=3.8.1

RUN curl -fsSL https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar xzf -

ENV PATH=/opt/apache-maven-$MAVEN_VERSION/bin:$PATH

COPY /pom.xml ./test1/pom.xml
RUN cd ./test1/ && mvn dependency:go-offline
RUN cd ./test1/ && mvn clean package

COPY / ./test1/
RUN cd ./test1/ && mvn clean package

ENTRYPOINT []

CMD echo test1
