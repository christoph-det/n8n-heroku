FROM n8nio/n8n:latest

USER root

ARG TAILSCALE_VERSION=1.92.3
RUN set -eux; \
  node -e "const https=require('https');const fs=require('fs');const url='https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz';https.get(url,res=>{if(res.statusCode!==200){console.error('download failed',res.statusCode);process.exit(1);}const f=fs.createWriteStream('/tmp/tailscale.tgz');res.pipe(f);f.on('finish',()=>f.close());});"; \
  tar -xzf /tmp/tailscale.tgz -C /tmp; \
  cp "/tmp/tailscale_${TAILSCALE_VERSION}_amd64/tailscale" /usr/local/bin/tailscale; \
  cp "/tmp/tailscale_${TAILSCALE_VERSION}_amd64/tailscaled" /usr/local/bin/tailscaled; \
  chmod 0755 /usr/local/bin/tailscale /usr/local/bin/tailscaled; \
  rm -rf /tmp/tailscale*;

WORKDIR /home/node/packages/cli
ENTRYPOINT []

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
