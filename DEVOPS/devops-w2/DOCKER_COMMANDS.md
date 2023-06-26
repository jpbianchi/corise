## How to create the docker network
Create the dockerfiles

docker build --tag quote-gen-service .
docker build --tag quote-dist-service .

cd quote_gen 
docker run --name quote-gen-container -p 84:84 quote-gen-service

cd quote_disp 
docker run --name quote-disp-container -p 85:85 quote-disp-service

docker container ls # to get a list of the created containers

docker network create quote-network
docker network inspect quote-network
# we should see the containers in "Containers"

docker network connect quote-network quote-gen-container 
docker network connect quote-network quote-disp-container

Create the docker-compose.yml file

docker-compose up
# to remove the network containers, but keep quote-gen & quote-disp
docker-compose down  

# to increase the nb of replicas of each service
# either modify the compose.yml file or use th CLI
docker-compose up -d --scale web1=2 --scale web2=2 # overrides the yml file
