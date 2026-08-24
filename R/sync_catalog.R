#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                 Synchronize catalog
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

source("R/functions/read_utf8_yaml.R")
source("R/functions/read_course_config.R")
source("R/functions/read_public_manifest.R")
source("R/functions/validate_public_manifest.R")
source("R/functions/get_manifest_url.R")
source("R/functions/get_material_base_url.R")
source("R/functions/build_catalog.R")

config <-
  read_course_config()
catalog <-
  build_catalog(config = config)

expected_lesson <- Sys.getenv("EXPECTED_LESSON")
expected_year <- Sys.getenv("EXPECTED_ACADEMIC_YEAR")
expected_tag <- Sys.getenv("EXPECTED_RELEASE_TAG")

if (nzchar(expected_lesson)) {
  current_year <- catalog$years[[config$current_year]]
  lesson <- current_year$lessons[[expected_lesson]]
  if (is.null(lesson) || !identical(lesson$release, expected_tag)) {
    cli::cli_abort(
      "The dispatched release is not available from the lesson Pages manifest."
    )
  }
  if (!identical(expected_year, lesson$release_year)) {
    cli::cli_abort(
      "The dispatched academic year does not match the public manifest."
    )
  }
}

jsonlite::write_json(
  x = catalog,
  path = "data/catalog.json",
  pretty = TRUE,
  auto_unbox = TRUE,
  null = "null"
)

cli::cli_inform("Synchronized the public lesson catalog.")
