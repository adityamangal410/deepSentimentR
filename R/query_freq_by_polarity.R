#' Query the dataset for frequency by polarity based on several filters
#' @name freq_by_polarity
#'
#' @description Query the dataset for frequency by polarity based on several filters and return the raw data, frequency data and a \code{plot} for the same.
#'
#' @param data the sentiment dataset containing variables \code{user} for username, \code{date} for date and
#' \code{text} for text of the tweet. default sentiment140_train dataset
#' @param user_list a vector of users for which to filter the dataset.
#' @param start_date_time input start_date_time in POSIXct format on which to filter the dataset
#' @param end_date_time input end_date_time in POSIXct format on which to filter the dataset
#' @param keyword_list a list of string keywords on which to filter the dataset
#' @return a list object with \code{raw} filtered dataframe, \code{frequency} dataframe that holds the frequency counts by polarity and a \code{plot} depicting the relationship between the two
#'
#' @export
#'
#' @importFrom ggplot2 ggplot aes geom_col labs theme_set theme_light
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate filter count
#' @importFrom stringr str_c str_detect
#' @importFrom rlang .data
#' @importFrom lubridate as_datetime
#'
#' @keywords query visualization
#'
#' @examples
#' library(lubridate)
#' sample_data <- data.frame("user" = c("test_user1", "test_user1", "test_user2"),
#'                           "date" = c(lubridate::as_datetime("2009-04-01"),
#'                                      lubridate::as_datetime("2009-04-05"),
#'                                      lubridate::as_datetime("2009-04-10")),
#'                           "text" = c("Sample tweet 1 from user1",
#'                                      "Sample tweet 2 from user1",
#'                                      "Sample tweet 1 from user2"),
#'                          "polarity" = c(0, 4, 4),
#'                          "id" = c(1,2,3))
#' freq_by_polarity(data = sample_data,
#'                  user_list = c("", "test_user1"),
#'                  start_date_time = lubridate::as_datetime("2009-03-30"),
#'                  end_date_time = lubridate::as_datetime("2009-06-30"),
#'                  keyword_list = c("tweet 2"))
#'
utils::globalVariables(c("sentiment140_train"))
freq_by_polarity <- function(data = sentiment140_train,
                             user_list,
                             start_date_time,
                             end_date_time,
                             keyword_list) {

  validate_sentiment_data_frame(data = data)
  validate_list(input_list = user_list, message = "Aborting, invalid user list")
  validate_time_range(start_date_time = start_date_time,
                      end_date_time = end_date_time)
  validate_list(input_list = keyword_list, message = "Aborting, invalid keyword list")

  clause <- make_clause(user_list, start_date_time, end_date_time, keyword_list)

  exp <- eval(parse(text = clause), data, parent.frame())

  raw <- data %>% dplyr::filter(exp)

  result <- list()

  result$raw <- raw

  frequency <- raw %>%
    dplyr::count(.data$polarity, name = "counts") %>%
    dplyr::mutate(polarity = as.factor(.data$polarity))

  result$frequency <- frequency

  ggplot2::theme_set(ggplot2::theme_light())
  p <- ggplot2::ggplot(data = frequency, ggplot2::aes(x = .data$polarity, y = .data$counts)) +
    ggplot2::geom_col(fill = "cyan") +
    ggplot2::labs(x = "Polarity (0=Negative, 4=Positive)",
                  y = "Frequency Count",
                  title = "Frequency Count vs Polarity")

  result$plot <- p

  return(result)
}
