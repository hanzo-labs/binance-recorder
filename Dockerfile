# Node image
FROM node:alpine

# Maintainer details
MAINTAINER David Tai "david@hanzo.ai"

# Create directory
WORKDIR /app

# Copy package.json & NPM Install
COPY package.json /app
RUN npm install

# Copy rest of the app
COPY . /app

CMD ["npm", "start"]

