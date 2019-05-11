#' Generate word correlation network
#'
#' @name word_cor_network
#'
#' @description Generate word correlation network to analyze given data with filters for all highly correlated words excluding stop words.
#'
#' @param data the sentiment140 train or test data containing variables \code{user} for username, \code{date} for date and
#' \code{text} for text of the tweet.
#' @param user_list a vector of users for which to filter the dataset
#' @param start_date_time input start_date_time in POSIXct format on which to filter the dataset
#' @param end_date_time input end_date_time in POSIXct format on which to filter the dataset
#' @param keyword_list a list of string keywords on which to filter the dataset
#' @param correlation_threshold threshold beyond which to plot the network
#' @return a list object with \code{raw} filtered dataframe, \code{word_cors} aggregated dataframe that holds the correlated words  and a \code{plot} representing the network.
#'
#' @export
#'
#' @importFrom ggplot2 theme_void aes labs theme_set theme_light
#' @importFrom magrittr %>%
#' @importFrom dplyr filter sample_n add_count
#' @importFrom stringr str_detect
#' @importFrom rlang .data
#' @importFrom tidytext unnest_tokens
#' @importFrom igraph graph_from_data_frame
#' @importFrom stats quantile
#' @import ggraph
#' @importFrom widyr pairwise_cor
#'
#' @keywords analysis visualization
#'
#' @examples
#' data(sentiment140_test)
#' word_cor_network()
#'
utils::globalVariables(c("sentiment140_test"))
word_cor_network <- function(data = sentiment140_test,
                             user_list,
                             start_date_time,
                             end_date_time,
                             keyword_list,
                             correlation_threshold = 0.15) {

  validate_sentiment_data_frame(data = data)
  validate_list(input_list = user_list, message="Aborting, invalid user list")
  validate_time_range(start_date_time = start_date_time,
                      end_date_time = end_date_time)
  validate_list(input_list = keyword_list, message="Aborting, invalid keyword list")

  clause <- make_clause(user_list, start_date_time, end_date_time, keyword_list)

  exp <- eval(parse(text = clause), data, parent.frame())

  raw <- data %>% dplyr::filter(exp)

  raw <- subsample_input_data(raw)

  result <- list()

  result$raw <- raw

  raw %>% cor_words() -> word_cors

  result$word_cors <- word_cors

  p <- word_cors %>%
    dplyr::filter(.data$correlation > correlation_threshold,
                  !stringr::str_detect(.data$item1, "\\d"),
                  !stringr::str_detect(.data$item2, "\\d")) %>%
    visualize_cor()

  result$plot <- p

  return(result)
}

#' Pairwise correlation of words in given dataset
#'
#' @description Tokenize text and return dataframe with pairwise word correlation per user for most commonly occuring words
#'
#' @param data dataframe containing text
#' @return aggregated dataframe including words and their pairwise correlations
#'
#' @importFrom tidytext unnest_tokens
#' @importFrom dplyr filter add_count
#' @importFrom stats quantile
#' @importFrom widyr pairwise_cor
#'
#' @keywords bigrams
#'
cor_words <- function(data) {
  data %>%
    tidytext::unnest_tokens("word", .data$text, token = "tweets") %>%
    dplyr::filter(!.data$word %in% tidytext::stop_words$word) %>%
    dplyr::add_count(.data$word, name = "counts") %>%
    dplyr::filter(.data$counts > stats::quantile(.data$counts, 0.7)) %>%
    widyr::pairwise_cor("word", "user", sort = TRUE)
}

#' Generate network plot for words and their pairwise correlation
#'
#' @description Generate network plot for words and their correlations with edge alpha relative to correlation.
#'
#' @param cors dataframe containing words and their pairwise correlation
#' @return plot object with network visualization
#'
#' @importFrom igraph graph_from_data_frame
#' @import ggraph
#' @importFrom ggplot2 aes theme_void labs
#'
#' @keywords bigrams
#'
visualize_cor <- function(cors) {
  set.seed(2019)

  ggplot2::theme_set(ggplot2::theme_light())
  cors %>%
    igraph::graph_from_data_frame() %>%
    ggraph::ggraph(layout = "fr") +
    ggraph::geom_edge_link(ggplot2::aes(edge_alpha = .data$correlation/max(.data$correlation)), show.legend = FALSE) +
    ggraph::geom_node_point(color = "lightblue", size = 5) +
    ggraph::geom_node_text(ggplot2::aes(label = .data$name), repel = TRUE) +
    ggplot2::theme_void() +
    ggplot2::labs(title = "Commonly occuring Word Correlation Network per User")
}
