require "active-fedora"
require 'jettywrapper'
jetty_zip_basename = 'hyacinth-fedora-3.7-with-risearch'
Jettywrapper.url = "https://github.com/elo2112/hydra-jetty/archive/#{jetty_zip_basename}.zip"

namespace :hyacinth do

  begin
    require 'rspec/core/rake_task'
    RSpec::Core::RakeTask.new(:rspec) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rspec_opts = ['--backtrace'] if ENV['CI']
    end

    RSpec::Core::RakeTask.new(:rcov) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rcov = true
    end
  rescue Exception => e
    puts "Exception creating rspec rake tasks: check for development environment?"
    puts e
  end

  desc "CI build"
  task :ci do

    unless File.exists?(File.join(Rails.root, 'jetty'))
      puts "\n"
      puts 'No jetty found.  Downloading / unzipping a copy now.'
      puts "\n"
    end

    Rake::Task["jetty:clean"].invoke

    Rails.env = "test"

    jetty_params = Jettywrapper.load_config
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task["hyacinth:test:setup_config_files_for_test_environment"].invoke
      Rake::Task["hyacinth:fedora:reload_cmodels"].invoke
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke
      Rake::Task['hyacinth:index:reindex'].invoke
      Rake::Task['hyacinth:projects:test:setup'].invoke
      Rake::Task['hyacinth:coverage'].invoke
    end
    raise "test failures: #{error}" if error
  end

  desc "Execute specs with coverage"
  task :coverage do
    # Put spec opts in a file named .rspec in root
    ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'

    Rake::Task["hyacinth:rspec"].invoke
  end

end
