#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                Render lesson card
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

render_lesson_card <- function(
  lesson,
  year_slug,
  channel = c("current", "archive")
) {
  channel <- match.arg(channel)
  status_label <- "P\u0159ipravujeme"
  status_class <- "lesson-status lesson-status--preparing"
  if (identical(lesson$status, "published")) {
    status_label <- "Publikov\u00e1no"
    status_class <- "lesson-status"
  }
  if (identical(lesson$status, "inherited")) {
    status_label <-
      paste0(
        "P\u0159evzato z ",
        gsub("-", "/", lesson$release_year)
      )
    status_class <- "lesson-status lesson-status--inherited"
  }

  top <-
    paste0(
      "<article class=\"lesson-card\">",
      "<div class=\"lesson-card__topline\">",
      "<span class=\"lesson-number\">",
      escape_html(lesson$id),
      "</span>",
      "<span class=\"",
      status_class,
      "\">",
      escape_html(status_label),
      "</span>",
      "</div>",
      "<h3>",
      escape_html(lesson$title),
      "</h3>",
      "<p class=\"lesson-card__subtitle\">",
      escape_html(lesson$subtitle),
      "</p>"
    )

  if (identical(lesson$status, "preparing")) {
    return(
      paste0(
        top,
        "<p class=\"lesson-empty\">",
        paste0(
          "Materi\u00e1ly zat\u00edm nemaj\u00ed schv\u00e1len\u00fd release ",
          "pro studentsk\u00fd web."
        ),
        "</p>",
        "</article>"
      )
    )
  }

  resources <- lesson$manifest$resources
  learning_html <-
    get_public_resource_url(
      lesson = lesson,
      resource = resources$learning$html,
      channel = channel
    )
  learning_pdf <-
    get_public_resource_url(
      lesson = lesson,
      resource = resources$learning$pdf,
      channel = channel
    )
  presentation_html <-
    get_public_resource_url(
      lesson = lesson,
      resource = resources$presentation$html,
      channel = channel
    )
  presentation_pdf <-
    get_public_resource_url(
      lesson = lesson,
      resource = resources$presentation$pdf,
      channel = channel
    )
  learning_source <-
    get_public_resource_url(
      lesson = lesson,
      resource = resources$learning$source,
      channel = channel
    )
  presentation_source <-
    get_public_resource_url(
      lesson = lesson,
      resource = resources$presentation$source,
      channel = channel
    )
  repository_ref <- "main"
  if (identical(channel, "archive")) {
    repository_ref <- lesson$release
  }
  repository_url <-
    paste0(
      "https://github.com/",
      lesson$manifest$repository,
      "/tree/",
      repository_ref
    )

  vec_primary <-
    c(
      render_resource_link(
        label = "Skripta HTML",
        href = learning_html,
        primary = TRUE
      ),
      render_resource_link(
        label = "Prezentace",
        href = presentation_html,
        primary = TRUE
      ),
      render_resource_link(
        label = "Skripta PDF",
        href = learning_pdf
      ),
      render_resource_link(
        label = "Prezentace PDF",
        href = presentation_pdf
      )
    )
  vec_sources <-
    c(
      render_resource_link(
        label = "QMD skript",
        href = learning_source
      ),
      render_resource_link(
        label = "QMD prezentace",
        href = presentation_source
      ),
      render_resource_link(
        label = "Repozit\u00e1\u0159",
        href = repository_url
      )
    )
  vec_supplementary <-
    render_supplementary_links(
      lesson = lesson,
      channel = channel
    )
  meta <-
    paste0(
      escape_html(lesson$release),
      " \u00b7 ",
      escape_html(format_release_date(lesson$release)),
      " \u00b7 ro\u010dn\u00edk ",
      escape_html(gsub("-", "/", year_slug))
    )

  res_card <-
    paste0(
      top,
      "<div class=\"resource-group\">",
      paste(vec_primary, collapse = ""),
      "</div>",
      "<div class=\"resource-group\">",
      paste(c(vec_sources, vec_supplementary), collapse = ""),
      "</div>",
      "<div class=\"lesson-card__meta\">",
      meta,
      "</div>",
      "</article>"
    )

  return(res_card)
}
