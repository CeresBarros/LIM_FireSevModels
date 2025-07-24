## Initialise docker container.
docker run -d \
-it \
-e PASSWORD=!Caribou4 \
-e USER=cbarros
--memory=100g \
--cpus=32 \
-p 8080:8787 \
--name LIM-docker \
--mount type=bind,source=/home/cbarros/LandscapesInMotion,target=/home/cbarros/LandscapesInMotion \
--mount type=bind,source=/mnt/scratch/cbarros/,target=/mnt/scratch/cbarros/ \
lim-cbarros
