# frozen_string_literal: true

require "json"
require "net/http"
require "pathname"
require "uri"

module LessonPagesVerifier
  module_function

  MARKER_KEYS = %w[lesson current_tag source_sha run_id run_attempt].freeze
  MAX_ATTEMPTS = 12

  def parse_positive_integer(text, name, allow_zero: false)
    value = Integer(text, 10)
    minimum = allow_zero ? 0 : 1
    raise ArgumentError, "#{name} must be at least #{minimum}" if value < minimum

    value
  rescue ArgumentError
    raise ArgumentError, "#{name} must be an integer#{allow_zero ? ' >= 0' : ' > 0'}"
  end

  def normalized_marker(value)
    return nil unless value.is_a?(Hash)

    MARKER_KEYS.to_h { |key| [key, value[key]] }
  end

  def marker_matches?(actual, expected)
    normalized_marker(actual) == normalized_marker(expected)
  end

  def manifest_matches?(actual, expected_tag)
    actual.is_a?(Hash) && actual["tag"] == expected_tag
  end

  def fetch_json(uri, redirects_remaining: 3)
    request = Net::HTTP::Get.new(uri)
    request["Cache-Control"] = "no-cache"
    request["Pragma"] = "no-cache"
    request["User-Agent"] = "lesson-pages-verifier"

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 10,
      read_timeout: 30
    ) { |http| http.request(request) }

    if response.is_a?(Net::HTTPRedirection)
      raise "Too many redirects for #{uri}" if redirects_remaining.zero?

      location = response["location"]
      raise "Redirect from #{uri} did not include a location" unless location

      return fetch_json(
        URI.join(uri.to_s, location),
        redirects_remaining: redirects_remaining - 1
      )
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "#{uri} returned HTTP #{response.code}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => error
    raise "#{uri} did not return valid JSON: #{error.message}"
  end

  def cache_busted_uri(base_uri, relative_path, attempt)
    uri = URI.join(base_uri.to_s, relative_path)
    uri.query = URI.encode_www_form(
      "verify_run" => ENV.fetch("GITHUB_RUN_ID", "local"),
      "verify_attempt" => attempt,
      "nonce" => Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
    )
    uri
  end

  def marker_path(expected_marker, phase, attempt)
    unless %w[initial retry].include?(phase)
      raise ArgumentError, "phase must be initial or retry"
    end

    run_id = expected_marker.fetch("run_id")
    run_attempt = expected_marker.fetch("run_attempt")
    [run_id, run_attempt].each do |value|
      unless value.is_a?(String) && value.match?(/\A[0-9]+\z/)
        raise ArgumentError, "deployment marker run identifiers must be numeric"
      end
    end

    format(
      "deployment-checks/%s-%s-%s-%02d.json",
      run_id,
      run_attempt,
      phase,
      attempt
    )
  end

  def verify_once(base_uri, expected_marker, phase, attempt)
    remote_marker = fetch_json(
      cache_busted_uri(
        base_uri,
        marker_path(expected_marker, phase, attempt),
        attempt
      )
    )
    unless marker_matches?(remote_marker, expected_marker)
      raise "deployment marker does not match the current workflow artifact"
    end

    expected_tag = expected_marker["current_tag"]
    return if expected_tag.nil? || expected_tag.empty?

    current_manifest = fetch_json(
      cache_busted_uri(base_uri, "current/manifest.json", attempt)
    )
    immutable_manifest = fetch_json(
      cache_busted_uri(
        base_uri,
        "releases/#{URI.encode_www_form_component(expected_tag)}/manifest.json",
        attempt
      )
    )

    unless manifest_matches?(current_manifest, expected_tag)
      raise "current manifest does not identify #{expected_tag}"
    end
    unless manifest_matches?(immutable_manifest, expected_tag)
      raise "immutable manifest does not identify #{expected_tag}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  base_url, site_directory_text, attempts_text, interval_text, phase = ARGV
  unless phase
    abort "Usage: verify_lesson_pages.rb BASE_URL SITE_DIRECTORY ATTEMPTS INTERVAL_SECONDS PHASE"
  end

  begin
    base_uri = URI.parse(base_url.end_with?("/") ? base_url : "#{base_url}/")
    unless %w[http https].include?(base_uri.scheme) && base_uri.host
      raise ArgumentError, "base URL must use http or https"
    end
    attempts = LessonPagesVerifier.parse_positive_integer(attempts_text, "attempts")
    if attempts > LessonPagesVerifier::MAX_ATTEMPTS
      raise ArgumentError, "attempts must not exceed #{LessonPagesVerifier::MAX_ATTEMPTS}"
    end
    interval_seconds = LessonPagesVerifier.parse_positive_integer(
      interval_text,
      "interval-seconds",
      allow_zero: true
    )
  rescue ArgumentError, URI::InvalidURIError => error
    abort "ERROR: #{error.message}"
  end

  marker_path = Pathname.new(site_directory_text) + "deployment.json"
  begin
    expected_marker = JSON.parse(marker_path.read)
  rescue Errno::ENOENT, JSON::ParserError => error
    abort "ERROR: Could not read deployment marker #{marker_path}: #{error.message}"
  end

  last_error = nil
  1.upto(attempts) do |attempt|
    begin
      LessonPagesVerifier.verify_once(base_uri, expected_marker, phase, attempt)
      puts "Verified lesson Pages deployment on attempt #{attempt}."
      exit 0
    rescue StandardError => error
      last_error = error
      warn "Attempt #{attempt}/#{attempts}: #{error.message}"
      sleep interval_seconds if attempt < attempts
    end
  end

  abort "ERROR: Lesson Pages did not publish the expected artifact: #{last_error.message}"
end
