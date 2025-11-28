#!/bin/bash

## Initialise docker container.
docker run -d \
  -it \
  -e PASSWORD=55Borgui$ \
  -e USER=cbarros \
  --memory=248g \
  --cpus=28 \
  -p 8888:8787 \
  --name LIM-docker \
  --mount type=bind,source=/home/cbarros/LandscapesInMotion,target=/home/cbarros/LandscapesInMotion \
  --mount type=bind,source=/mnt/scratch/cbarros/,target=/mnt/scratch/cbarros/ \
  cbarros/lim-cbarros
