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

  writeLines(
    text = c(
      "# Automaticky generovan\u00e9 podklady",
      "",
      paste0(
        "Tento adres\u00e1\u0159 se p\u0159i ka\u017ed\u00e9m sestaven\u00ed ",
        "sma\u017ee a znovu vytvo\u0159\u00ed."
      ),
      "",
      "- Neupravujte zdej\u0161\u00ed soubory ru\u010dn\u011b.",
      "- Obsah upravujte v `offerings/`.",
      paste0(
        "- Ob\u00e1lky str\u00e1nek upravujte v ko\u0159enov\u00fdch ",
        "`.qmd` souborech."
      ),
      paste0(
        "- `Rscript R/render_site.R` znovu vytvo\u0159\u00ed tento ",
        "adres\u00e1\u0159."
      )
    ),
    con = file.path(output_directory, "README.md"),
    useBytes = TRUE
  )

  generated_semester_root <-
    file.path(output_directory, "semestry")
  generated_legacy_root <-
    file.path(output_directory, "rok")
  dir.create(
    generated_semester_root,
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(
    generated_legacy_root,
    recursive = TRUE,
    showWarnings = FALSE
  )
  writeLines(
    text = c(
      "# Generovan\u00e9 str\u00e1nky semestr\u016f",
      "",
      paste0(
        "Tento adres\u00e1\u0159 vytv\u00e1\u0159\u00ed sestaven\u00ed webu ",
        "z obsahu v `offerings/`."
      ),
      "",
      "- Neupravujte zdej\u0161\u00ed `.qmd` soubory ru\u010dn\u011b.",
      paste0(
        "- Zm\u011bny prov\u00e1d\u011bjte v p\u0159\u00edslu\u0161n\u00e9m ",
        "`offerings/YYYY-YY/`."
      ),
      paste0(
        "- Tento README se rovn\u011b\u017e p\u0159i ka\u017ed\u00e9m ",
        "sestaven\u00ed znovu vytvo\u0159\u00ed."
      )
    ),
    con = file.path(generated_semester_root, "README.md"),
    useBytes = TRUE
  )
  writeLines(
    text = c(
      paste0(
        "# Generovan\u00e1 kompatibiln\u00ed ",
        "p\u0159esm\u011brov\u00e1n\u00ed"
      ),
      "",
      paste0(
        "Tento adres\u00e1\u0159 zachov\u00e1v\u00e1 star\u00e9 adresy ",
        "`/rok/...`."
      ),
      "",
      paste0(
        "- Str\u00e1nky pouze p\u0159esm\u011brov\u00e1vaj\u00ed na ",
        "`/semestry/...`."
      ),
      "- Neupravujte zdej\u0161\u00ed `.qmd` soubory ru\u010dn\u011b.",
      paste0(
        "- Tento README se rovn\u011b\u017e p\u0159i ka\u017ed\u00e9m ",
        "sestaven\u00ed znovu vytvo\u0159\u00ed."
      )
    ),
    con = file.path(generated_legacy_root, "README.md"),
    useBytes = TRUE
  )

  current_year <- catalog$years[[catalog$current_year]]
  if (is.null(current_year)) {
    cli::cli_abort("Catalog does not contain the configured current semester.")
  }

  required_content <- c("schedule", "assessment", "team")
  frozen_hash <- function(year, content_name) {
    if (!isTRUE(year$frozen)) {
      return(NULL)
    }
    if (
      is.null(year$content_hashes) ||
        is.null(year$content_hashes[[content_name]])
    ) {
      cli::cli_abort(
        "Frozen semester {.val {year$slug}} is missing content hashes."
      )
    }
    return(year$content_hashes[[content_name]])
  }
  if (
    is.null(current_year$content) ||
      !all(required_content %in% names(current_year$content))
  ) {
    cli::cli_abort(
      "Current-semester configuration is missing schedule, assessment, or team."
    )
  }

  current_schedule <-
    read_semester_fragment(
      path = current_year$content$schedule,
      expected_hash = frozen_hash(current_year, "schedule")
    )
  current_assessment <-
    read_semester_fragment(
      path = current_year$content$assessment,
      expected_hash = frozen_hash(current_year, "assessment")
    )
  current_team <-
    read_semester_fragment(
      path = current_year$content$team,
      expected_hash = frozen_hash(current_year, "team")
    )

  writeLines(
    text = current_schedule,
    con = file.path(output_directory, "current-rozvrh.md"),
    useBytes = TRUE
  )
  writeLines(
    text = current_assessment,
    con = file.path(output_directory, "current-hodnoceni.md"),
    useBytes = TRUE
  )
  writeLines(
    text = current_team,
    con = file.path(output_directory, "current-vyucujici.md"),
    useBytes = TRUE
  )

  vec_current_cards <- character()
  for (
    lesson in current_year$lessons
    ) {
    vec_current_cards <-
      c(
        vec_current_cards,
        render_lesson_card(
          lesson = lesson,
          year_slug = current_year$slug,
          channel = "current"
        )
      )
  }

  semester_title <- current_year$semester_label
  if (is.null(semester_title) || !nzchar(semester_title)) {
    semester_title <- paste0("Semestr ", current_year$label)
  }
  semester_note <-
    paste0(
      "Publikovan\u00e9 materi\u00e1ly se m\u011bn\u00ed pouze po ",
      "schv\u00e1len\u00e9m vyd\u00e1n\u00ed lekce."
    )
  if (identical(current_year$semester_status, "preliminary")) {
    semester_note <-
      paste0(
        "Program semestru je p\u0159edb\u011b\u017en\u00fd; publikovan\u00e9 ",
        "materi\u00e1ly se m\u011bn\u00ed pouze po schv\u00e1len\u00e9m ",
        "vyd\u00e1n\u00ed lekce."
      )
  }

  writeLines(
    text = paste0(
      "<div class=\"year-heading\"><h2>",
      escape_html(semester_title),
      "</h2><p>",
      escape_html(semester_note),
      "</p></div>"
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
    if (
      is.null(year$content) ||
        !all(required_content %in% names(year$content))
    ) {
      cli::cli_abort(
        "Semester {.val {year$slug}} is missing snapshot content paths."
      )
    }

    schedule_content <-
      read_semester_fragment(
        path = year$content$schedule,
        expected_hash = frozen_hash(year, "schedule")
      )
    assessment_content <-
      read_semester_fragment(
        path = year$content$assessment,
        expected_hash = frozen_hash(year, "assessment")
      )
    team_content <-
      read_semester_fragment(
        path = year$content$team,
        expected_hash = frozen_hash(year, "team")
      )

    semester_directory <-
      file.path(generated_semester_root, year$slug)
    legacy_directory <-
      file.path(generated_legacy_root, year$slug)
    dir.create(
      semester_directory,
      recursive = TRUE,
      showWarnings = FALSE
    )
    dir.create(
      legacy_directory,
      recursive = TRUE,
      showWarnings = FALSE
    )

    vec_year_cards <- character()
    for (
      lesson in year$lessons
      ) {
      lesson_directory <-
        file.path(semester_directory, lesson$id)
      legacy_lesson_directory <-
        file.path(legacy_directory, lesson$id)
      dir.create(
        lesson_directory,
        recursive = TRUE,
        showWarnings = FALSE
      )
      dir.create(
        legacy_lesson_directory,
        recursive = TRUE,
        showWarnings = FALSE
      )
      writeLines(
        text = render_lesson_page(
          lesson = lesson,
          year = year
        ),
        con = file.path(lesson_directory, "index.qmd"),
        useBytes = TRUE
      )
      writeLines(
        text = render_redirect_page(
          title = paste0(year$label, " \u00b7 ", lesson$id),
          target = paste0(
            "/semestry/",
            year$slug,
            "/",
            lesson$id,
            "/"
          )
        ),
        con = file.path(legacy_lesson_directory, "index.qmd"),
        useBytes = TRUE
      )
      vec_year_cards <-
        c(
          vec_year_cards,
          render_lesson_card(
            lesson = lesson,
            year_slug = year$slug,
            channel = "archive"
          )
        )
    }

    year_title <- year$semester_label
    if (is.null(year_title) || !nzchar(year_title)) {
      year_title <- paste0("Semestr ", year$label)
    }
    snapshot_state <- "Aktivn\u00ed snapshot"
    snapshot_description <-
      "Obsah se m\u016f\u017ee m\u011bnit do uzav\u0159en\u00ed tohoto semestru."
    if (isTRUE(year$frozen)) {
      snapshot_state <- "Uzav\u0159en\u00fd snapshot"
      snapshot_description <-
        paste0(
          "Rozvrh, hodnocen\u00ed a odkazy na vyd\u00e1n\u00ed jsou ",
          "zmrazen\u00e9."
        )
    }

    writeLines(
      text = c(
        "---",
        paste0("title: \"", escape_yaml_text(year_title), "\""),
        "page-layout: full",
        "---",
        "",
        paste0(
          "<div class=\"status-note\"><strong>",
          snapshot_state,
          ".</strong> ",
          snapshot_description,
          "</div>"
        ),
        "",
        "<div class=\"lesson-actions\">",
        "<a class=\"resource-link resource-link--primary\" href=\"rozvrh.html\">Rozvrh</a>",
        paste0(
          "<a class=\"resource-link\" href=\"hodnoceni.html\">",
          "Z\u00e1v\u011bre\u010dn\u00e9 hodnocen\u00ed</a>"
        ),
        paste0(
          "<a class=\"resource-link\" href=\"vyucujici.html\">",
          "Vyu\u010duj\u00edc\u00ed</a>"
        ),
        "</div>",
        "",
        "<div class=\"lesson-grid\">",
        vec_year_cards,
        "</div>"
      ),
      con = file.path(semester_directory, "index.qmd"),
      useBytes = TRUE
    )
    writeLines(
      text = c(
        "---",
        paste0(
          "title: \"Rozvrh \u00b7 ",
          escape_yaml_text(year_title),
          "\""
        ),
        "---",
        "",
        schedule_content
      ),
      con = file.path(semester_directory, "rozvrh.qmd"),
      useBytes = TRUE
    )
    writeLines(
      text = c(
        "---",
        paste0(
          "title: \"Z\u00e1v\u011bre\u010dn\u00e9 hodnocen\u00ed \u00b7 ",
          escape_yaml_text(year_title),
          "\""
        ),
        "---",
        "",
        assessment_content
      ),
      con = file.path(semester_directory, "hodnoceni.qmd"),
      useBytes = TRUE
    )
    writeLines(
      text = c(
        "---",
        paste0(
          "title: \"Vyu\u010duj\u00edc\u00ed \u00b7 ",
          escape_yaml_text(year_title),
          "\""
        ),
        "page-layout: full",
        "---",
        "",
        team_content
      ),
      con = file.path(semester_directory, "vyucujici.qmd"),
      useBytes = TRUE
    )
    writeLines(
      text = render_redirect_page(
        title = paste0("Semestr ", year$label),
        target = paste0("/semestry/", year$slug, "/")
      ),
      con = file.path(legacy_directory, "index.qmd"),
      useBytes = TRUE
    )

    vec_archive <-
      c(
        vec_archive,
        paste0(
          "<section class=\"archive-year\"><h2>",
          escape_html(year_title),
          "</h2><p><strong>",
          escape_html(snapshot_state),
          ".</strong> ",
          escape_html(snapshot_description),
          paste0(
            "</p><p><a class=\"resource-link resource-link--primary\" ",
            "href=\"semestry/"
          ),
          year$slug,
          "/\">Otev\u0159\u00edt snapshot semestru</a></p></section>"
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
