namespace :hyacinth do

  namespace :test do

    task :setup_config_files_for_test_environment do

      # database.yml
      database_yml_file = File.join(Rails.root, 'config/database.yml')
      FileUtils.touch(database_yml_file) # Create if it doesn't exist
      database_yml = YAML.load_file(database_yml_file) || {}
      database_yml['test'] = {
        'adapter' => 'sqlite3',
        'database' => 'db/test.sqlite3',
        'pool' => 5,
        'timeout' => 5000
      }
      File.open(database_yml_file, 'w') {|f| f.write database_yml.to_yaml }

      # fedora.yml
      fedora_yml_file = File.join(Rails.root, 'config/fedora.yml')
      FileUtils.touch(fedora_yml_file) # Create if it doesn't exist
      fedora_yml = YAML.load_file(fedora_yml_file) || {}
      fedora_yml['test'] = {
        :user => 'fedoraAdmin',
        :password => 'fedoraAdmin',
        :url => 'http://localhost:9983/fedora-test'
      }
      File.open(fedora_yml_file, 'w') {|f| f.write fedora_yml.to_yaml }

      # hyacinth.yml
      hyacinth_yml_file = File.join(Rails.root, 'config/hyacinth.yml')
      FileUtils.touch(hyacinth_yml_file) # Create if it doesn't exist
      hyacinth_yml = YAML.load_file(hyacinth_yml_file) || {}
      hyacinth_yml['test'] = {
        'solr_url' => 'http://localhost:9983/solr/hyacinth-test',
        'default_pid_generator_namespace' => 'cul',
        'default_asset_home' => File.join(Rails.root, 'tmp/asset_home_test'),
        'upload_directory' => File.join(Rails.root, 'tmp/upload_test')
      }
      File.open(hyacinth_yml_file, 'w') {|f| f.write hyacinth_yml.to_yaml }

      # secrets.yml
      secrets_yml_file = File.join(Rails.root, 'config/secrets.yml')
      FileUtils.touch(secrets_yml_file) # Create if it doesn't exist
      secrets_yml = YAML.load_file(secrets_yml_file) || {}
      secrets_yml['test'] = {
        'secret_key_base' => '6a30eac555d5cddd6d7b11d1bf9e815ba94032a2d0e88f1c12964f360ae5f90ecfbb7c6413616b10fc80b9ef9bede5926fbc9699332e9484b4221038751227d5', # This was randomly generated
        'session_store_key' =>  '_hyacinth_test_session_key'
      }
      File.open(secrets_yml_file, 'w') {|f| f.write secrets_yml.to_yaml }

      # solr.yml
      solr_yml_file = File.join(Rails.root, 'config/solr.yml')
      FileUtils.touch(solr_yml_file) # Create if it doesn't exist
      solr_yml = YAML.load_file(solr_yml_file) || {}
      solr_yml['test'] = {
        'url' => 'http://localhost:9983/solr/test'
      }
      File.open(solr_yml_file, 'w') {|f| f.write solr_yml.to_yaml }

    end

    task :create_sample_digital_objects => :environment do

      test_project = Project.find_by(string_key: 'test')
      test_user = User.find_by(email: 'hyacinth-test@library.columbia.edu')

      number_of_records_to_create = 400
      counter = 0

      start_time = Time.now

      number_of_records_to_create.times {

        digital_object = DigitalObject::Item.new
        digital_object.projects << test_project
        digital_object.created_by = test_user
        digital_object.updated_by = test_user

        random_adj = RandomWord.adjs.next
        random_adj.capitalize if random_adj
        random_noun = RandomWord.nouns.next
        random_noun.capitalize if random_noun
        random_title = random_adj.to_s + ' ' + random_noun.to_s

        digital_object.update_dynamic_field_data(
          {
            'title' => [
              {
                'title_sort_portion' => random_title
              }
            ],
            'name' => [
              {
                'name_value' => Faker::Name.name
              },
              {
                'name_value' => Faker::Name.name
              }
            ],
            'note' => [
              {
                'note_value' => Faker::Lorem.paragraph
              }
            ]
          }
        )

        unless digital_object.save
          puts 'Errors: ' + digital_object.errors.inspect
        end

        counter += 1
        puts "Processed #{counter} of #{number_of_records_to_create}"

      }

      puts 'Done.  Took ' + (Time.now - start_time).to_s + ' seconds.'

    end

  end

end
