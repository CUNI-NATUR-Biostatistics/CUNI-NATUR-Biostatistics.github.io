# frozen_string_literal: true

require "English"
require "cgi"
require "fileutils"
require "json"
require "pathname"
require "rubygems"
require "shellwords"
require "tmpdir"
require "yaml"

bundles_directory = Pathname.new(ARGV.fetch(0))
output_directory = Pathname.new(ARGV.fetch(1))
preview_manifest_path = Pathname.new(ARGV.fetch(2))
require_releases_text = ARGV.fetch(3)
repository_root = Pathname.new(Dir.pwd).realpath
tag_pattern = /\A(L\d{2})-v(\d+\.\d+\.\d+)-(\d{8})(?:-moodle)?\z/

abort_pages = lambda do |message|
  warn "ERROR: #{message}"
  exit 1
end

unless %w[true false].include?(require_releases_text)
  abort_pages.call("require-releases must be true or false")
end
require_releases = require_releases_text == "true"

require_text = lambda do |mapping, key, context|
  value = mapping[key]
  unless value.is_a?(String) && !value.strip.empty?
    abort_pages.call("#{context}.#{key} must be a non-empty string")
  end
  value.strip
end

resolve_preview_file = lambda do |path_text, extension|
  unless path_text.is_a?(String)
    abort_pages.call("Preview path must be a relative string")
  end
  relative_path = Pathname.new(path_text)
  if relative_path.absolute?
    abort_pages.call("Preview path must be relative: #{path_text}")
  end
  clean_path = relative_path.cleanpath
  if clean_path.each_filename.first == ".."
    abort_pages.call("Preview path escapes the repository: #{path_text}")
  end
  begin
    absolute_path = (repository_root + clean_path).realpath
  rescue Errno::ENOENT
    abort_pages.call("Preview file does not exist: #{path_text}")
  end
  prefix = repository_root.to_s + File::SEPARATOR
  unless absolute_path.to_s.start_with?(prefix) && absolute_path.file?
    abort_pages.call("Preview path is not a repository file: #{path_text}")
  end
  unless absolute_path.extname.downcase == extension
    abort_pages.call("Preview file must have extension #{extension}: #{path_text}")
  end
  absolute_path
end

write_redirect = lambda do |directory, target, title, link_text|
  FileUtils.mkdir_p(directory)
  File.write(
    directory + "index.html",
    <<~HTML
      <!doctype html>
      <html lang="cs">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta http-equiv="refresh" content="0; url=#{target}">
          <title>#{CGI.escapeHTML(title)}</title>
        </head>
        <body>
          <p><a href="#{target}">#{link_text}</a></p>
        </body>
      </html>
    HTML
  )
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

begin
  preview_manifest = YAML.safe_load_file(
    preview_manifest_path,
    permitted_classes: [],
    aliases: false
  )
rescue Errno::ENOENT
  abort_pages.call("Preview manifest does not exist: #{preview_manifest_path}")
rescue Psych::Exception => error
  abort_pages.call("Preview manifest is invalid YAML: #{error.message}")
end
unless preview_manifest.is_a?(Hash)
  abort_pages.call("Preview manifest must contain a YAML mapping")
end
unless preview_manifest["schema_version"] == 1
  abort_pages.call("Preview manifest schema_version must equal 1")
end

preview_lesson = require_text.call(preview_manifest, "lesson", "preview manifest")
preview_academic_year =
  require_text.call(preview_manifest, "academic_year", "preview manifest")
preview_title = require_text.call(preview_manifest, "title", "preview manifest")
unless preview_lesson.match?(/\AL\d{2}\z/)
  abort_pages.call("Preview lesson must use LXX format")
end

preview_resources = preview_manifest["resources"]
unless preview_resources.is_a?(Hash)
  abort_pages.call("Preview manifest resources must be a mapping")
end

preview_files = {}
%w[learning presentation].each do |group_name|
  group = preview_resources[group_name]
  unless group.is_a?(Hash)
    abort_pages.call("Preview resources.#{group_name} must be a mapping")
  end
  html_path = require_text.call(group, "html", "preview resources.#{group_name}")
  preview_files[group_name] = resolve_preview_file.call(html_path, ".html")
end

FileUtils.rm_rf(output_directory)
FileUtils.mkdir_p(output_directory + "releases")

preview_files.each do |group_name, source_path|
  destination = output_directory + "preview" + group_name + "index.html"
  FileUtils.mkdir_p(destination.dirname)
  FileUtils.cp(source_path, destination)
end
write_redirect.call(
  output_directory + "preview",
  "learning/index.html",
  "#{preview_title} - preview",
  "Otev&#345;&#237;t pracovn&#237; skripta"
)

zip_paths = bundles_directory.glob("**/web-materials-*.zip")
if zip_paths.empty? && require_releases
  abort_pages.call("No website release bundles were downloaded")
end

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
    unless lesson == preview_lesson
      abort_pages.call("Release #{tag} does not match preview lesson #{preview_lesson}")
    end

    destination = output_directory + "releases" + tag
    if destination.exist?
      abort_pages.call("Duplicate website bundle for #{tag}")
    end
    FileUtils.cp_r(manifests.first.dirname, destination)
    write_redirect.call(
      destination,
      "learning/index.html",
      manifest.fetch("title"),
      "Otev&#345;&#237;t vydan&#225; skripta"
    )
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

current = nil
unless releases.empty?
  lessons = releases.map { |release| release["lesson"] }.uniq
  unless lessons == [preview_lesson]
    abort_pages.call("Release bundles contain unexpected lessons: #{lessons.join(', ')}")
  end

  current = releases.max_by do |release|
    [release["academic_year"], release["date"], release["version"]]
  end
  FileUtils.cp_r(current["destination"], output_directory + "current")
end

root_target = current.nil? ? "preview/" : "current/"
write_redirect.call(
  output_directory,
  root_target,
  preview_title,
  "Otev&#345;&#237;t materi&#225;ly lekce"
)
File.write(output_directory + ".nojekyll", "")

github_output = ENV["GITHUB_OUTPUT"]
if github_output && !github_output.empty?
  File.open(github_output, "a") do |file|
    file.puts "current_tag=#{current.nil? ? '' : current['tag']}"
    file.puts "lesson=#{preview_lesson}"
    file.puts "academic_year=#{preview_academic_year}"
  end
end

current_message = current.nil? ? "no stable release" : "current is #{current['tag']}"
puts "Assembled preview and #{releases.length} releases; #{current_message}."
