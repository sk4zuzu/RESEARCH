FROM python:3.8.12-alpine3.14

RUN apk --no-cache add curl jq

COPY /requirements.txt /mesh-retry/

RUN apk --no-cache --virtual .build-deps add \
    gcc make musl-dev \
 && pip3 --no-cache-dir install -r /mesh-retry/requirements.txt \
 && apk --no-cache del .build-deps

COPY /*.py /mesh-retry/
COPY /*.sh /mesh-retry/

WORKDIR /mesh-retry/

ENTRYPOINT []

CMD python3 ./main.py & echo "$!" > ./main.py.pid \
 && exec sleep 3600
