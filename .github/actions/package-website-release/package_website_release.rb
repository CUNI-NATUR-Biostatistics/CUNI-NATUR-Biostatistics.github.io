# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "pathname"
require "yaml"

manifest_path = ARGV.fetch(0)
tag = ARGV.fetch(1)
output_directory = ARGV.fetch(2)
repository_root = Pathname.new(Dir.pwd).realpath
tag_pattern = /\A(L\d{2})-v\d+\.\d+\.\d+-\d{8}(?:-moodle)?\z/
year_pattern = /\A(\d{4})-(\d{2})\z/

abort_release = lambda do |message|
  warn "ERROR: #{message}"
  exit 1
end

require_text = lambda do |mapping, key, context|
  value = mapping[key]
  unless value.is_a?(String) && !value.strip.empty?
    abort_release.call("#{context}.#{key} must be a non-empty string")
  end
  value.strip
end

resolve_public_file = lambda do |path_text|
  unless path_text.is_a?(String)
    abort_release.call("Public path must be a relative string")
  end
  relative_path = Pathname.new(path_text)
  if relative_path.absolute?
    abort_release.call("Public path must be relative: #{path_text}")
  end
  clean_path = relative_path.cleanpath
  if clean_path.each_filename.first == ".."
    abort_release.call("Public path escapes the repository: #{path_text}")
  end
  begin
    absolute_path = (repository_root + clean_path).realpath
  rescue Errno::ENOENT
    abort_release.call("Public file does not exist: #{path_text}")
  end
  prefix = repository_root.to_s + File::SEPARATOR
  unless absolute_path.to_s.start_with?(prefix) && absolute_path.file?
    abort_release.call("Public path is not a repository file: #{path_text}")
  end
  [clean_path.to_s.tr("\\", "/"), absolute_path]
end

tag_match = tag_pattern.match(tag)
abort_release.call("Invalid release tag: #{tag}") unless tag_match

manifest = YAML.safe_load_file(
  manifest_path,
  permitted_classes: [],
  aliases: false
)
unless manifest.is_a?(Hash)
  abort_release.call("#{manifest_path} must contain a YAML mapping")
end
unless manifest["schema_version"] == 1
  abort_release.call("schema_version must equal 1")
end

course = require_text.call(manifest, "course", "manifest")
lesson = require_text.call(manifest, "lesson", "manifest")
academic_year = require_text.call(manifest, "academic_year", "manifest")
title = require_text.call(manifest, "title", "manifest")
subtitle = manifest.fetch("subtitle", "").to_s.strip
unless lesson == tag_match[1]
  abort_release.call("Manifest lesson does not match tag #{tag}")
end

year_match = year_pattern.match(academic_year)
unless year_match
  abort_release.call("academic_year must use YYYY-YY, for example 2026-27")
end
expected_end = (year_match[1].to_i + 1).to_s[-2, 2]
unless year_match[2] == expected_end
  abort_release.call("academic_year must name consecutive years")
end

resources = manifest["resources"]
abort_release.call("resources must be a mapping") unless resources.is_a?(Hash)

required_groups = {
  "learning" => {
    "html" => ["learning/index.html", ".html"],
    "pdf" => ["learning/skripta.pdf", ".pdf"],
    "source" => ["source/skripta.qmd", ".qmd"]
  },
  "presentation" => {
    "html" => ["presentation/index.html", ".html"],
    "pdf" => ["presentation/presentation.pdf", ".pdf"],
    "source" => ["source/presentation.qmd", ".qmd"]
  }
}

output_root = Pathname.new(output_directory)
asset_name = "web-materials-#{tag}.zip"
bundle_root = output_root + "web-materials-#{tag}"
FileUtils.rm_rf(bundle_root)
FileUtils.mkdir_p(bundle_root)

public_manifest = {
  "schema_version" => 1,
  "course" => course,
  "lesson" => lesson,
  "academic_year" => academic_year,
  "title" => title,
  "subtitle" => subtitle,
  "tag" => tag,
  "repository" => ENV.fetch(
    "GITHUB_REPOSITORY",
    "CUNI-NATUR-Biostatistics/#{lesson}"
  ),
  "resources" => {},
  "checksums" => []
}

copy_resource = lambda do |source_path, destination_path|
  FileUtils.mkdir_p(destination_path.dirname)
  FileUtils.cp(source_path, destination_path)
  public_manifest["checksums"] << {
    "path" => destination_path
      .relative_path_from(bundle_root)
      .to_s
      .tr("\\", "/"),
    "sha256" => Digest::SHA256.file(destination_path).hexdigest,
    "bytes" => destination_path.size
  }
end

required_groups.each do |group_name, fields|
  source_group = resources[group_name]
  unless source_group.is_a?(Hash)
    abort_release.call("resources.#{group_name} must be a mapping")
  end
  public_manifest["resources"][group_name] = {}

  fields.each do |field_name, (destination, extension)|
    context = "resources.#{group_name}"
    source_text = require_text.call(source_group, field_name, context)
    clean_source, source_path = resolve_public_file.call(source_text)
    unless source_path.extname.downcase == extension
      abort_release.call("#{source_text} must have extension #{extension}")
    end
    copy_resource.call(source_path, bundle_root + destination)
    public_manifest["resources"][group_name][field_name] = {
      "href" => destination,
      "source_path" => clean_source
    }
  end
end

{
  "exercises" => "code",
  "data" => "data",
  "extras" => "extras"
}.each do |group_name, destination_directory|
  entries = resources.fetch(group_name, [])
  unless entries.is_a?(Array)
    abort_release.call("resources.#{group_name} must be a list")
  end
  public_manifest["resources"][group_name] = []
  used_names = {}

  entries.each_with_index do |entry, index|
    unless entry.is_a?(Hash)
      abort_release.call(
        "resources.#{group_name}[#{index}] must be a mapping"
      )
    end
    context = "resources.#{group_name}[#{index}]"
    label = require_text.call(entry, "label", context)
    source_text = require_text.call(entry, "path", context)
    clean_source, source_path = resolve_public_file.call(source_text)
    filename = source_path.basename.to_s
    if used_names[filename]
      abort_release.call(
        "Duplicate filename in resources.#{group_name}: #{filename}"
      )
    end
    used_names[filename] = true
    destination = "#{destination_directory}/#{filename}"
    copy_resource.call(source_path, bundle_root + destination)
    public_manifest["resources"][group_name] << {
      "label" => label,
      "href" => destination,
      "source_path" => clean_source
    }
  end
end

File.write(
  bundle_root + "manifest.json",
  JSON.pretty_generate(public_manifest) + "\n"
)
FileUtils.mkdir_p(output_root)
asset_path = output_root + asset_name
FileUtils.rm_f(asset_path)

Dir.chdir(output_root) do
  success = system(
    "zip",
    "-q",
    "-r",
    asset_name,
    bundle_root.basename.to_s
  )
  unless success
    abort_release.call("zip failed while creating #{asset_name}")
  end
end

github_output = ENV["GITHUB_OUTPUT"]
if github_output && !github_output.empty?
  File.open(github_output, "a") do |file|
    file.puts "asset_path=#{asset_path}"
    file.puts "asset_name=#{asset_name}"
    file.puts "lesson=#{lesson}"
    file.puts "academic_year=#{academic_year}"
  end
end

puts "Created #{asset_path} for #{lesson} (#{academic_year})."
