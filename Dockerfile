FROM node:20-alpine
WORKDIR /app
# Install heavy native dependencies to simulate a large, slow build step
RUN apk add --no-cache build-base python3 make g++ postgresql-dev ffmpeg imagemagick
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
