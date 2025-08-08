FROM rocker/geospatial:4.1.3

## maintainer of this script
MAINTAINER Alex Chubaty <achubaty@for-cast.ca>

## update uid:gid for rstudio user to mach Ceres'
ARG USERNAME=rstudio
ARG USER_UID=1003
ARG USER_GID=1004

RUN groupmod --gid $USER_GID $USERNAME \
    && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
    && chown -R $USER_UID:$USER_GID /home/$USERNAME

