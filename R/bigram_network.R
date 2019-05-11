#' Generate bigram network
#'
#' @name bigram_network
#'
#' @description Generate bigram network to analyze given data with filters for all most common bigrams excluding stop words.
#'
#' @param data the sentiment140 train or test data containing variables \code{user} for username, \code{date} for date and
#' \code{text} for text of the tweet.
#' @param user_list a vector of users for which to filter the dataset
#' @param start_date_time input start_date_time in POSIXct format on which to filter the dataset
#' @param end_date_time input end_date_time in POSIXct format on which to filter the dataset
#' @param keyword_list a list of string keywords on which to filter the dataset
#' @param counts_quantile the quantile beyond which to visualize the bigrams
#' @return a list object with \code{raw} filtered dataframe, \code{bigram_counts} aggregated dataframe that holds the frequency counts of bigrams and a \code{plot} representing the network.
#'
#' @export
#'
#' @importFrom ggplot2 theme_void aes labs theme_set theme_light
#' @importFrom magrittr %>%
#' @importFrom dplyr filter count sample_n
#' @importFrom stringr str_detect
#' @importFrom rlang .data
#' @importFrom tidytext unnest_tokens
#' @importFrom tidyr separate
#' @importFrom igraph graph_from_data_frame
#' @importFrom stats quantile
#' @import ggraph
#'
#' @keywords analysis visualization
#'
#' @examples
#' bigram_network()
#'
utils::globalVariables(c("sentiment140_test"))
bigram_network <- function(data = sentiment140_test,
                           user_list,
                           start_date_time,
                           end_date_time,
                           keyword_list,
                           counts_quantile = 0.95) {

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

  raw %>% count_bigrams() -> bigram_counts

  result$bigram_counts <- bigram_counts

  p <- bigram_counts %>%
    dplyr::filter(.data$counts > stats::quantile(.data$counts, counts_quantile),
                  !stringr::str_detect(.data$word1, "\\d"),
                  !stringr::str_detect(.data$word2, "\\d")) %>%
    visualize_bigrams()

  result$plot <- p

  return(result)
}

#' Count bigrams in given dataset
#'
#' @description Count bigrams in the given dataset while excluding stop words
#'
#' @param data dataframe containing text
#' @return aggregated dataframe including bigrams and their counts
#'
#' @importFrom tidytext unnest_tokens
#' @importFrom tidyr separate
#' @importFrom dplyr filter count
#'
#' @keywords bigrams
#'
count_bigrams <- function(data) {
  data %>%
    tidytext::unnest_tokens("bigram", .data$text, token = "ngrams", n = 2) %>%
    tidyr::separate(.data$bigram, c("word1", "word2"), sep = " ") %>%
    dplyr::filter(!.data$word1 %in% tidytext::stop_words$word,
                  !.data$word2 %in% tidytext::stop_words$word) %>%
    dplyr::count(.data$word1, .data$word2, sort = TRUE, name = "counts")
}

#' Generate network plot for bigram and counts
#'
#' @description Generate network plot for bigram and counts with arrows pointing to bigram word direction and edge alpha relative to counts
#'
#' @param bigrams dataframe containing bigrams and their counts
#' @return plot object with network visualization
#'
#' @importFrom igraph graph_from_data_frame
#' @import ggraph
#' @importFrom ggplot2 aes theme_void labs
#'
#' @keywords bigrams
#'
visualize_bigrams <- function(bigrams) {
  set.seed(2019)
  ggplot2::theme_set(ggplot2::theme_light())
  a <- grid::arrow(type = "closed", length = grid::unit(.15, "inches"))

  bigrams %>%
    igraph::graph_from_data_frame() %>%
    ggraph::ggraph(layout = "fr") +
    ggraph::geom_edge_link(ggplot2::aes(edge_alpha = .data$counts/max(.data$counts)), show.legend = FALSE, arrow = a) +
    ggraph::geom_node_point(color = "lightblue", size = 5) +
    ggraph::geom_node_text(ggplot2::aes(label = .data$name), vjust = 1, hjust = 1) +
    ggplot2::theme_void() +
    ggplot2::labs(title = "Commonly occuring Bigrams Network")
}
