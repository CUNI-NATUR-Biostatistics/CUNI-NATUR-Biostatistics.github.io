# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "pathname"
require "tmpdir"
require "yaml"

SCRIPT = Pathname.new(__dir__).join(
  "..",
  "..",
  ".github",
  "actions",
  "assemble-lesson-pages",
  "assemble_lesson_pages.rb"
).realpath

class AssembleLessonPagesTest < Minitest::Test
  def write_preview(root, presentation_path: "Presentation/presentation.html")
    FileUtils.mkdir_p(root + "Learning_materials")
    FileUtils.mkdir_p(root + "Presentation")
    File.write(root + "Learning_materials/skripta.html", "preview learning")
    File.write(root + "Presentation/presentation.html", "preview presentation")
    manifest = {
      "schema_version" => 1,
      "course" => "MB120P163",
      "lesson" => "L01",
      "academic_year" => "2026-27",
      "title" => "Preview lesson",
      "resources" => {
        "learning" => { "html" => "Learning_materials/skripta.html" },
        "presentation" => { "html" => presentation_path }
      }
    }
    File.write(root + "website-release.yml", YAML.dump(manifest))
  end

  def write_release_bundle(root, bundles, tag: "L01-v1.0.0-20260824")
    source = root + "release-source"
    bundle = source + "web-materials-#{tag}"
    FileUtils.mkdir_p(bundle + "learning")
    FileUtils.mkdir_p(bundle + "presentation")
    File.write(bundle + "learning/index.html", "stable learning")
    File.write(bundle + "presentation/index.html", "stable presentation")
    File.write(
      bundle + "manifest.json",
      JSON.pretty_generate(
        "tag" => tag,
        "lesson" => "L01",
        "academic_year" => "2026-27",
        "title" => "Stable lesson"
      )
    )
    destination = bundles + tag
    FileUtils.mkdir_p(destination)
    zip_path = destination + "web-materials-#{tag}.zip"
    success = system(
      "zip",
      "-q",
      "-r",
      zip_path.to_s,
      bundle.basename.to_s,
      chdir: source.to_s
    )
    raise "Could not create release fixture" unless success
  end

  def run_assembler(root, require_releases: false)
    output = root + "lesson-site"
    github_output = root + "github-output.txt"
    stdout, stderr, status = Open3.capture3(
      { "GITHUB_OUTPUT" => github_output.to_s },
      "ruby",
      SCRIPT.to_s,
      (root + "bundles").to_s,
      output.to_s,
      "website-release.yml",
      require_releases.to_s,
      chdir: root.to_s
    )
    [output, github_output, stdout, stderr, status]
  end

  def test_preview_only_site_uses_learning_materials_as_entry
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      write_preview(root)

      output, github_output, _stdout, stderr, status = run_assembler(root)

      assert status.success?, stderr
      assert_equal "preview learning", File.read(output + "preview/learning/index.html")
      assert_equal "preview presentation", File.read(output + "preview/presentation/index.html")
      assert_includes File.read(output + "preview/index.html"), "url=learning/index.html"
      assert_includes File.read(output + "index.html"), "url=preview/"
      refute_predicate output + "current", :exist?
      assert_includes File.read(github_output), "current_tag=\n"
    end
  end

  def test_combined_site_preserves_release_and_preview_channels
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      bundles = root + "bundles"
      write_preview(root)
      write_release_bundle(root, bundles)

      output, github_output, _stdout, stderr, status =
        run_assembler(root, require_releases: true)

      assert status.success?, stderr
      assert_equal "preview learning", File.read(output + "preview/learning/index.html")
      assert_equal "stable learning", File.read(output + "current/learning/index.html")
      assert_equal "stable presentation", File.read(output + "current/presentation/index.html")
      assert_includes File.read(output + "current/index.html"), "url=learning/index.html"
      assert_includes File.read(output + "releases/L01-v1.0.0-20260824/index.html"), "url=learning/index.html"
      assert_includes File.read(output + "index.html"), "url=current/"
      assert_includes File.read(github_output), "current_tag=L01-v1.0.0-20260824"
    end
  end

  def test_missing_preview_html_fails_before_deployment_artifact_is_built
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      write_preview(root, presentation_path: "Presentation/missing.html")

      output, _github_output, _stdout, stderr, status = run_assembler(root)

      refute status.success?
      assert_includes stderr, "Preview file does not exist"
      refute_predicate output, :exist?
    end
  end

  def test_preview_path_cannot_escape_repository
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      write_preview(root, presentation_path: "../outside.html")

      output, _github_output, _stdout, stderr, status = run_assembler(root)

      refute status.success?
      assert_includes stderr, "Preview path escapes the repository"
      refute_predicate output, :exist?
    end
  end
end
