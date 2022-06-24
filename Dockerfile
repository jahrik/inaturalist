FROM ruby:2.6.5

# Some usefull docs
# https://github.com/nickjj/docker-rails-example
# https://docs.docker.com/samples/rails/

# container_name of the postgres instance in the docker-compose.yml file.
# It will be able to see this 'postgres' host if they're both running in the same docker network
ARG PGHOST=postgres
# Overwrite these at build time with --build-arg PGPASSWORD=$PGPASSWORD, etc...
ARG PGUSER=postgres
ARG PGPASSWORD=postgres
ARG RAILS_ENV=development
ARG ELASTICSEARCH_HOST?=http://elasticsearch:9200

ENV PGHOST="${PGHOST}" \
    PGUSER="${PGUSER}" \
    PGPASSWORD="${PGPASSWORD}" \
    RAILS_ENV="${RAILS_ENV}" \
    GEM_HOME="/usr/local/bundle" \
    PATH="$GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH" \
    ELASTICSEARCH_HOST?=${ELASTICSEARCH_HOST}

# Install any requirements
RUN apt-get update && \
    apt-get -y install \
    build-essential \
    libcurl4-openssl-dev \
    gdal-bin \
    proj-bin \
    proj-data \
    libgeos-dev \
    libgeos++-dev \
    libproj-dev \
    ffmpeg \
    imagemagick \
    exiftool \
    nodejs \
    postgresql-client

# Add a non-root user to run the app
RUN groupadd -r inat && \
    useradd -m -g inat inat

# Switch to the inat user and create a workdir to copy everything to
USER inat
WORKDIR /inaturalist

# Copy the Gemfile and install gems before copying other stuff
# so it doesn't have to run bundle install everytime something changes
COPY --chown=inat:inat Gemfile Gemfile.lock ./
RUN gem install bundler && \
    bundle install --jobs 4 --retry 3

# Copy everything else
# TODO: restrict this to just the files and folders needed instead of copying everything
COPY --chown=inat:inat . .

RUN chmod +x docker-entrypoint.sh

# ENTRYPOINT ['unset', 'BUNDLE_PATH', 'unset', 'BUNDLE_BIN']
# CMD ['bundle', 'exec', 'rails', 's', '-p', '3000', '-b', '0.0.0.0']
