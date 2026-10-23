# Draws the tlfstack hex logo: three isometric layers (figures, listings,
# tables, bottom to top) in the package's Paul Tol palette, with a table grid
# and a step curve on the top face. Run from the package root:
#   Rscript --no-init-file data-raw/make_logo.R
library(ggplot2)

navy <- "#1B2A41"
cols <- c(fig = "#228833", lst = "#EE6677", tbl = "#4477AA")
shade <- function(hex, f) {
  rgb <- grDevices::col2rgb(hex) / 255
  grDevices::rgb(rgb[1] * f, rgb[2] * f, rgb[3] * f)
}

hex <- data.frame(x = 0.965 * cos(pi / 2 + (0:5) * pi / 3), y = 0.965 * sin(pi / 2 + (0:5) * pi / 3))

w <- 0.56
h <- 0.30
t <- 0.075
layer <- function(y, fill, id) {
  top <- data.frame(x = c(-w, 0, w, 0), y = c(y, y + h, y, y - h), part = "top")
  left <- data.frame(x = c(-w, 0, 0, -w), y = c(y, y - h, y - h - t, y - t), part = "left")
  right <- data.frame(x = c(0, w, w, 0), y = c(y - h, y, y - t, y - h - t), part = "right")
  out <- rbind(top, left, right)
  out$fill <- c(rep(fill, 4), rep(shade(fill, 0.72), 4), rep(shade(fill, 0.55), 4))
  out$id <- paste(id, out$part)
  out
}
ys <- c(fig = -0.13, lst = 0.10, tbl = 0.33)
polys <- do.call(rbind, lapply(names(ys), function(k) layer(ys[[k]], cols[[k]], k)))
polys$id <- factor(polys$id, levels = unique(polys$id))

# Top face coordinates: T + u (R - T) + v (L - T).
y0 <- ys[["tbl"]]
face <- function(u, v) {
  c(x = u * w - v * w, y = (y0 + h) + u * (-h) + v * (-h))
}
seg <- function(u1, v1, u2, v2) {
  a <- face(u1, v1)
  b <- face(u2, v2)
  data.frame(x = a[["x"]], y = a[["y"]], xend = b[["x"]], yend = b[["y"]])
}
grid <- rbind(
  do.call(rbind, lapply(c(0.25, 0.5, 0.75), function(u) seg(u, 0.08, u, 0.92))),
  do.call(rbind, lapply(c(1 / 3, 2 / 3), function(v) seg(0.08, v, 0.92, v)))
)
# A Kaplan-Meier style step curve drawn across the top face.
# Plot axes on the face: time runs along the left->top edge (v = 1 - time),
# survival falls along the left->bottom edge (u = 1 - survival).
time <- c(0.08, 0.30, 0.30, 0.52, 0.52, 0.72, 0.72, 0.92)
surv <- c(0.90, 0.90, 0.72, 0.72, 0.55, 0.55, 0.42, 0.42)
su <- 1 - surv
sv <- 1 - time
step <- do.call(rbind, lapply(seq_along(su), function(i) as.data.frame(as.list(face(su[i], sv[i])))))

p <- ggplot() +
  geom_polygon(data = hex, aes(x, y), fill = navy, colour = cols[["tbl"]], linewidth = 2.2) +
  geom_polygon(data = polys, aes(x, y, group = id, fill = I(fill)), colour = navy, linewidth = 0.35) +
  geom_segment(data = grid, aes(x, y, xend = xend, yend = yend), colour = "white", alpha = 0.55,
               linewidth = 0.45) +
  geom_path(data = step, aes(x, y), colour = "white", linewidth = 1.15, lineend = "round") +
  annotate("text", x = 0, y = -0.60, label = "tlfstack", colour = "white", size = 6.4,
           fontface = "bold", family = "sans") +
  annotate("text", x = 0, y = -0.76, label = "tables · listings · figures", colour = "#C8D3E3",
           size = 2.1, family = "sans") +
  coord_equal(xlim = c(-0.88, 0.88), ylim = c(-1.01, 1.01), expand = FALSE) +
  theme_void() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA),
        panel.background = element_rect(fill = "transparent", colour = NA))

dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)
ragg::agg_png("man/figures/logo.png", width = 1.732, height = 2, units = "in", res = 300,
              background = "transparent")
print(p)
grDevices::dev.off()
svglite::svglite("man/figures/logo.svg", width = 1.732, height = 2, bg = "transparent")
print(p)
grDevices::dev.off()
