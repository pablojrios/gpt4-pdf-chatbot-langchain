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
COPY package.json yarn.lock* ./
# RUN  npm install --production
# Omit --production flag for TypeScript devDependencies
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  # Allow install without lockfile, so example works even without Node.js installed locally
  else echo "Warning: Lockfile not found. It is recommended to commit lockfiles to version control." && yarn install; \
  fi

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
# RUN yarn build
RUN npm run build

# Note: It is not necessary to add an intermediate step that does a full copy of `node_modules` here

# Step 2. Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED 1

# TODO: Don't run production as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# USER nextjs:nodejs

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
# COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/.next ./.next

# Note: Don't expose ports here, Compose will handle that for us
# EXPOSE 3000
# ENV PORT 3000

# npm start requiere un build de producción con lo que levanta desde .next/
CMD ["npm", "start"]
