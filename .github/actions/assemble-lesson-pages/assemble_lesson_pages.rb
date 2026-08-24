# frozen_string_literal: true

require "English"
require "fileutils"
require "json"
require "pathname"
require "rubygems"
require "shellwords"
require "tmpdir"

bundles_directory = Pathname.new(ARGV.fetch(0))
output_directory = Pathname.new(ARGV.fetch(1))
tag_pattern = /\A(L\d{2})-v(\d+\.\d+\.\d+)-(\d{8})(?:-moodle)?\z/

abort_pages = lambda do |message|
  warn "ERROR: #{message}"
  exit 1
end

safe_zip = lambda do |zip_path|
  command = "unzip -Z1 #{Shellwords.escape(zip_path.to_s)}"
  entries = `#{command}`.lines.map(&:strip)
  next false unless $CHILD_STATUS.success?

  entries.all? do |entry|
    path = Pathname.new(entry)
    !path.absolute? && path.cleanpath.each_filename.first != ".."
  end
end

zip_paths = bundles_directory.glob("**/web-materials-*.zip")
if zip_paths.empty?
  abort_pages.call("No website release bundles were downloaded")
end

FileUtils.rm_rf(output_directory)
FileUtils.mkdir_p(output_directory + "releases")
releases = []

zip_paths.each do |zip_path|
  unless safe_zip.call(zip_path)
    abort_pages.call("Unsafe paths found in #{zip_path}")
  end

  Dir.mktmpdir("lesson-pages") do |temporary_directory|
    success = system(
      "unzip",
      "-q",
      zip_path.to_s,
      "-d",
      temporary_directory
    )
    abort_pages.call("Could not extract #{zip_path}") unless success

    manifests = Pathname.new(temporary_directory).glob("*/manifest.json")
    unless manifests.length == 1
      abort_pages.call("Expected one manifest.json in #{zip_path}")
    end
    manifest = JSON.parse(manifests.first.read)
    tag = manifest.fetch("tag")
    lesson = manifest.fetch("lesson")
    academic_year = manifest.fetch("academic_year")
    tag_match = tag_pattern.match(tag)
    abort_pages.call("Invalid tag in #{zip_path}: #{tag}") unless tag_match
    unless lesson == tag_match[1]
      abort_pages.call("Lesson does not match tag in #{zip_path}")
    end

    destination = output_directory + "releases" + tag
    if destination.exist?
      abort_pages.call("Duplicate website bundle for #{tag}")
    end
    FileUtils.cp_r(manifests.first.dirname, destination)
    releases << {
      "tag" => tag,
      "lesson" => lesson,
      "academic_year" => academic_year,
      "version" => Gem::Version.new(tag_match[2]),
      "date" => tag_match[3],
      "destination" => destination,
      "manifest" => manifest
    }
  end
end

lessons = releases.map { |release| release["lesson"] }.uniq
unless lessons.length == 1
  abort_pages.call(
    "Bundles contain more than one lesson: #{lessons.join(', ')}"
  )
end

current = releases.max_by do |release|
  [release["academic_year"], release["date"], release["version"]]
end

FileUtils.cp_r(current["destination"], output_directory + "current")
File.write(output_directory + ".nojekyll", "")
File.write(
  output_directory + "index.html",
  <<~HTML
    <!doctype html>
    <html lang="cs">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="refresh" content="0; url=current/presentation/index.html">
        <title>#{current.fetch("manifest").fetch("title")}</title>
      </head>
      <body>
        <p><a href="current/presentation/index.html">Otev&#345;&#237;t aktu&#225;ln&#237; prezentaci</a></p>
      </body>
    </html>
  HTML
)

github_output = ENV["GITHUB_OUTPUT"]
if github_output && !github_output.empty?
  File.open(github_output, "a") do |file|
    file.puts "current_tag=#{current['tag']}"
    file.puts "lesson=#{current['lesson']}"
    file.puts "academic_year=#{current['academic_year']}"
  end
end

puts "Assembled #{releases.length} releases; current is #{current['tag']}."
