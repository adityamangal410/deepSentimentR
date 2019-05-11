#' Generate time series plots to analyze data based on filters
#'
#' @name time_series
#'
#' @description Generate time series plots to analyze given data with filters and visualize over polarity and return the raw data, date/day aggregate data and a \code{plots} for the same.
#'
#' @param data the sentiment140 train or test data containing variables \code{user} for username, \code{date} for date and
#' \code{text} for text of the tweet.
#' @param user_list a vector of users for which to filter the dataset
#' @param start_date_time input start_date_time in POSIXct format on which to filter the dataset
#' @param end_date_time input end_date_time in POSIXct format on which to filter the dataset
#' @param keyword_list a list of string keywords on which to filter the dataset
#' @return a list object with \code{raw} filtered dataframe, \code{date_counts} aggregated dataframe that holds the frequency counts of date by polarity, \code{day_counts} aggregated dataframe that holds the frequency counts of day by polarity and a \code{plots} depicting their relationship.
#'
#' @export
#'
#' @importFrom ggplot2 ggplot aes geom_line labs stat_smooth scale_x_date geom_point theme_light theme_set
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate filter count
#' @importFrom rlang .data
#' @importFrom lubridate date day
#'
#' @keywords analysis visualization
#'
#' @examples
#' data(sentiment140_train)
#' time_series(user_list = c("DarkPiano"))
#'
utils::globalVariables(c("sentiment140_train"))
time_series <- function(data = sentiment140_train,
                             user_list,
                             start_date_time,
                             end_date_time,
                             keyword_list) {

  validate_sentiment_data_frame(data = data)
  validate_list(input_list = user_list, message="Aborting, invalid user list")
  validate_time_range(start_date_time = start_date_time,
                      end_date_time = end_date_time)
  validate_list(input_list = keyword_list, message="Aborting, invalid keyword list")

  clause <- make_clause(user_list, start_date_time, end_date_time, keyword_list)

  exp <- eval(parse(text = clause), data, parent.frame())

  raw <- data %>% dplyr::filter(exp)

  result <- list()

  result$raw <- raw

  date_counts <- raw %>%
    dplyr::mutate(date = lubridate::date(.data$date),
                  polarity = as.factor(.data$polarity)) %>%
    dplyr::count(.data$date, .data$polarity, name = "count")

  result$date_counts <- date_counts

  day_counts <- raw %>%
    dplyr::mutate(day = lubridate::day(.data$date),
                  polarity = as.factor(.data$polarity)) %>%
    dplyr::count(.data$day, .data$polarity, name = "count")

  result$day_counts <- day_counts

  ggplot2::theme_set(ggplot2::theme_light())
  p_date <- ggplot2::ggplot(data = date_counts,
                            ggplot2::aes(x = .data$date,
                                         y = .data$count,
                                         group = .data$polarity,
                                         color = .data$polarity)) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::scale_x_date(date_labels = "%d/%b/%Y") +
    ggplot2::labs(y="Counts",
                  x="Date",
                  title="Trend of tweets by date over polarity",
                  color = "Polarity")

  result$plot_date <- p_date

  p_day <- ggplot2::ggplot(data = day_counts,
                           ggplot2::aes(x = .data$day,
                                        y = .data$count,
                                        group = .data$polarity,
                                        color = .data$polarity)) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::labs(y="Counts",
                  x="Day of the Month",
                  title="Trends of tweets by day of month over polarity",
                  color = "Polarity")

  result$plot_day <- p_day

  return(result)
}
