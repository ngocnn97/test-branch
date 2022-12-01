 
FROM openjdk

WORKDIR /simple-java-maven-app

COPY . .


CMD [ "mvn", "-B" , "-DskipTests", "clean", "package"]
CMD [ "mvn", "test"]
CMD [./jenkins/scripts/deliver.sh]