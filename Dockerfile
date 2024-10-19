FROM debian:12-slim as builder
RUN apt-get update -y \
    && apt-get install -y \
        gcc \
        make \
        libatomic1 \
        git \
        libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/vlang/v.git /vlang
RUN make -C /vlang
COPY . /app
RUN make -C /app V=/vlang/v

FROM debian:12-slim
RUN apt-get update -y \
    && apt-get install -y libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/vonitor /app/vonitor
CMD [ "/app/vonitor" ]
