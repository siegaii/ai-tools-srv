# service
FROM node:lts-alpine AS build

WORKDIR /app

COPY . .

RUN npm install pnpm -g && pnpm install && pnpm build


FROM node:lts-alpine

WORKDIR /app

COPY --from=build /app/build ./build
COPY --from=build /app/package.json ./
COPY --from=build /app/pnpm-lock.yaml ./

RUN npm install pnpm -g && pnpm install --prod

# Set the NODE_ENV environment variable to 'production'
ENV NODE_ENV=production

EXPOSE 7001

CMD ["npm", "run", "prod"]
