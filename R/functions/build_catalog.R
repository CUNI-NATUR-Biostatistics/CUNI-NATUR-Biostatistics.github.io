#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                    Build catalog
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

build_catalog <- function(config) {
  list_years <- list()

  for (
    year_config in config$years
    ) {
    offering <-
      yaml::read_yaml(
        file = year_config$offering,
        fileEncoding = "UTF-8"
      )

    if (!identical(offering$academic_year, year_config$slug)) {
      cli::cli_abort(
        "Offering file does not match academic year {.val {year_config$slug}}."
      )
    }

    list_lessons <- list()
    for (
      lesson_config in config$lessons
      ) {
      lesson_id <- lesson_config$id
      release_tag <- offering$releases[[lesson_id]]
      if (!isTRUE(offering$frozen)) {
        release_tag <- NULL
      }
      manifest_url <-
        get_manifest_url(
          base_url = config$pages_base_url,
          lesson_id = lesson_id,
          release_tag = release_tag
        )
      manifest <-
        read_public_manifest(url = manifest_url)

      if (is.null(manifest)) {
        list_lessons[[lesson_id]] <-
          list(
            id = lesson_id,
            title = lesson_config$title,
            subtitle = "",
            status = "preparing",
            release = NULL,
            release_year = NULL,
            material_base_url = NULL,
            manifest = NULL
          )
        next
      }

      validate_public_manifest(
        manifest = manifest,
        lesson_id = lesson_id
      )

      if (!is.null(release_tag) && !identical(manifest$tag, release_tag)) {
        cli::cli_abort(
          "Pinned release for {.val {lesson_id}} returned a different tag."
        )
      }
      if (isTRUE(offering$frozen) && is.null(release_tag)) {
        cli::cli_abort(
          paste0(
            "Frozen offering {.val {year_config$slug}} has no pin for ",
            "{.val {lesson_id}}."
          )
        )
      }

      status <- "published"
      if (!identical(manifest$academic_year, year_config$slug)) {
        if (manifest$academic_year > year_config$slug) {
          cli::cli_abort(
            paste0(
              "{.val {lesson_id}} returned material newer than offering ",
              "{.val {year_config$slug}}."
            )
          )
        }
        status <- "inherited"
      }

      list_lessons[[lesson_id]] <-
        list(
          id = lesson_id,
          title = manifest$title,
          subtitle = manifest$subtitle,
          status = status,
          release = manifest$tag,
          release_year = manifest$academic_year,
          material_base_url = get_material_base_url(
            base_url = config$pages_base_url,
            lesson_id = lesson_id,
            release_tag = release_tag
          ),
          manifest = manifest
        )
    }

    list_years[[year_config$slug]] <-
      list(
        slug = year_config$slug,
        label = year_config$label,
        frozen = isTRUE(offering$frozen),
        lessons = list_lessons
      )
  }

  res_catalog <-
    list(
      schema_version = 1L,
      generated_at = format(
        Sys.time(),
        tz = "UTC",
        usetz = TRUE
      ),
      current_year = config$current_year,
      years = list_years
    )

  return(res_catalog)
}
