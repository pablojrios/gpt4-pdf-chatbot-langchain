# Based on https://github.com/vercel/next.js/blob/canary/examples/with-docker-compose/next-app/dev.Dockerfile
# En modo dev genera una imagen de ~2.5 GB lo cual es inadmisible:
# docker image ls
# REPOSITORY          TAG       IMAGE ID       CREATED          SIZE
# gpt35-pdf-chatbot   v1.0      2699223c6e45   47 seconds ago   2.49GB

FROM node:18-alpine AS base

FROM base AS builder 
RUN apk add --no-cache libc6-compat
WORKDIR /app


# Install dependencies 
COPY package.json yarn.lock ./
# RUN  npm install --production
# Omit --production flag for TypeScript devDependencies
RUN yarn install --frozen-lockfile

WORKDIR /app
# Copy app files
COPY components ./components
COPY config ./config
COPY declarations ./declarations
COPY docs ./docs
COPY next.config.js .
COPY next-env.d.ts .
COPY pages ./pages
COPY postcss.config.cjs .
COPY public ./public
COPY README.md .
COPY scripts ./scritps
COPY styles ./styles
COPY tailwind.config.cjs .
COPY tsconfig.json .
COPY types ./types
COPY utils ./utils
COPY visual-guide ./visual-guide

ENV NEXT_TELEMETRY_DISABLED 1

# Build Next.js
# RUN npm run build (es equivalente a yarn build)
# yarn build se usa para armar un binario para producción, pero como voy a arrancar el server en modo dev con yarn dev
# yarn build no hace falta.
RUN yarn build
# RUN npm run build

# Note: It is not necessary to add an intermediate step that does a full copy of `node_modules` here

# Step 2. Production image, copy all the files and run next
FROM base as runner
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED 1

# TODO: Don't run production as root
# RUN addgroup --system --gid 1001 nodejs
# RUN adduser --system --uid 1001 nextjs
# RUN adduser nextjs nodejs

# RUN chown nextjs:nodejs /app

# previamente ejecuté:
# rm -fr .next
# yarn build
# yarn start
# Así cuando vas a http://localhost:3000 no compila ningún archivo ya que no corrí npm run dev
#
# pablo@visionaria:~/dev/gpt4-pdf-chatbot-langchain(main)$ ls -l .next
# total 832
# -rw-rw-r-- 1 pablo pablo     21 jul  4 22:17 BUILD_ID
# -rw-rw-r-- 1 pablo pablo   1125 jul  4 22:17 build-manifest.json
# drwxrwxr-x 6 pablo pablo   4096 jul  4 22:18 cache
# -rw-rw-r-- 1 pablo pablo     93 jul  4 22:17 export-marker.json
# -rw-rw-r-- 1 pablo pablo    511 jul  4 22:17 images-manifest.json
# -rw-rw-r-- 1 pablo pablo 101681 jul  4 22:17 next-server.js.nft.json
# -rw-rw-r-- 1 pablo pablo     20 jul  4 22:16 package.json
# -rw-rw-r-- 1 pablo pablo    362 jul  4 22:17 prerender-manifest.js
# -rw-rw-r-- 1 pablo pablo    312 jul  4 22:17 prerender-manifest.json
# -rw-rw-r-- 1 pablo pablo      2 jul  4 22:17 react-loadable-manifest.json
# -rw-rw-r-- 1 pablo pablo   2953 jul  4 22:17 required-server-files.json
# -rw-rw-r-- 1 pablo pablo    484 jul  4 22:16 routes-manifest.json
# drwxrwxr-x 4 pablo pablo   4096 jul  4 22:17 server
# drwxrwxr-x 6 pablo pablo   4096 jul  4 22:17 static
# -rw-rw-r-- 1 pablo pablo 693546 jul  4 22:17 trace


# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
# COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/.next ./.next

# USER nextjs

# Note: Don't expose ports here, Compose will handle that for us
# EXPOSE 3000
# ENV PORT 3000

# npm start requiere un build de producción con lo que levanta desde .next/
CMD ["npm", "start"]
