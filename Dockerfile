ARG BUILDER_IMAGE="elixir:1.18.2-otp-27-slim"
ARG RUNNER_IMAGE="debian:bookworm-slim"

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y && \
    apt-get install -y build-essential git curl ca-certificates && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN mix assets.setup
RUN mix compile
RUN mix assets.deploy

COPY config/runtime.exs config/
COPY rel rel

RUN mix release

FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates sqlite3 tzdata && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TZ=America/Santiago
ENV MIX_ENV="prod"

WORKDIR "/app"

RUN mkdir -p /app/data /app/artifacts /app/backups

COPY --from=builder /app/_build/${MIX_ENV}/rel/mis_redes_sociales ./

EXPOSE 4000

CMD ["/app/bin/server"]
