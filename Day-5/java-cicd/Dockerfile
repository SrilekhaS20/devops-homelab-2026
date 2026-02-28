FROM ubuntu:20.04
RUN apt-get update && apt-get install openjdk-17-jdk
RUN apt-get install -y maven
COPY . /app
WORKDIR /app
RUN mvn clean package
CMD java -jar target/demo-1.0.0.jar