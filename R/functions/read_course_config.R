#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                 Read course config
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

read_course_config <- function(path = "config/course.yml") {
  config <-
    read_utf8_yaml(path = path)

  if (!identical(config$schema_version, 1L)) {
    cli::cli_abort("Course configuration schema_version must equal 1.")
  }
  if (is.null(config$current_year) || is.null(config$lessons)) {
    cli::cli_abort("Course configuration is missing current_year or lessons.")
  }

  return(config)
}
