FROM n8nio/n8n:latest

USER root

ARG TAILSCALE_VERSION=1.92.3
ARG GOST_VERSION=3.0.0-rc10
RUN set -eux; \
  node -e "const https=require('https');const fs=require('fs');const url='https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz';const out='/tmp/tailscale.tgz';const get=u=>{https.get(u,res=>{if([301,302,307,308].includes(res.statusCode)&&res.headers.location){return get(res.headers.location);}if(res.statusCode!==200){console.error('download failed',res.statusCode);process.exit(1);}const f=fs.createWriteStream(out);res.pipe(f);f.on('finish',()=>f.close());});};get(url);"; \
  tar -xzf /tmp/tailscale.tgz -C /tmp; \
  cp "/tmp/tailscale_${TAILSCALE_VERSION}_amd64/tailscale" /usr/local/bin/tailscale; \
  cp "/tmp/tailscale_${TAILSCALE_VERSION}_amd64/tailscaled" /usr/local/bin/tailscaled; \
  chmod 0755 /usr/local/bin/tailscale /usr/local/bin/tailscaled; \
  rm -rf /tmp/tailscale*; \
  mkdir -p /var/lib/tailscale /var/run/tailscale /tmp/tailscale; \
  # Install gost for TCP forwarding through SOCKS5
  node -e "const https=require('https');const fs=require('fs');const url='https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_amd64.tar.gz';const out='/tmp/gost.tgz';const get=u=>{https.get(u,res=>{if([301,302,307,308].includes(res.statusCode)&&res.headers.location){return get(res.headers.location);}if(res.statusCode!==200){console.error('download failed',res.statusCode);process.exit(1);}const f=fs.createWriteStream(out);res.pipe(f);f.on('finish',()=>f.close());});};get(url);"; \
  tar -xzf /tmp/gost.tgz -C /tmp; \
  cp /tmp/gost /usr/local/bin/gost; \
  chmod 0755 /usr/local/bin/gost; \
  rm -rf /tmp/gost*;

WORKDIR /home/node/packages/cli
ENTRYPOINT []

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
