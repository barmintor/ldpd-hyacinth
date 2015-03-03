require 'thread/pool'

namespace :hyacinth do

  namespace :publish do

    def publish_object_by_pid(pid)
      begin
        obj = DigitalObject::Base.find(pid)
        obj.publish
      rescue => e
        # Errors raised on different threads won't show up on the console, so we need to print them.
        error_message = 'Publish Error: Skipping ' + pid + "\nException: #{e.class}, Message: #{e.message}"
        puts error_message
        #puts e.backtrace.join("\n")
        Rails.logger.error(error_message)
      end
    end

    task :by_project_string_key => :environment do

      if ENV['THREADS'].present?
        thread_pool_size = ENV['THREADS'].to_i
        puts "Number of threads: #{thread_pool_size}"
      else
        thread_pool_size = 1
        puts "Number of threads: #{thread_pool_size}"
      end

      if ENV['START_AT'].present?
        start_at = ENV['START_AT'].to_i
        puts 'Starting at: ' + start_at.to_s
      else
        start_at = 0
      end

      list_of_pids = []
      found_results = true
      page = 1
      per_page = 1000

      start_time = Time.now

      while found_results do
        search_results = DigitalObject::Base.search(
          {
            'page' => page,
            'per_page' => per_page,
            'f' => {
              'project_string_key_sim' => ['durst']
            },
            'fl' => 'pid'
          },
          false
        )

        page += 1

        if search_results['total'] > 0 && search_results['results'].length > 0
          list_of_pids += search_results['results'].map{ |result| result['pid'] }
        else
          found_results = false
        end
      end

      puts "Found #{list_of_pids.length} results.  Took #{Time.now - start_time} seconds."
      puts 'Publishing pids...'

      pool = Thread.pool(thread_pool_size)
      counter = 0
      mutex = Mutex.new
      total = list_of_pids.length
      start_time = Time.now

      puts 'Eager loading application classes to avoid multithreading issues...'
      # We run into autoloading issues when running in a multithreaded context,
      # so we'll have the application eager load all classes now.
      Rails.application.eager_load!
      puts 'Eager load done.'

      puts 'list_of_pids size: ' + list_of_pids.length.to_s

      # Because of other gem autoloading issues, we also want to publish the first item
      # on the main thread before using a thread pool for
      # other items, and remove it from the list_of_pids using Array#shift.

      first_pid = list_of_pids.shift # remove first element
      publish_object_by_pid(first_pid)
      counter += 1
      print "Published #{counter} of #{total} | #{Time.now - start_time} seconds" + "\r"

      list_of_pids.each do |pid|
        pool.process {
          publish_object_by_pid(pid)
          mutex.synchronize do
            counter += 1
            print "Published #{counter} of #{total} | #{Time.now - start_time} seconds" + "\r"
          end
        }
      end


      pool.shutdown

      puts "\nDone!"

    end

  end

end
