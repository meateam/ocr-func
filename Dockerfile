FROM openfaas/of-watchdog:0.7.3 as watchdog

FROM golang:1.13.5 as build

RUN apt install -y git

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

RUN mkdir -p /go/src/handler
WORKDIR /go/src/handler

ARG GO111MODULE="on"

RUN apt-get -qq update \
  && apt-get install -y \
    libleptonica-dev \
    libtesseract-dev \
    tesseract-ocr

# Load languages
RUN apt-get install -y \
  tesseract-ocr-eng \
  tesseract-ocr-heb \
  tesseract-ocr-fas \
  tesseract-ocr-ara

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build --ldflags "-s -w" -a -installsuffix cgo -o handler .

FROM alpine:3.10

ENV TESSDATA_PREFIX /usr/share/tessdata

RUN set -x && apk add --update --no-cache --virtual wget-dependencies \
    ca-certificates \
    openssl

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories

RUN apk add --update --no-cache --repository \
    http://dl-cdn.alpinelinux.org/alpine/edge/main --repository \
    http://dl-cdn.alpinelinux.org/alpine/edge/community


RUN apk add \
    leptonica-dev \
    tesseract-ocr-dev \
    tesseract-ocr

RUN wget -O ${TESSDATA_PREFIX}/osd.traineddata https://github.com/tesseract-ocr/tessdata/raw/3.04.00/osd.traineddata && \
    wget -O ${TESSDATA_PREFIX}/equ.traineddata https://github.com/tesseract-ocr/tessdata/raw/3.04.00/equ.traineddata && \
    wget -O ${TESSDATA_PREFIX}/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/4.00/eng.traineddata && \
    wget -O ${TESSDATA_PREFIX}/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/4.00/heb.traineddata && \
    wget -O ${TESSDATA_PREFIX}/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/4.00/ara.traineddata && \
    wget -O ${TESSDATA_PREFIX}/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/4.00/fas.traineddata

# Add non root user and certs
RUN addgroup -S app && adduser -S -g app app \
    && mkdir -p /home/app \
    && chown app /home/app

WORKDIR /home/app

COPY --from=build /go/src/handler/handler    .
COPY --from=build /usr/bin/fwatchdog         .
COPY --from=build /go/src/handler/function/  .

RUN chown -R app /home/app

USER app

ENV fprocess="./handler"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:8082"

HEALTHCHECK --interval=1s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]