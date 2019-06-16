FROM perl:5.30

RUN mkdir -p /app
WORKDIR /app

RUN perl -MCPAN -e "install File::Next"
