# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.provider :virtualbox do |vb|
    vb.cpus = 2
    vb.gui = false
    vb.customize ["modifyvm", :id, "--memory", "8192"]
    vb.customize ["modifyvm", :id, "--cpus", "4"]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    vb.customize ["modifyvm", :id, "--vram", "256"]
  end
  config.ssh.forward_x11 = true
  config.vm.network 'private_network', ip: '192.168.56.11'
  config.vm.hostname = 'inaturalist.dev'
  config.vm.synced_folder "./", "/home/vagrant/inaturalist"

  # Runs as root
  config.vm.provision "shell", inline: %{
    apt-get update
    apt-get upgrade -y

    # Install Requirements
    apt-get -y install \
      libpq-dev \
      build-essential \
      libcurl4-openssl-dev \
      gdal-bin \
      proj-bin \
      proj-data \
      libgeos-dev \
      libgeos++-dev \
      libproj-dev \
      ffmpeg \
      curl \
      gnupg2 \
      imagemagick \
      exiftool \
      redis \
      memcached \
      postgis \
      nodejs \
      openjdk-11-jdk

    # Install postgresql
    apt-get install -y \
      postgresql \
      postgresql-contrib
    systemctl start postgresql.service
    systemctl enable postgresql.service

    # Set the default postgres user's password
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

    # I think this is needed for Elasticsearch
    swapoff -a
    sysctl -w vm.swappiness=1
    sysctl -w fs.file-max=262144
    sysctl -w vm.max_map_count=262144

    # Install Elasticsearch
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
    apt-get update
    apt-get install elasticsearch
    # Disable security to get rid of warnings
    # "xpack.security.enabled: false"
    systemctl start elasticsearch
    systemctl enable elasticsearch
    # Install plugins
    /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-kuromoji || true
  }

  # Runs as vagrant user
  config.vm.provision "shell", privileged: false, inline: %{

    # Install RVM
    command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
    command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
    curl -sSL https://get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm
    rvm install "ruby-2.6.5"
    rvm use "ruby-2.6.5"

    # Install gems
    gem install bundler
    cd ~/inaturalist
    bundle install --jobs 4 --retry 3

    # Ruby setup
    echo -e "--format documentation\n--color\n--require spec_helper\n--profile\n--tty" > .rspec
    export PGHOST=0.0.0.0
    export PGUSER=postgres
    export PGPASSWORD=postgres
    RAILS_ENV=development
    # edit config/deploy.rb
    # set :passenger_restart_with_touch, true
    ruby bin/setup

    # Elasticsearch
    rake es:rebuild

    # Load some seed data
    rails r "Site.create( name: 'iNaturalist', url: 'http://localhost:3000' )"
    rails r tools/load_sources.rb
    rails r tools/load_iconic_taxa.rb
    rake inaturalist:generate_translations_js

    # Load more test data
    rails r "User.create( login: 'testerson', password: 'tester', password_confirmation: 'tester', email: 'test@test.com' )"
    rails r tools/import_natural_earth_countries.rb
    rails r tools/import_us_states.rb
    rails r tools/import_us_counties.rb
    rails r tools/load_dummy_observations.rb

    # Start the app!
    # rails s -b 127.0.0.1
    # rails s -b 0.0.0.0
    rails s -b 192.168.56.11 &
  }
end
