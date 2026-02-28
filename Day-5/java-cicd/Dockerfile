FROM ubuntu:20.04
RUN apt-get update
RUN apt-get install openjdk-17-jdk
COPY app.jar /app.jar
CMD java -jar /app.jar