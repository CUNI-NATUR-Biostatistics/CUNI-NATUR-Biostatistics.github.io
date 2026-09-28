# frozen_string_literal: true

require "minitest/autorun"
require "socket"

require_relative "../../.github/actions/verify-lesson-pages/verify_lesson_pages"

class VerifyLessonPagesTest < Minitest::Test
  def marker
    {
      "lesson" => "L01",
      "current_tag" => "L01-v1.2.0-20260928",
      "source_sha" => "abc123",
      "run_id" => "456",
      "run_attempt" => "2"
    }
  end

  def test_marker_requires_the_exact_deployment_identity
    assert LessonPagesVerifier.marker_matches?(marker, marker.merge("extra" => true))
    refute LessonPagesVerifier.marker_matches?(marker.merge("run_id" => "older"), marker)
    refute LessonPagesVerifier.marker_matches?(nil, marker)
  end

  def test_manifest_requires_the_expected_release_tag
    assert LessonPagesVerifier.manifest_matches?(
      { "tag" => "L01-v1.2.0-20260928" },
      "L01-v1.2.0-20260928"
    )
    refute LessonPagesVerifier.manifest_matches?(
      { "tag" => "L01-v1.1.0-20260923" },
      "L01-v1.2.0-20260928"
    )
  end

  def test_positive_integer_validation
    assert_equal 3, LessonPagesVerifier.parse_positive_integer("3", "attempts")
    assert_equal 0, LessonPagesVerifier.parse_positive_integer(
      "0",
      "interval",
      allow_zero: true
    )
    assert_raises(ArgumentError) do
      LessonPagesVerifier.parse_positive_integer("0", "attempts")
    end
  end

  def test_marker_path_is_unique_to_phase_and_attempt
    assert_equal(
      "deployment-checks/456-2-initial-01.json",
      LessonPagesVerifier.marker_path(marker, "initial", 1)
    )
    assert_equal(
      "deployment-checks/456-2-retry-12.json",
      LessonPagesVerifier.marker_path(marker, "retry", 12)
    )
    assert_raises(ArgumentError) do
      LessonPagesVerifier.marker_path(marker, "unknown", 1)
    end
  end

  def test_verify_once_checks_the_unique_marker_and_both_stable_manifests
    responses = {
      "/deployment-checks/456-2-initial-01.json" => marker,
      "/current/manifest.json" => { "tag" => marker.fetch("current_tag") },
      "/releases/L01-v1.2.0-20260928/manifest.json" => {
        "tag" => marker.fetch("current_tag")
      }
    }

    with_json_server(responses, requests: 3) do |base_uri|
      LessonPagesVerifier.verify_once(base_uri, marker, "initial", 1)
    end
  end

  def test_verify_once_rejects_a_stale_deployment_before_checking_manifests
    stale_marker = marker.merge("run_id" => "455")
    responses = {
      "/deployment-checks/456-2-initial-01.json" => stale_marker
    }

    with_json_server(responses, requests: 1) do |base_uri|
      error = assert_raises(RuntimeError) do
        LessonPagesVerifier.verify_once(base_uri, marker, "initial", 1)
      end
      assert_includes error.message, "deployment marker does not match"
    end
  end

  private

  def with_json_server(responses, requests:)
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    thread = Thread.new do
      requests.times do
        socket = server.accept
        request_line = socket.gets
        path = request_line.split[1].split("?", 2).first
        loop do
          line = socket.gets
          break if line.nil? || line == "\r\n"
        end
        body = responses[path]
        if body
          json = JSON.generate(body)
          socket.write(
            "HTTP/1.1 200 OK\r\n" \
            "Content-Type: application/json\r\n" \
            "Content-Length: #{json.bytesize}\r\n" \
            "Connection: close\r\n\r\n" \
            "#{json}"
          )
        else
          socket.write(
            "HTTP/1.1 404 Not Found\r\n" \
            "Content-Length: 0\r\n" \
            "Connection: close\r\n\r\n"
          )
        end
        socket.close
      end
    ensure
      server.close
    end

    yield URI("http://127.0.0.1:#{port}/")
  ensure
    thread&.join
  end
end
