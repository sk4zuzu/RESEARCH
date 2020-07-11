
FROM alpine:3

RUN : INSTALL GENERAL PURPOSE PACKAGES \
 && apk --no-cache add \
    bash

ARG HOST_UID
ARG HOST_GID

RUN : SETUP HOST-MATCHING UID:GID USER ACCOUNT \
 && if _GETENT=`getent group ${HOST_GID}`; then \
      _GROUP=${_GETENT%%:*}; \
    else \
      _GROUP="newgroup"; \
      addgroup -g ${HOST_GID} ${_GROUP}; \
    fi \
 && if ! getent passwd ${HOST_UID}; then \
      _USER="newuser"; \
      adduser -u ${HOST_UID} -G ${_GROUP} -h /home/${_USER} -s /bin/bash -D ${_USER}; \
    fi

USER ${HOST_UID}

ENTRYPOINT []

CMD exec id

# vim:ts=2:sw=2:et:syn=dockerfile:
