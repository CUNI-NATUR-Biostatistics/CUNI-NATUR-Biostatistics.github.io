# Static syntax and configuration checks for the HUB sources.

source("R/functions/read_utf8_yaml.R")
source("R/functions/read_course_config.R")

r_files <-
  c(
    "R/build_site.R",
    "R/freeze_offering.R",
    "R/sync_catalog.R",
    list.files(
      path = "R/functions",
      pattern = "[.]R$",
      full.names = TRUE
    ),
    list.files(
      path = "tests",
      pattern = "[.]R$",
      full.names = TRUE
    )
  )

invisible(
  lapply(
    r_files,
    function(path) {
      parse(file = path, encoding = "UTF-8")
    }
  )
)

quarto_config <- read_utf8_yaml("_quarto.yml")
course_config <- read_course_config()
offering <- read_utf8_yaml("offerings/2026-27.yml")
lesson_ids <-
  vapply(
    course_config$lessons,
    function(lesson) lesson$id,
    character(1)
  )
l00 <- course_config$lessons[[match("L00", lesson_ids)]]
regular_lessons <- course_config$lessons[lesson_ids != "L00"]
materials_source <-
  paste(
    readLines("materialy.qmd", encoding = "UTF-8"),
    collapse = "\n"
  )

stopifnot(
  identical(quarto_config$website$title, "Biostatistika"),
  identical(course_config$current_year, "2026-27"),
  identical(
    course_config$course_title,
    "Biostatistika a pl\u00e1nov\u00e1n\u00ed ekologick\u00fdch pokus\u016f"
  ),
  identical(
    offering$semester_label,
    "Zimn\u00ed semestr 2026/27"
  ),
  identical(offering$semester_status, "preliminary"),
  "L00" %in% names(offering$releases),
  identical(l00$placement, "schedule"),
  identical(l00$repository_link, FALSE),
  identical(l00$card_resources, "core"),
  all(
    vapply(
      regular_lessons,
      function(lesson) identical(lesson$placement, "materials"),
      logical(1)
    )
  ),
  all(
    vapply(
      regular_lessons,
      function(lesson) identical(lesson$repository_link, TRUE),
      logical(1)
    )
  ),
  all(
    vapply(
      regular_lessons,
      function(lesson) identical(lesson$card_resources, "all"),
      logical(1)
    )
  ),
  grepl("rozvrh.html#l00", materials_source, fixed = TRUE),
  all(
    c("schedule", "assessment", "team") %in%
      names(offering$content)
  )
)

expect_config_error <- function(candidate, pattern) {
  candidate_path <- tempfile(fileext = ".yml")
  on.exit(unlink(candidate_path, force = TRUE), add = TRUE)
  yaml::write_yaml(candidate, candidate_path)
  condition <-
    tryCatch(
      {
        read_course_config(path = candidate_path)
        NULL
      },
      error = identity
    )
  stopifnot(
    inherits(condition, "error"),
    grepl(pattern, conditionMessage(condition), fixed = TRUE)
  )
}

invalid_placement <- course_config
invalid_placement$lessons[[1]]$placement <- "sidebar"
expect_config_error(
  candidate = invalid_placement,
  pattern = "placement must be materials or schedule"
)

invalid_repository_link <- course_config
invalid_repository_link$lessons[[1]]$repository_link <- "false"
expect_config_error(
  candidate = invalid_repository_link,
  pattern = "repository_link must be true or false"
)

invalid_card_resources <- course_config
invalid_card_resources$lessons[[1]]$card_resources <- "everything"
expect_config_error(
  candidate = invalid_card_resources,
  pattern = "card_resources must be all or core"
)

message("HUB R syntax and YAML validation passed.")
