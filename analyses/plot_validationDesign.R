## Validation-design schematic (methods figure for the manuscript).
## Regenerates analyses/Figs/validationDesign.png. Run from the repo root.
## analyses/Figs/validationDesign.mmd is a text version only, not this figure's source.

library(ggplot2)

nodes <- data.frame(
  id = c("all", "hold", "cal", "test", "train", "inner", "model", "score"),
  label = c("All fires",
            "Holdout fires\n(used once, at the end)",
            "Calibration fires",
            "Outer fold k:\ntest fires",
            "Outer fold k:\ntraining fires",
            "Inner folds:\ntuning / variable selection",
            "Model fitted on\nouter training fires",
            "Score on\nouter test fires"),
  x = c(0, -2.6, 1.6, 3.4, 0.2, 0.2, 0.2, 3.4),
  y = c(6, 4.5, 4.5, 3, 3, 1.5, 0, 0)
)

## box half-width and half-height
bw <- 1.4
bh <- 0.42

#' Shorten arrows so they stop at box edges
#'
#' @param x0,y0 numeric. Arrow start coordinates (centre of the origin box).
#' @param x1,y1 numeric. Arrow end coordinates (centre of the target box).
#'
#' @return a `data.frame` with columns `xs`, `ys`, `xe`, `ye`: the
#'   shortened start and end coordinates.
#'
#' @keywords internal
shrink <- function(x0, y0, x1, y1) {
  dx <- x1 - x0; dy <- y1 - y0
  t <- pmin(bw / pmax(abs(dx), 1e-9), bh / pmax(abs(dy), 1e-9))
  data.frame(xs = x0 + dx * t, ys = y0 + dy * t, xe = x1 - dx * t, ye = y1 - dy * t)
}

edges <- data.frame(
  from = c("all", "all", "cal", "cal", "train", "inner", "model", "test"),
  to   = c("hold", "cal", "test", "train", "inner", "model", "score", "score"),
  ## dashed: test fires only enter at the scoring step
  type = c(rep("solid", 7), "dashed")
)
edges <- cbind(edges,
               setNames(nodes[match(edges$from, nodes$id), c("x", "y")], c("x0", "y0")),
               setNames(nodes[match(edges$to, nodes$id), c("x", "y")], c("x1", "y1")))
edges <- cbind(edges, with(edges, shrink(x0, y0, x1, y1)))

ragg::agg_png("analyses/Figs/validationDesign.png", width = 8, height = 6.2,
              units = "in", res = 300, background = "white")
print(
  ggplot() +
    geom_segment(data = edges,
                 aes(x = xs, y = ys, xend = xe, yend = ye, linetype = type),
                 arrow = arrow(length = unit(2.5, "mm"), type = "closed"),
                 linewidth = 0.5, show.legend = FALSE) +
    geom_rect(data = nodes,
              aes(xmin = x - bw, xmax = x + bw, ymin = y - bh, ymax = y + bh),
              fill = "grey95", colour = "grey30", linewidth = 0.4) +
    geom_text(data = nodes, aes(x, y, label = label), size = 3.4, lineheight = 0.9) +
    scale_linetype_identity() +
    coord_equal(xlim = c(-4.2, 5), ylim = c(-0.6, 6.6), expand = FALSE) +
    theme_void()
)
invisible(dev.off())
