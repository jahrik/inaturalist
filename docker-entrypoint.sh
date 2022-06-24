#!/bin/bash

if [ "$RAILS_ENV" == "development" ]
then
    rails r "Site.create( name: 'iNaturalist', url: 'http://localhost:3000' )"
    rails r "User.create( login: 'testerson', password: 'tester', password_confirmation: 'tester', email: 'test@test.com' )"

    # Elasticsearch
    rake es:rebuild

    # Load some seed data
    rails r tools/load_sources.rb
    rails r tools/load_iconic_taxa.rb
    rake inaturalist:generate_translations_js

    rails r tools/import_natural_earth_countries.rb
    rails r tools/import_us_states.rb
    rails r tools/import_us_counties.rb
    rails r tools/load_dummy_observations.rb

else
    echo "SOMETHING ELSE HAPPENED"
fi

exec "$@"
