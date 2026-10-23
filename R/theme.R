#' Figure body theme
#'
#' A ggplot2 theme for submission figures: white background with a thin black
#' panel border, major gridlines only, black text, legend at the bottom, and
#' no in-body title or subtitle. The title block is set in the RTF text layer
#' by [tlf_rtf_figure()], so it stays machine-auditable.
#'
#' @param base_size Font size in points. `NULL` uses the configured
#'   `figure_size`. Sizes outside the configured `figure_size_range` are an
#'   error.
#' @param base_family Font family. `NULL` uses the configured
#'   `figure_family`.
#' @param config A [tlf_config()]; `NULL` resolves through [tlf_get_config()].
#' @return A ggplot2 theme.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tlf_submission()
#' @export
theme_tlf_submission <- function(base_size = NULL, base_family = NULL, config = NULL) {
  cfg <- tlf_get_config(config)
  base_size <- or_default(base_size, cfg$fonts$figure_size)
  base_family <- or_default(base_family, cfg$fonts$figure_family)
  check_figure_size(base_size, cfg$fonts$figure_size_range)
  black_text <- ggplot2::element_text(colour = "black", size = base_size)
  ggplot2::theme_bw(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = "black", family = base_family, size = base_size),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.border = ggplot2::element_rect(fill = NA, colour = "black", linewidth = 0.4),
      panel.grid.major = ggplot2::element_line(colour = "grey85", linewidth = 0.25),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text = black_text,
      axis.title = black_text,
      axis.ticks = ggplot2::element_line(colour = "black", linewidth = 0.3),
      legend.text = black_text,
      legend.title = black_text,
      legend.key = ggplot2::element_rect(fill = "white", colour = NA),
      legend.background = ggplot2::element_rect(fill = "white", colour = NA),
      legend.position = "bottom",
      strip.background = ggplot2::element_rect(fill = "white", colour = "black"),
      strip.text = black_text,
      plot.title = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_blank()
    )
}
