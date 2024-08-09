FROM node:14.16.0-buster

# Install dependencies required for MongoDB
RUN apt-get update && apt-get install -y \
  build-essential \
  python3 \
  curl

RUN addgroup --system app && adduser --system --ingroup app app
USER app

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . . 
EXPOSE 3001
CMD ["npm", "start"]
