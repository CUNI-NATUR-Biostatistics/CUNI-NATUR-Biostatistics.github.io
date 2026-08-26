#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#              Freeze academic offering
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

source("R/functions/read_utf8_yaml.R")
source("R/functions/read_course_config.R")
source("R/functions/read_catalog.R")
source("R/functions/make_placeholder_catalog.R")

config <-
  read_course_config()
catalog <-
  read_catalog(config = config)
current_year <- catalog$years[[config$current_year]]

vec_unpublished <- character()
list_releases <- list()
for (
  lesson in current_year$lessons
  ) {
  if (is.null(lesson$release)) {
    vec_unpublished <-
      c(vec_unpublished, lesson$id)
  } else {
    list_releases[[lesson$id]] <- lesson$release
  }
}

if (length(vec_unpublished) > 0L) {
  cli::cli_abort(
    paste0(
      "Cannot freeze: no published release for ",
      "{paste(vec_unpublished, collapse = ', ')}."
    )
  )
}

year_config <- NULL
for (
  candidate_year in config$years
  ) {
  if (identical(candidate_year$slug, config$current_year)) {
    year_config <- candidate_year
    break
  }
}
if (is.null(year_config)) {
  cli::cli_abort("Current year is missing from the year configuration.")
}

offering <-
  read_utf8_yaml(path = year_config$offering)
required_content <- c("schedule", "assessment", "team")
if (
  is.null(offering$content) ||
    !all(required_content %in% names(offering$content))
) {
  cli::cli_abort("Cannot freeze: semester snapshot content is incomplete.")
}

content_hashes <- list()
for (
  content_name in required_content
  ) {
  content_path <- offering$content[[content_name]]
  if (!file.exists(content_path)) {
    cli::cli_abort(
      "Cannot freeze: semester content {.path {content_path}} is missing."
    )
  }
  content_hashes[[content_name]] <-
    unname(tools::md5sum(content_path))
}
offering$frozen <- TRUE
offering$releases <- list_releases
offering$content_hashes <- content_hashes

connection <-
  file(
    description = year_config$offering,
    open = "w",
    encoding = "UTF-8"
  )
on.exit(close(connection), add = TRUE)
yaml::write_yaml(
  x = offering,
  file = connection
)

cli::cli_inform(
  paste0(
    "Froze offering {.val {config$current_year}}. ",
    "Review the resulting diff before publication."
  )
)
