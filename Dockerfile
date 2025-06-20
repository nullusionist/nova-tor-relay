FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
      wget gnupg2 lsb-release apt-transport-https \
      ca-certificates curl gettext && \
    wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
    | gpg --dearmor \
    | tee /usr/share/keyrings/tor-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/tor.list && \
    apt-get update && \
    apt-get install -y tor deb.torproject.org-keyring && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --system --group tor

COPY torrc.template /etc/tor/torrc.template
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /var/lib/tor && chown -R tor:tor /var/lib/tor

VOLUME ["/var/lib/tor"]

EXPOSE 9001 9030 9051

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
