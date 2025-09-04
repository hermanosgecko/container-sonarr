###############################################################################
# BASE IMAGE
###############################################################################
FROM docker.io/library/debian:12-slim AS base

ENV DEBIAN_FRONTEND=noninteractive

ARG USER_UID=1000
ARG USER_GID=1000
ARG USERNAME=hermanosgecko

# Create a new group
RUN groupadd -g ${USER_GID} ${USERNAME} \
 && useradd --uid ${USER_UID} --gid ${USER_GID} --home-dir /opt --shell /bin/bash ${USERNAME}

###############################################################################
# BUILD IMAGE
###############################################################################
FROM base AS builder

ARG APP_DIR=/opt/app

ADD --chown=1000:1000 *.tar.gz /tmp/extract/

RUN mkdir ${APP_DIR} \
 && mv /tmp/extract/* ${APP_DIR}/bin \
 && rm -rf ${APP_DIR}/bin/*.Update \
 && echo "UpdateMethod=docker\nBranch=${APP_BRANCH:-main}\nPackageVersion=${APP_VERSION:-latest}\nPackageAuthor=[hermanosgecko](https://github.com/hermanosgecko)" > "${APP_DIR}/package_info"  \
 && chown -R 1000:1000 ${APP_DIR} \
 && chmod -R u=rwX,go=rX "${APP_DIR}" 

###############################################################################
# RUNTIME IMAGE
###############################################################################
FROM base as runtime

# EXPOSE THE PORT
EXPOSE 8989

# CREATE THE CONFIG DIRECTORY
RUN mkdir /config \
 && chown 1000:1000 /config

 # COPY THE DEFAULT CONFIG FILE
COPY --chown=1000:1000 config.xml /config

VOLUME ["/config"]

# INSTALL PREREQUISITES
RUN apt update && \
    apt install -y libicu72 ca-certificates libsqlite3-0

# COPY APP 
COPY --from=builder /opt/app /opt/app

USER 1000
WORKDIR /opt/app
CMD [ "/opt/app/bin/Sonarr", "-nobrowser", "-data=/config" ]