# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Define a default value so it's not empty if the builder fails to provide it
ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM node:20.20.2-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293 AS builder

# Some packages (e.g. @google-cloud/profiler) require additional
# deps for post-install scripts
RUN apk add --update --no-cache \
    python3 \
    make \
    g++

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install --only=production

FROM node:20.20.2-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293
# ^ pinned to the exact same digest as the builder stage above, so the Node.js ABI
# (and therefore pprof's native binary) matches. The previous "alpine + apk add nodejs"
# approach installed whatever Node version Alpine's package repo currently has, which
# drifts forward over time and breaks the native binary copied from the builder stage.

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/node_modules ./node_modules

COPY . .

EXPOSE 7000

# @google-cloud/profiler only works when running on GCP (auto-detects its Project ID
# via the GKE/GCE metadata service). Our target platforms are kind and Azure AKS, not
# GCP, so the metadata service never exists and the profiler crashes on startup unless
# explicitly disabled.
ENV DISABLE_PROFILER=1

ENTRYPOINT [ "node", "server.js" ]
