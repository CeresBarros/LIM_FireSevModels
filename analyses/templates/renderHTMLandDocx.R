#' Render an Rmd from `analyses/` to all its output formats
#'
#' Knits from the repo root (Rmds in `analyses/` use repo-root-relative paths),
#' then sets `updateFields` in the .docx so Word refreshes the table of contents
#' page numbers on opening (pandoc cannot compute page numbers itself).
#'
#' @param input character. Path to the .Rmd file.
#'
#' @return character. Paths of the rendered files, invisibly.
renderHTMLandDocx <- function(input) {
  input <- normalizePath(input)
  out <- rmarkdown::render(input, output_format = "all",
                           knit_root_dir = dirname(dirname(input)),
                           envir = globalenv())
  docx <- grep("[.]docx$", out, value = TRUE)
  for (d in docx) {
    tmp <- tempfile()
    utils::unzip(d, exdir = tmp)
    f <- file.path(tmp, "word", "settings.xml")
    x <- paste(readLines(f, warn = FALSE), collapse = "\n")
    if (!grepl("updateFields", x)) {
      x <- sub("(<w:settings[^>]*>)", "\\1<w:updateFields w:val=\"true\"/>", x)
      writeLines(x, f)
    }
    owd <- setwd(tmp)
    file.remove(d)
    utils::zip(d, list.files(".", recursive = TRUE, all.files = TRUE), flags = "-qX")
    setwd(owd)
    unlink(tmp, recursive = TRUE)
  }
  invisible(out)
}
