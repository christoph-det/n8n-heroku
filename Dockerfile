FROM n8nio/n8n:latest

USER root

ARG TAILSCALE_VERSION=1.66.4
RUN set -eux; \
  if command -v apk >/dev/null 2>&1; then \
    apk add --no-cache ca-certificates curl iptables; \
  elif command -v apt-get >/dev/null 2>&1; then \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl iptables; \
    rm -rf /var/lib/apt/lists/*; \
  else \
    echo "Unsupported base image: missing apk/apt-get" >&2; \
    exit 1; \
  fi; \
  curl -fsSL "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz" -o /tmp/tailscale.tgz; \
  tar -xzf /tmp/tailscale.tgz -C /tmp; \
  install -m 0755 "/tmp/tailscale_${TAILSCALE_VERSION}_amd64/tailscale" /usr/local/bin/tailscale; \
  install -m 0755 "/tmp/tailscale_${TAILSCALE_VERSION}_amd64/tailscaled" /usr/local/bin/tailscaled; \
  rm -rf /tmp/tailscale*;

WORKDIR /home/node/packages/cli
ENTRYPOINT []

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
