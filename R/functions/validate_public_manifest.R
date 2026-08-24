#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#              Validate public manifest
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

validate_public_manifest <- function(manifest, lesson_id) {
  vec_required <-
    c(
      "schema_version",
      "course",
      "lesson",
      "academic_year",
      "title",
      "tag",
      "resources"
    )

  vec_missing <-
    setdiff(vec_required, names(manifest))

  if (length(vec_missing) > 0L) {
    cli::cli_abort(
      paste0(
        "Manifest for {.val {lesson_id}} misses: ",
        "{paste(vec_missing, collapse = ', ')}."
      )
    )
  }
  if (!identical(manifest$schema_version, 1L)) {
    cli::cli_abort(
      "Manifest schema_version for {.val {lesson_id}} must equal 1."
    )
  }
  if (!identical(manifest$lesson, lesson_id)) {
    cli::cli_abort("Manifest lesson does not match {.val {lesson_id}}.")
  }

  tag_pattern <-
    paste0(
      "^",
      lesson_id,
      "-v[0-9]+\\.[0-9]+\\.[0-9]+-[0-9]{8}(-moodle)?$"
    )
  if (!grepl(tag_pattern, manifest$tag)) {
    cli::cli_abort("Manifest tag for {.val {lesson_id}} has an invalid format.")
  }

  for (
    group_name in c("learning", "presentation")
    ) {
    group <- manifest$resources[[group_name]]
    if (is.null(group)) {
      cli::cli_abort("Manifest for {.val {lesson_id}} misses {group_name}.")
    }
    for (
      format_name in c("html", "pdf", "source")
      ) {
      if (is.null(group[[format_name]]$href)) {
        cli::cli_abort(
          paste0(
            "Manifest for {.val {lesson_id}} misses ",
            "{group_name}.{format_name}.href."
          )
        )
      }
    }
  }

  return(invisible(TRUE))
}
