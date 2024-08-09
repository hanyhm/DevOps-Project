FROM node:14.16.0-alpine3.13

RUN apk add --no-cache bash g++ gcc libgcc linux-headers make python3 openssl curl

RUN addgroup app && adduser -S -G app app
USER app

WORKDIR /app
COPY package*.json ./

# Pre-download MongoDB binary
RUN npm install mongodb-memory-server --unsafe-perm=true --allow-root && \
    node -e "require('mongodb-memory-server').MongoMemoryServer.create().then(server => server.start()).then(server => server.stop())"

RUN npm install
COPY . . 
EXPOSE 3001
CMD ["npm", "start"]
