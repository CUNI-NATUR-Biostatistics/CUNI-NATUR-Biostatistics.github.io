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

  vec_lesson_ids <- character()
  for (
    lesson_index in seq_along(config$lessons)
    ) {
    lesson <- config$lessons[[lesson_index]]
    if (
      is.null(lesson$id) ||
        !is.character(lesson$id) ||
        length(lesson$id) != 1L ||
        !nzchar(lesson$id)
    ) {
      cli::cli_abort("Every configured lesson must have one non-empty id.")
    }
    if (lesson$id %in% vec_lesson_ids) {
      cli::cli_abort("Configured lesson ids must be unique.")
    }
    vec_lesson_ids <- c(vec_lesson_ids, lesson$id)

    placement <- lesson$placement
    if (is.null(placement)) {
      placement <- "materials"
    }
    if (
      !is.character(placement) ||
        length(placement) != 1L ||
        !placement %in% c("materials", "schedule")
    ) {
      cli::cli_abort(
        "Lesson {.val {lesson$id}} placement must be materials or schedule."
      )
    }

    repository_link <- lesson$repository_link
    if (is.null(repository_link)) {
      repository_link <- TRUE
    }
    if (
      !is.logical(repository_link) ||
        length(repository_link) != 1L ||
        is.na(repository_link)
    ) {
      cli::cli_abort(
        "Lesson {.val {lesson$id}} repository_link must be true or false."
      )
    }

    config$lessons[[lesson_index]]$placement <- placement
    config$lessons[[lesson_index]]$repository_link <- repository_link
  }

  return(config)
}
