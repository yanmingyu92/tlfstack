alt <- function() ex_adlb[ex_adlb$PARAMCD == "ALT", ]

plot_label <- function(p, aes) {
  labs <- if (exists("get_labs", asNamespace("ggplot2"))) ggplot2::get_labs(p) else p$labels
  labs[[aes]]
}

layer_data_of <- function(p, geom_class) {
  b <- ggplot2::ggplot_build(p)
  hits <- vapply(p$layers, function(l) inherits(l$geom, geom_class), logical(1))
  b$data[hits]
}

rtf_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
