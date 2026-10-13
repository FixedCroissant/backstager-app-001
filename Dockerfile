# --- Stage 1: Build Stage ---
FROM node:20.18-bookworm AS installer

WORKDIR /app

# 1. Install build toolchain, Python symlinks, and libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-dev \
    python-is-python3 \
    gcc \
    g++ \
    make \
    build-essential \
    pkg-config \
    libsqlite3-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHON=/usr/bin/python3

# 2. Upgrade node-gyp globally & override local gyp calls
RUN npm install -g node-gyp@latest
ENV npm_config_node_gyp=/usr/local/lib/node_modules/node-gyp/bin/node-gyp.js

# 3. Corepack setup with explicit Yarn pre-hydration
RUN corepack enable && corepack prepare yarn@4.13.0 --activate

# 4. Copy ONLY package manifests to leverage Docker caching
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
# Copy subpackage manifests:
COPY packages/app/package.json ./packages/app/package.json
COPY packages/backend/package.json ./packages/backend/package.json

# 5. Manifest-only install (Populates cached dependencies)
#RUN yarn install --no-immutable || (cat /tmp/xfs-*/build.log 2>/dev/null && exit 1)

# 6. Copy full application source
COPY . .

# 7. Final workspace sync & build backend bundle from backend directory scope
#RUN yarn install --no-immutable && cd packages/backend && yarn build
# INSTALL YARN PACKAGES 
RUN yarn install --no-immutable
# COMPILE TYPE SCRIPT
RUN yarn tsc
# GO TO BACK END AND CREATE BUILD
RUN cd packages/backend && yarn build

# BELOW ARE FOR BASIC DEBUGGING.
#RUN yarn install --no-immutable && \
#    ls -la packages/backend/src/index.ts && \
#    yarn build:backend

# RUN ls -la packages/backend/

# RUN ls -la


# # --- Stage 2: Runtime Stage ---
FROM node:20.18-bookworm AS final
WORKDIR /app

# # 1. Install runtime OS dependencies & Python environment for TechDocs
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. Set up isolated TechDocs Python Virtual Environment
RUN python3 -m venv /opt/techdocs-venv && \
    /opt/techdocs-venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/techdocs-venv/bin/pip install --no-cache-dir mkdocs-techdocs-core

# 2 SET PATH for TECH DOCS TO GO
ENV PATH="/opt/techdocs-venv/bin:$PATH"

# 3. Enable Corepack and Yarn 4 in runtime stage
RUN corepack enable && corepack prepare yarn@4.13.0 --activate    

# 4. Copy root Yarn configuration so Berry knows how to resolve modules
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# 5. Copy the bundle archive from Stage 1 (referenced as 'build')
COPY --from=installer /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# 6. Install production node_modules from skeleton yarn.lock
# (Required because bundle.tar.gz only contains built JS, not node_modules)
RUN --mount=type=cache,target=/root/.yarn/berry/cache,sharing=shared \
    yarn workspaces focus --all --production

# 7. Copy configuration files
COPY app-config.yaml app-config.production.yaml ./

# 8. Ensure non-root node user owns workspace for TEchdocs build caching
RUN mkdir -p /app/.cache && chown node:node /app /app/.cache

USER node

EXPOSE 7007


# 9. Run the backend entrypoint directly
CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]



