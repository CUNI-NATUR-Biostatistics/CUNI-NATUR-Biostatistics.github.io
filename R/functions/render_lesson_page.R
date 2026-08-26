#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#                Render lesson page
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

render_lesson_page <- function(lesson, year) {
  vec_header <-
    c(
      "---",
      paste0("title: \"", escape_yaml_text(lesson$title), "\""),
      paste0(
        "subtitle: \"",
        escape_yaml_text(lesson$id),
        " \u00b7 ",
        year$label,
        "\""
      ),
      "page-layout: full",
      "---",
      ""
    )

  if (identical(lesson$status, "preparing")) {
    return(
      c(
        vec_header,
        "::: {.callout-note}",
        "## P\u0159ipravujeme",
        paste0(
          "Tato lekce zat\u00edm nem\u00e1 schv\u00e1len\u00fd release ",
          "pro studentsk\u00fd web."
        ),
        ":::"
      )
    )
  }

  resources <- lesson$manifest$resources
  presentation_html <-
    get_public_resource_url(
      lesson = lesson,
      resource = resources$presentation$html,
      channel = "archive"
    )
  vec_actions <-
    c(
      render_resource_link(
        label = paste0(
          "Otev\u0159\u00edt prezentaci p\u0159es celou obrazovku"
        ),
        href = presentation_html,
        primary = TRUE
      ),
      render_resource_link(
        label = "Skripta HTML",
        href = get_public_resource_url(
          lesson = lesson,
          resource = resources$learning$html,
          channel = "archive"
        ),
        primary = TRUE
      ),
      render_resource_link(
        label = "Skripta PDF",
        href = get_public_resource_url(
          lesson = lesson,
          resource = resources$learning$pdf,
          channel = "archive"
        )
      ),
      render_resource_link(
        label = "Prezentace PDF",
        href = get_public_resource_url(
          lesson = lesson,
          resource = resources$presentation$pdf,
          channel = "archive"
        )
      ),
      render_resource_link(
        label = "QMD skript",
        href = get_public_resource_url(
          lesson = lesson,
          resource = resources$learning$source,
          channel = "archive"
        )
      ),
      render_resource_link(
        label = "QMD prezentace",
        href = get_public_resource_url(
          lesson = lesson,
          resource = resources$presentation$source,
          channel = "archive"
        )
      ),
      render_supplementary_links(
        lesson = lesson,
        channel = "archive"
      )
    )

  status_note <- ""
  if (identical(lesson$status, "inherited")) {
    status_note <-
      paste0(
        "::: {.callout-note}\n",
        paste0(
          "Tento ro\u010dn\u00edk pou\u017e\u00edv\u00e1 schv\u00e1lenou ",
          "verzi z roku "
        ),
        gsub("-", "/", lesson$release_year),
        ".\n",
        ":::\n"
      )
  }

  vec_body <-
    c(
      status_note,
      paste0(
        "**Verze:** `",
        lesson$release,
        "` \u00b7 **Vyd\u00e1no:** ",
        format_release_date(lesson$release)
      ),
      "",
      "<div class=\"lesson-actions\">",
      paste(vec_actions, collapse = ""),
      "</div>",
      "",
      "## Prezentace",
      "",
      paste0(
        "<iframe class=\"presentation-frame\" src=\"",
        presentation_html,
        "\" title=\"Prezentace ",
        escape_html(lesson$id),
        ": ",
        escape_html(lesson$title),
        "\" loading=\"lazy\" allowfullscreen></iframe>"
      ),
      "",
      paste0(
        paste0(
          "Pokud se prezentace nevlo\u017e\u00ed, ",
          "[otev\u0159ete ji v samostatn\u00e9m okn\u011b]("
        ),
        presentation_html,
        ")."
      )
    )

  return(c(vec_header, vec_body))
}
