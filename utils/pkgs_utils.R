default_yr <- 2022
default_cws_yr <- 2021

if (interactive()) {
  yr <- default_yr
  cws_yr <- default_cws_yr
} else {
  prsr <- argparse::ArgumentParser()
  prsr$add_argument("yr", help = "Main profile year")
  prsr$add_argument("cws_yr", help = "CWS year")

  args <- prsr$parse_args()
  yr <- as.numeric(args$yr)
  cws_yr <- as.numeric(args$cws_yr)
}

# if (interactive()) {
#   yr <- default_yr
#   cws_yr <- default_cws_yr
# } else {
#   prsr <- argparse::ArgumentParser()
#   prsr$add_argument("yr", help = "Main profile year")
#   prsr$add_argument("cws_yr", help = "CWS year")

#   args <- prsr$parse_args()
#   yr <- as.numeric(args$yr)
#   cws_yr <- as.numeric(args$cws_yr)
# }

library(dplyr, warn.conflicts = FALSE)
library(purrr)
library(tidyr)
library(forcats)
library(stringr)
library(cwi)
library(dcws)
library(camiller)

##########  PRINT YEARS  ################################################## ----
print_yrs <- function() {
  cli::cli_h1(cli::col_magenta("YEARS INCLUDED"))
  cli::cli_ul(c(
    paste(cli::style_bold("Main year:"), yr),
    paste(cli::style_bold("CWS year:"), cws_yr)
  ))
  cat("\n")
}
print_yrs()

##########  FUNCTIONS  ################################################## ----
has_digits <- function(x) all((str_detect(x, "^\\d")), na.rm = TRUE)
not_digits <- function(x) !has_digits(x)

collapse_response <- function(data, categories, nons = c("Don't know", "Refused")) {
  keeps <- names(categories)
  df1 <- data %>%
    dplyr::mutate(response = forcats::fct_collapse(response, !!!categories)) %>%
    dplyr::group_by(dplyr::across(-value)) %>%
    dplyr::summarise(value = sum(value)) %>%
    dplyr::ungroup()

  if (is.null(nons)) {
    out <- df1 %>% dplyr::filter(response %in% keeps)
  } else {
    out <- df1 %>%
      cwi::sub_nonanswers(nons = nons) %>%
      dplyr::filter(response %in% keeps)
  }
  out
}

calc_shares_moe <- function(...) calc_shares(..., moe = moe, digits = 2)
add_grps_moe <- function(...) add_grps(..., moe = moe)
