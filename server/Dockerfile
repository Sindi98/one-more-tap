# The AIR HOCKEY relay: docker build -t omt-relay . && docker run -p 47620:47620 omt-relay
FROM node:22-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY relay.mjs ./
USER node
ENV PORT=47620
EXPOSE 47620
CMD ["node", "relay.mjs"]
