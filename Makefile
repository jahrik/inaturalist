.EXPORT_ALL_VARIABLES:
RAILS_ENV?=development
PGHOST?=pg
PGUSER?=postgres
PGPASSWORD?=postgres
PGDB?=inaturalist_development
ELASTICSEARCH_HOST?=http://es:9200

all: services rails

build:
	docker-compose build

clean:
	docker-compose down --remove-orphans
	docker image prune
	docker volume prune

rails:
	docker build -t inat_rails .
	docker-compose up -d rails

services:
	docker-compose build --parallel es memcached redis pg
	docker-compose up -d es memcached redis pg

services-api:
	docker-compose build --parallel es memcached redis pg
	docker-compose up -d es memcached redis pg
ifdef API_PATH
	docker-compose -f $(API_PATH)/docker-compose.yml -f $(API_PATH)/docker-compose.override.yml up -d --build
else
	docker-compose -f ../iNaturalistAPI/docker-compose.yml -f ../iNaturalistAPI/docker-compose.override.yml up -d --build
endif

stop:
	docker-compose stop

development:

	# Still deciding to put this in the entrypoint or here...
	# -docker exec -t inat_rails rake es:rebuild
	# -docker exec -t inat_rails rails r "Site.create( name: 'iNaturalist', url: 'http://localhost:3000' )"
	# -docker exec -t inat_rails rails r "User.create( login: 'testerson', password: 'tester', password_confirmation: 'tester', email: 'test@test.com' )"
	# -docker exec -t inat_rails bundle exec rake db:setup RAILS_ENV=$(RAILS_ENV)
	-docker exec -t inat_rails rails r tools/load_sources.rb
	-docker exec -t inat_rails rails r tools/load_iconic_taxa.rb
	-docker exec -t inat_rails rake inaturalist:generate_translations_js
	-docker exec -t inat_rails rails r tools/import_natural_earth_countries.rb
	-docker exec -t inat_rails rails r tools/import_us_states.rb
	-docker exec -t inat_rails rails r tools/import_us_counties.rb
	-docker exec -t inat_rails rails r tools/load_dummy_observations.rb
