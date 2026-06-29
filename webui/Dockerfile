FROM caddy:2-alpine

COPY index.html /srv/index.html
COPY globe.html /srv/globe.html
COPY upload.html /srv/upload.html
COPY app.html /srv/app.html
COPY gems.json /srv/gems.json
COPY config.js /srv/config.js
COPY Caddyfile /etc/caddy/Caddyfile

# Caddy reads $PORT from the env (Railway injects it); see Caddyfile.
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
