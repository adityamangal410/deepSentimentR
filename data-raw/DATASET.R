## code to prepare `DATASET` dataset goes here
library(readr)
library(stringr)
library(stringi)
library(dplyr)

#'
#' Remove non english tweets
#' remove short tweets
#' cleanup tweets
#' remove extra white spaces
#' subsample the data
#'
filter_and_sub_sample_data <- function(data, data_size=50000) {
  data <- data %>%
    filter(stringi::stri_enc_mark(.data$text) == "ASCII") %>%
    mutate(text = str_replace(text, "&\\w+;", ""),
           text = str_replace(text, "^\\s+|\\s+$", ""),
           text = str_replace(text, "\\s+", " "),
           text = str_replace(text, "[^:|[:punct:]+]", ""),
           text = str_replace(text, " [^[:alnum:]+] ", " ")) %>%
    filter(nchar(text) > 20)

  if (dim(data)[1] < data_size) {
    data_size = dim(data)[1]
  }

  set.seed(314159)
  data <- data %>%
    sample_n(data_size)

  return(data)
}

#' process training data
#'
#'
sentiment140_train <- readr::read_csv("./data-raw/sentiment140_train_pos_tagged.csv.bz2")
sentiment140_train <- sentiment140_train %>%
  filter_and_sub_sample_data()

usethis::use_data(sentiment140_train, overwrite = TRUE)

#'
#' process test data
#'
#'
sentiment140_test <- readr::read_csv("./data-raw/sentiment140_test_pos_tagged.csv.bz2")
sentiment140_test <- sentiment140_test %>%
  filter_and_sub_sample_data() %>%
  filter(polarity != 2)


usethis::use_data(sentiment140_test, overwrite = TRUE)
