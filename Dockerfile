FROM  golang:alpine3.10

WORKDIR /root
# Alternatively use ADD https:// (which will not be cached by Docker builder)
RUN apk --no-cache \
    add curl \ 
    && echo "Pulling watchdog binary from Github." \
    && curl -sSL https://github.com/openfaas-incubator/of-watchdog/releases/download/0.7.3/of-watchdog > /usr/bin/fwatchdog \
    && chmod +x /usr/bin/fwatchdog \
    && apk del curl --no-cache

ENV TESSDATA_PREFIX /usr/share/tessdata

RUN set -x && apk add  --update --no-cache --virtual wget-dependencies \
    ca-certificates \
    openssl

RUN apk add build-base python-dev py-pip  jpeg-dev zlib-dev gcc
ENV LIBRARY_PATH=/lib:/usr/lib

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories

RUN apk --update --no-cache --repository \
    http://dl-cdn.alpinelinux.org/alpine/edge/main --repository \
    http://dl-cdn.alpinelinux.org/alpine/edge/community  add tesseract-ocr

RUN wget -O ${TESSDATA_PREFIX}/osd.traineddata https://github.com/tesseract-ocr/tessdata/raw/3.04.00/osd.traineddata && \
    wget -O ${TESSDATA_PREFIX}/equ.traineddata https://github.com/tesseract-ocr/tessdata/raw/3.04.00/equ.traineddata && \
    wget -O ${TESSDATA_PREFIX}/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/4.00/eng.traineddata && \
    wget -O ${TESSDATA_PREFIX}/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/4.00/heb.traineddata && \
    wget -O ${TESSDATA_PREFIX}/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/4.00/ara.traineddata && \
    wget -O ${TESSDATA_PREFIX}/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/4.00/fas.traineddata

RUN apk add \
    leptonica-dev \
    tesseract-ocr-dev \
    tesseract-ocr

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o handler .

ENV fprocess="./handler"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:8082"

HEALTHCHECK --interval=1s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]