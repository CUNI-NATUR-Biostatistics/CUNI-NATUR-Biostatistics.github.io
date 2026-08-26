#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                 Write site sources
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

write_site_sources <- function(catalog, output_directory = "_generated") {
  unlink(output_directory, recursive = TRUE, force = TRUE)
  dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)

  current_year <- catalog$years[[catalog$current_year]]
  if (is.null(current_year)) {
    cli::cli_abort("Catalog does not contain the configured current year.")
  }

  vec_current_cards <- character()
  for (
    lesson in current_year$lessons
    ) {
    vec_current_cards <-
      c(
        vec_current_cards,
        render_lesson_card(
          lesson = lesson,
          year_slug = current_year$slug
        )
      )
  }

  writeLines(
    text = c(
      paste0(
        "<div class=\"year-heading\"><h2>Akademick\u00fd rok ",
        current_year$label,
        paste0(
          "</h2><p>Obsah se m\u011bn\u00ed pouze po schv\u00e1len\u00e9m ",
          "release lekce.</p></div>"
        )
      )
    ),
    con = file.path(output_directory, "current-intro.md"),
    useBytes = TRUE
  )
  writeLines(
    text = c(
      "<div class=\"lesson-grid\">",
      vec_current_cards,
      "</div>"
    ),
    con = file.path(output_directory, "current-grid.md"),
    useBytes = TRUE
  )

  vec_archive <- character()
  for (
    year in catalog$years
    ) {
    year_directory <-
      file.path(output_directory, "rok", year$slug)
    dir.create(year_directory, recursive = TRUE, showWarnings = FALSE)
    vec_year_cards <- character()

    for (
      lesson in year$lessons
      ) {
      lesson_directory <-
        file.path(year_directory, lesson$id)
      dir.create(lesson_directory, recursive = TRUE, showWarnings = FALSE)
      writeLines(
        text = render_lesson_page(
          lesson = lesson,
          year = year
        ),
        con = file.path(lesson_directory, "index.qmd"),
        useBytes = TRUE
      )
      vec_year_cards <-
        c(
          vec_year_cards,
          render_lesson_card(
            lesson = lesson,
            year_slug = year$slug
          )
        )
    }

    writeLines(
      text = c(
        "---",
        paste0(
          "title: \"Akademick\u00fd rok ",
          year$label,
          "\""
        ),
        "page-layout: full",
        "---",
        "",
        "<div class=\"lesson-grid\">",
        vec_year_cards,
        "</div>"
      ),
      con = file.path(year_directory, "index.qmd"),
      useBytes = TRUE
    )

    state_label <- "Aktu\u00e1ln\u00ed ro\u010dn\u00edk"
    if (isTRUE(year$frozen)) {
      state_label <- "Uzav\u0159en\u00fd snapshot"
    }
    vec_archive <-
      c(
        vec_archive,
        paste0(
          "<section class=\"archive-year\"><h2>",
          year$label,
          "</h2><p>",
          state_label,
          paste0(
            "</p><p><a class=\"resource-link resource-link--primary\" ",
            "href=\"rok/"
          ),
          year$slug,
          "/\">Zobrazit lekce</a></p></section>"
        )
      )
  }

  writeLines(
    text = vec_archive,
    con = file.path(output_directory, "archive-list.md"),
    useBytes = TRUE
  )

  return(invisible(output_directory))
}
