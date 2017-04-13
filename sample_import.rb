require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'json'
require 'work_queue'
require 'retries'

unless ENV['API_KEY']
  abort 'Must set API_KEY'
end

class AmplitudeImporter
  API_KEY = ENV['API_KEY'].freeze
  ENDPOINT = 'https://api.amplitude.com/httpapi'.freeze

  def run(filename)
    submitted_count = 0
    logger.info "Processing #{filename}"
    uri = URI.parse(ENDPOINT)
    File.open(filename) do |f|
      f.each_line.lazy.each_slice(10) do |lines|
        json_lines = lines.compact.map do |line|
          JSON.parse(line.strip).tap do |json|
            json['time'] = Time.parse(json['event_time']).to_f
            json['carrier'] = json['device_carrier']
            json['insert_id'] = [
              json['user_id'],
              json['event_id']
            ].map(&:to_s).join('-')
          end
        end

        queue.enqueue_b do
          with_retries(max_tries: 10) do
            response = Net::HTTP.post_form(
              uri,
              { api_key: API_KEY,
                event: JSON.generate(json_lines) })
            if response.code == '200'
              logger.info "Response completed successfully"
            else
              msg = "Response failed with #{response.code}: #{response.message}"
              logger.info msg
              raise msg
            end
          end
        end
        submitted_count += json_lines.size
        logger.info "Submitted batch of #{json_lines.size} events (#{submitted_count} total)"
      end
    end

    logger.info "Waiting for queue to finish..."
    queue.join

    logger.info "Found #{submitted_count} events for importing"
  end

  private

  def queue
    @queue ||= WorkQueue.new(100)
  end

  def logger
    @logger ||= Logger.new(STDERR)
  end
end

AmplitudeImporter.new.run(ARGV[0])
