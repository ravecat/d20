FROM d20/toolchain:latest AS base

WORKDIR /app

ENV CI="true"

RUN printf "[safe]\n\tdirectory = /app\n" > /root/.gitconfig

COPY mix.exs mix.lock ./

RUN mix local.hex --force \
  && mix local.rebar --force

FROM base AS dependencies

ENV MIX_ENV="dev"

COPY config/config.exs config/dev.exs config/
COPY assets/package.json assets/bun.lock assets/

RUN mix deps.get
RUN mix deps.compile
RUN mix assets.setup

FROM dependencies AS development

COPY . .

RUN mix compile

RUN mkdir -p /app/bin \
  && printf '#!/bin/sh\nset -eu\ncd /app\nexec mix ecto.migrate\n' > /app/bin/migrate \
  && chmod +x /app/bin/migrate

EXPOSE 5000 5174

CMD ["mix", "phx.server"]

FROM base AS build

ENV MIX_ENV="prod"

COPY config/config.exs config/prod.exs config/
COPY assets/package.json assets/bun.lock assets/

RUN mix deps.get --only prod
RUN mix deps.compile

COPY priv priv
COPY assets assets
COPY lib lib

RUN mix compile
RUN mix assets.setup
RUN mix assets.deploy

COPY config/runtime.exs config/
COPY rel rel

RUN mix release

FROM d20/runtime:latest

WORKDIR /app

ENV MIX_ENV="prod"

ENV LANG="C.UTF-8"
ENV LANGUAGE="C"
ENV LC_ALL="C.UTF-8"
ENV SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
ENV NIX_SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
ENV PATH="/bin"

COPY --from=build --chown=65534:65534 /app/_build/prod/rel/d20 ./

RUN find /app/bin /app/releases -type f -perm -0100 -print \
  | while IFS= read -r path; do \
    sed -i -e '1s|^#!.*/bin/sh$|#!/bin/sh|' -e '1s|^#!.*/bin/bash$|#!/bin/sh|' "$path"; \
  done

RUN find /app/erts-* /app/lib -type f \( -perm -0100 -o -name '*.so' \) -print \
  | while IFS= read -r path; do \
    if rpath="$(patchelf --print-rpath "$path" 2>/dev/null)"; then \
      patchelf --set-rpath "/lib${rpath:+:$rpath}" "$path"; \
    fi; \
  done

USER 65534:65534

CMD ["/app/bin/server"]
