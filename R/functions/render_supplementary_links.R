#----------------------------------------------------------#
#
#
#               Biostatistics course hub
#
#          Render supplementary links
#
#                    O. Mottl
#                       2026
#
#----------------------------------------------------------#

render_supplementary_links <- function(
  lesson,
  channel = c("current", "archive"),
  groups = NULL
) {
  channel <- match.arg(channel)
  vec_links <- character()

  list_groups <-
    list(
      exercises = list(label = "R", icon = "terminal"),
      data = list(label = "Data", icon = "database"),
      extras = list(label = "P\u0159\u00edloha", icon = "paperclip")
    )

  if (!is.null(groups)) {
    if (
      !is.character(groups) ||
        anyNA(groups) ||
        any(!groups %in% names(list_groups))
    ) {
      cli::cli_abort(
        "Supplementary card groups must be exercises, data, or extras."
      )
    }
    list_groups <- list_groups[unique(groups)]
  }

  for (
    group_name in names(list_groups)
    ) {
    entries <- lesson$manifest$resources[[group_name]]
    if (is.null(entries) || length(entries) == 0L) {
      next
    }

    for (
      entry in entries
      ) {
      label <-
        paste0(
          list_groups[[group_name]]$label,
          ": ",
          entry$label
        )
      vec_links <-
        c(
          vec_links,
          render_resource_link(
            label = label,
            href = get_public_resource_url(
              lesson = lesson,
              resource = entry,
              channel = channel
            ),
            download = TRUE,
            icon = list_groups[[group_name]]$icon
          )
        )
    }
  }

  return(vec_links)
}
