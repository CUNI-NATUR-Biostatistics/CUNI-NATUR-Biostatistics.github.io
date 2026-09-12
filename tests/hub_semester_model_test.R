# Focused regression checks for HUB semester generation and URL semantics.

source("R/functions/read_utf8_yaml.R")
source("R/functions/read_course_config.R")
source("R/functions/make_placeholder_catalog.R")
source("R/functions/read_catalog.R")
source("R/functions/escape_html.R")
source("R/functions/escape_yaml_text.R")
source("R/functions/render_resource_link.R")
source("R/functions/get_public_resource_url.R")
source("R/functions/format_release_date.R")
source("R/functions/render_supplementary_links.R")
source("R/functions/render_lesson_card.R")
source("R/functions/render_lesson_page.R")
source("R/functions/read_semester_fragment.R")
source("R/functions/inject_schedule_lesson_cards.R")
source(
  "R/functions/render_redirect_page.R",
  encoding = "UTF-8"
)
source(
  "R/functions/write_site_sources.R",
  encoding = "UTF-8"
)

config <- read_course_config()
catalog <- make_placeholder_catalog(config)
legacy_catalog <- catalog
for (
  lesson_id in names(legacy_catalog$years[["2026-27"]]$lessons)
  ) {
  legacy_catalog$years[["2026-27"]]$lessons[[lesson_id]]$placement <- NULL
  legacy_catalog$years[["2026-27"]]$lessons[[lesson_id]]$repository_link <- NULL
}
legacy_catalog_path <- tempfile(fileext = ".json")
on.exit(unlink(legacy_catalog_path, force = TRUE), add = TRUE)
jsonlite::write_json(
  legacy_catalog,
  path = legacy_catalog_path,
  auto_unbox = TRUE,
  null = "null"
)
upgraded_catalog <-
  read_catalog(
    config = config,
    path = legacy_catalog_path
  )
stopifnot(
  identical(
    upgraded_catalog$years[["2026-27"]]$lessons$L00$placement,
    "schedule"
  ),
  identical(
    upgraded_catalog$years[["2026-27"]]$lessons$L00$repository_link,
    FALSE
  ),
  identical(
    upgraded_catalog$years[["2026-27"]]$lessons$L01$placement,
    "materials"
  ),
  identical(
    upgraded_catalog$years[["2026-27"]]$lessons$L01$repository_link,
    TRUE
  )
)
output_directory <-
  tempfile(
    pattern = "hub-semester-test-",
    tmpdir = tempdir()
  )
on.exit(
  unlink(output_directory, recursive = TRUE, force = TRUE),
  add = TRUE
)

write_site_sources(
  catalog = catalog,
  output_directory = output_directory
)

current_grid <-
  paste(
    readLines(
      file.path(output_directory, "current-grid.md"),
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )
current_schedule <-
  paste(
    readLines(
      file.path(output_directory, "current-rozvrh.md"),
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )
archive_schedule <-
  paste(
    readLines(
      file.path(
        output_directory,
        "semestry",
        "2026-27",
        "rozvrh.qmd"
      ),
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )
archive_grid <-
  paste(
    readLines(
      file.path(
        output_directory,
        "semestry",
        "2026-27",
        "index.qmd"
      ),
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )
count_fixed <- function(pattern, text) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1]]
  if (identical(matches, -1L)) {
    return(0L)
  }
  return(length(matches))
}

stopifnot(
  file.exists(
    file.path(output_directory, "README.md")
  ),
  file.exists(
    file.path(output_directory, "semestry", "README.md")
  ),
  file.exists(
    file.path(output_directory, "rok", "README.md")
  ),
  file.exists(
    file.path(output_directory, "semestry", "2026-27", "index.qmd")
  ),
  file.exists(
    file.path(output_directory, "semestry", "2026-27", "rozvrh.qmd")
  ),
  file.exists(
    file.path(output_directory, "semestry", "2026-27", "hodnoceni.qmd")
  ),
  file.exists(
    file.path(output_directory, "semestry", "2026-27", "vyucujici.qmd")
  ),
  file.exists(
    file.path(output_directory, "rok", "2026-27", "index.qmd")
  ),
  !grepl(
    "<span class=\"lesson-number\">L00</span>",
    current_grid,
    fixed = TRUE
  ),
  count_fixed(
    "<span class=\"lesson-number\">L00</span>",
    current_schedule
  ) == 1L,
  grepl("lesson-grid--schedule", current_schedule, fixed = TRUE),
  grepl("P\u0159ipravujeme", current_schedule, fixed = TRUE),
  count_fixed(
    "<span class=\"lesson-number\">L00</span>",
    archive_schedule
  ) == 1L,
  !grepl(
    "<span class=\"lesson-number\">L00</span>",
    archive_grid,
    fixed = TRUE
  )
)

legacy_redirect <-
  paste(
    readLines(
      file.path(output_directory, "rok", "2026-27", "index.qmd"),
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )
stopifnot(
  grepl(
    "/semestry/2026-27/",
    legacy_redirect,
    fixed = TRUE
  )
)

resource <- function(href) {
  list(href = href)
}
lesson <-
  list(
    id = "L01",
    title = "Testovac\u00ed lekce",
    placement = "materials",
    repository_link = TRUE,
    subtitle = "Kontrola stabiln\u00edch odkaz\u016f",
    status = "published",
    release = "L01-v0.1.1-20260824",
    release_year = "2026-27",
    material_base_url =
      "https://cuni-natur-biostatistics.github.io/L01/current/",
    release_base_url = paste0(
      "https://cuni-natur-biostatistics.github.io/L01/releases/",
      "L01-v0.1.1-20260824/"
    ),
    manifest =
      list(
        repository = "CUNI-NATUR-Biostatistics/L01",
        resources =
          list(
            learning =
              list(
                html = resource("learning/"),
                pdf = resource("learning/skripta.pdf"),
                source = resource("learning/skripta.qmd")
              ),
            presentation =
              list(
                html = resource("presentation/"),
                pdf = resource("presentation/presentation.pdf"),
                source = resource("presentation/presentation.qmd")
              ),
            exercises = list(
              list(label = "Cvi\u010den\u00ed", href = "R/cviceni.R")
            ),
            data = list(
              list(label = "Data", href = "data/data.csv")
            ),
            extras = list(
              list(label = "Dodatek", href = "extras/dodatek.txt")
            )
          )
      )
  )

current_card <-
  render_lesson_card(
    lesson = lesson,
    year_slug = "2026-27",
    channel = "current"
  )
archive_card <-
  render_lesson_card(
    lesson = lesson,
    year_slug = "2026-27",
    channel = "archive"
  )

stopifnot(
  grepl("/L01/current/learning/", current_card, fixed = TRUE),
  grepl("/tree/main", current_card, fixed = TRUE),
  grepl(
    "/L01/releases/L01-v0.1.1-20260824/learning/",
    archive_card,
    fixed = TRUE
  ),
  grepl(
    "/tree/L01-v0.1.1-20260824",
    archive_card,
    fixed = TRUE
  ),
  grepl("semestr 2026/27", current_card, fixed = TRUE),
  grepl("bi bi-book", current_card, fixed = TRUE),
  grepl("bi bi-easel", current_card, fixed = TRUE),
  grepl("bi bi-file-earmark-pdf", current_card, fixed = TRUE),
  grepl("bi bi-file-earmark-code", current_card, fixed = TRUE),
  grepl("bi bi-github", current_card, fixed = TRUE),
  grepl("bi bi-terminal", current_card, fixed = TRUE),
  grepl("bi bi-database", current_card, fixed = TRUE),
  grepl("bi bi-paperclip", current_card, fixed = TRUE),
  grepl("aria-hidden=\"true\"", current_card, fixed = TRUE),
  !grepl("ro\u010dn\u00edk", current_card, fixed = TRUE)
)

private_lesson <- lesson
private_lesson$id <- "L00"
private_lesson$title <- "Prvn\u00ed kroky v R"
private_lesson$placement <- "schedule"
private_lesson$repository_link <- FALSE
private_lesson$release <- "L00-v0.1.0-20260928"
private_lesson$material_base_url <-
  "https://cuni-natur-biostatistics.github.io/L00/current/"
private_lesson$release_base_url <-
  paste0(
    "https://cuni-natur-biostatistics.github.io/L00/releases/",
    "L00-v0.1.0-20260928/"
  )
private_lesson$manifest$repository <- "CUNI-NATUR-Biostatistics/L00"

private_card <-
  render_lesson_card(
    lesson = private_lesson,
    year_slug = "2026-27",
    channel = "current"
  )
stopifnot(
  grepl("/L00/current/learning/", private_card, fixed = TRUE),
  grepl("QMD skript", private_card, fixed = TRUE),
  grepl("QMD prezentace", private_card, fixed = TRUE),
  grepl("R: Cvi\u010den\u00ed", private_card, fixed = TRUE),
  grepl("Data: Data", private_card, fixed = TRUE),
  !grepl("bi bi-github", private_card, fixed = TRUE),
  !grepl(
    "github.com/CUNI-NATUR-Biostatistics/L00",
    private_card,
    fixed = TRUE
  )
)

schedule_template <-
  c(
    "## Voliteln\u00e1 orientace L00 {#l00}",
    "",
    "<!-- lesson-cards: schedule -->"
  )
published_schedule <-
  inject_schedule_lesson_cards(
    schedule_content = schedule_template,
    lessons = list(private_lesson),
    year_slug = "2026-27",
    channel = "current"
  )
stopifnot(
  sum(
    grepl(
      "<span class=\"lesson-number\">L00</span>",
      published_schedule,
      fixed = TRUE
    )
  ) == 1L,
  !any(grepl("lesson-cards: schedule", published_schedule, fixed = TRUE))
)

missing_marker_error <-
  tryCatch(
    {
      inject_schedule_lesson_cards(
        schedule_content = "Rozvrh bez zna\u010dky",
        lessons = list(private_lesson),
        year_slug = "2026-27"
      )
      NULL
    },
    error = identity
  )
duplicate_marker_error <-
  tryCatch(
    {
      inject_schedule_lesson_cards(
        schedule_content =
          c(
            "<!-- lesson-cards: schedule -->",
            "<!-- lesson-cards: schedule -->"
          ),
        lessons = list(private_lesson),
        year_slug = "2026-27"
      )
      NULL
    },
    error = identity
  )
orphan_marker_error <-
  tryCatch(
    {
      inject_schedule_lesson_cards(
        schedule_content = "<!-- lesson-cards: schedule -->",
        lessons = list(lesson),
        year_slug = "2026-27"
      )
      NULL
    },
    error = identity
  )
stopifnot(
  inherits(missing_marker_error, "error"),
  inherits(duplicate_marker_error, "error"),
  inherits(orphan_marker_error, "error")
)

freeze_fixture <-
  tempfile(
    pattern = ".freeze-fixture-",
    tmpdir = "tests"
  )
on.exit(unlink(freeze_fixture, force = TRUE), add = TRUE)
writeLines(
  "Nem\u011bnn\u00fd obsah semestru.",
  con = freeze_fixture,
  useBytes = TRUE
)
expected_hash <- unname(tools::md5sum(freeze_fixture))
invisible(
  read_semester_fragment(
    path = freeze_fixture,
    expected_hash = expected_hash
  )
)
write(
  "Pozd\u011bj\u0161\u00ed zm\u011bna.",
  file = freeze_fixture,
  append = TRUE
)
freeze_error <-
  tryCatch(
    {
      read_semester_fragment(
        path = freeze_fixture,
        expected_hash = expected_hash
      )
      NULL
    },
    error = identity
  )
stopifnot(inherits(freeze_error, "error"))

unlink(freeze_fixture, force = TRUE)
unlink(output_directory, recursive = TRUE, force = TRUE)

message("HUB semester-model regression checks passed.")
