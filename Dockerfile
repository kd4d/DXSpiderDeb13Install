FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates perl build-essential \
    libdbi-perl libdbd-sqlite3-perl libdigest-sha-perl \
    libio-socket-ssl-perl libio-socket-inet6-perl libnet-telnet-perl \
    libjson-perl libcache-lru-perl libdata-structure-util-perl \
    libtimedate-perl libmojolicious-perl libmath-round-perl \
    libarchive-zip-perl libcurses-perl procps net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd
RUN curl -sSL https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Set up sysop user
RUN useradd -m -u 1000 -s /bin/bash sysop

# Clone DXSpider
RUN git clone -b mojo https://github.com/EA3CV/dx-spider.git /spider \
    && mkdir -p /spider/local /spider/local_data /spider/connect \
    && chown -R sysop:sysop /spider

# Create entrypoint script using bash built-in /dev/tcp check
RUN echo '#!/bin/bash\n\
rm -f /spider/local_data/cluster.lck\n\
if [ ! -f /spider/local_data/dxusers.db ]; then\n\
  echo "Initializing DXSpider user DB..."\n\
  echo "" | perl -I/spider/local -I/spider/perl /spider/perl/create_sysop.pl\n\
fi\n\
\n\
( \n\
  echo "Waiting for DXSpider daemon on port 7300..."\n\
  while ! (echo > /dev/tcp/127.0.0.1/7300) 2>/dev/null; do sleep 1; done\n\
  echo "DXSpider port 7300 detected! Starting ttyd on port 8080..."\n\
  exec ttyd -p 8080 -W -c "sysop:????????" perl -I/spider/local -I/spider/perl /spider/perl/console.pl ?????\n\
) &\n\
\n\
echo "Starting DXSpider Cluster Daemon..."\n\
exec perl -I/spider/local -I/spider/perl /spider/perl/cluster.pl\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /spider
EXPOSE 7300 8080
USER sysop

ENTRYPOINT ["/entrypoint.sh"]
