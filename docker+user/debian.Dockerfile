
FROM debian:buster-slim

RUN : INSTALL GENERAL PURPOSE PACKAGES \
 && apt-get -q update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bash \
 && : APT FULL CLEANUP \
 && rm -rf /var/lib/apt/lists/*

ARG HOST_UID
ARG HOST_GID

RUN : SETUP HOST-MATCHING UID:GID USER ACCOUNT \
 && if _GETENT=`getent group ${HOST_GID}`; then \
      _GROUP=${_GETENT%%:*}; \
    else \
      _GROUP="newgroup"; \
      groupadd -g ${HOST_GID} ${_GROUP}; \
    fi \
 && if ! getent passwd ${HOST_UID}; then \
      _USER="newuser"; \
      useradd -u ${HOST_UID} -g ${_GROUP} -m -d /home/${_USER} -s /bin/bash ${_USER}; \
    fi

USER ${HOST_UID}

ENTRYPOINT []

CMD exec id

# vim:ts=2:sw=2:et:syn=dockerfile:
