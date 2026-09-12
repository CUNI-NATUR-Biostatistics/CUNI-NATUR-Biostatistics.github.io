#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#            Inject schedule lesson cards
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

inject_schedule_lesson_cards <- function(
  schedule_content,
  lessons,
  year_slug,
  channel = c("current", "archive")
) {
  channel <- match.arg(channel)
  marker <- "<!-- lesson-cards: schedule -->"
  marker_positions <- which(trimws(schedule_content) == marker)
  schedule_lessons <-
    Filter(
      f = function(lesson) {
        identical(lesson$placement, "schedule")
      },
      x = lessons
    )

  if (length(schedule_lessons) == 0L) {
    if (length(marker_positions) > 0L) {
      cli::cli_abort(
        "Schedule card marker exists without a schedule-placed lesson."
      )
    }
    return(schedule_content)
  }
  if (length(marker_positions) != 1L) {
    cli::cli_abort(
      paste0(
        "Schedule with schedule-placed lessons must contain exactly one ",
        "{.code <!-- lesson-cards: schedule -->} marker."
      )
    )
  }

  cards <-
    unlist(
      lapply(
        schedule_lessons,
        function(lesson) {
          render_lesson_card(
            lesson = lesson,
            year_slug = year_slug,
            channel = channel
          )
        }
      ),
      use.names = FALSE
    )
  card_block <-
    c(
      "<div class=\"lesson-grid lesson-grid--schedule\">",
      cards,
      "</div>"
    )

  res_content <-
    append(
      schedule_content[-marker_positions],
      values = card_block,
      after = marker_positions - 1L
    )

  return(res_content)
}
