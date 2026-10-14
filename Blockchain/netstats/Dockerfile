FROM node:alpine

RUN apk add --update git && \
    rm -rf /var/cache/apk/*

RUN git clone https://github.com/goerli/netstats-server /netstats-server
WORKDIR /netstats-server
RUN \
    npm install && \
    npm install -g grunt-cli && \
    grunt

EXPOSE  3000
CMD ["npm", "start"]