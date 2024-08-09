FROM node:14.16.0-alpine3.13

RUN addgroup app && adduser -S -G app app
USER app

WORKDIR /app
COPY package*.json ./
RUN npm install

# Install dependencies required for MongoDB
RUN apk add --no-cache bash g++ gcc libgcc linux-headers make python3

COPY . . 

EXPOSE 3001

CMD ["npm", "start"]