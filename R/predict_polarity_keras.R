#' Predict polarity for the given dataset.
#'
#' @name predict_polarity_keras
#'
#' @description Predict polarity for the given dataset and filters using the pre-trained Keras LSTM model.
#'
#' @param data the sentiment140 test \code{text} for text of the tweet.
#' @param user_list a vector of users for which to filter the dataset
#' @param start_date_time input start_date_time in POSIXct format on which to filter the dataset
#' @param end_date_time input end_date_time in POSIXct format on which to filter the dataset
#' @param keyword_list a list of string keywords on which to filter the dataset
#' @param maxlen Maximum length of a sequence.
#' @param max_words Maximum number of words to consider using word frequency measure.
#' @param trained_data Training dataset.
#' @param model_load_path File path location of the trained model file.
#' @return a list object with \code{raw} filtered dataframe, \code{predictions} dataframe that holds the predicted polarity using the model, \code{confusion_matrix}, multiple model performance statistics  and a \code{plot} comparing the actual and predicted polarity.
#'
#' @export
#'
#' @importFrom ggplot2 ggplot geom_tile geom_text aes scale_fill_gradient theme_bw theme labs
#' @importFrom magrittr %>%
#' @importFrom dplyr filter count mutate pull
#' @importFrom rlang .data
#'
#' @keywords modelling visualization keras
#'
#' @examples
#' library(deepSentimentR)
#' predict_polarity_keras()
#'
utils::globalVariables(c("sentiment140_test"))
predict_polarity_keras <- function(data = sentiment140_test,
                                   user_list,
                                   start_date_time,
                                   end_date_time,
                                   keyword_list,
                                   maxlen = keras_config_params$maxlen,
                                   max_words = keras_config_params$max_words,
                                   trained_data = sentiment140_train,
                                   model_load_path = system.file("extdata",
                                                                 "train_no_glove_lstm.rds",
                                                                 package = "deepSentimentR",
                                                                 mustWork = TRUE)) {

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

  predictions <- get_predictions(data = raw,
                                 maxlen = maxlen,
                                 model_load_path = model_load_path,
                                 trained_data = trained_data,
                                 max_words = max_words)

  result$predictions <- predictions

  predictions %>%
    dplyr::count(.data$polarity, .data$pred_polarity, name = "count") %>%
    dplyr::mutate(polarity = as.factor(.data$polarity),
                  pred_polarity = as.factor(.data$pred_polarity)) -> confusion

  result$confusion_matrix <- confusion

  result$true_negative <- confusion %>%
    filter(.data$polarity == 0, .data$pred_polarity == 0) %>%
    pull(.data$count)

  result$true_positive <- confusion %>%
    filter(.data$polarity == 1, .data$pred_polarity == 1) %>%
    pull(.data$count)

  result$false_positive <- confusion %>%
    filter(.data$polarity==0, .data$pred_polarity == 1) %>%
    pull(.data$count)

  result$false_negative <- confusion %>%
    filter(.data$polarity==1, .data$pred_polarity==0) %>%
    pull(.data$count)

  result$precision <- result$true_positive / (result$true_positive + result$false_positive)

  result$recall <- result$true_positive / (result$true_positive + result$false_negative)

  result$f1 <- 2 * result$precision * result$recall / (result$precision + result$recall)

  result$accuracy <- (result$true_positive + result$true_negative) /
    (result$true_positive + result$true_negative + result$false_positive + result$false_negative)

  p <- confusion %>%
    ggplot2::ggplot(mapping = ggplot2::aes(x = .data$polarity, y = .data$pred_polarity)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$count), colour = "white") +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%1.0f", .data$count)), vjust = 1) +
    ggplot2::scale_fill_gradient(low = "light blue", high = "royal blue") +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(x = "Polarity",
                  y = "Predicted Polarity",
                  title = "Confusion Matrix for Predicted Polarity")

  result$plot <- p

  return(result)
}

#' Get predictions for the given subset of data
#'
#' @name get_predictions
#'
#' @description Run given keras model to make predictions on the given subset of data
#'
#' @param data Given subset of data to make predictions on.
#' @param maxlen Maximum length of a sequence.
#' @param model_load_path File path location of the trained model file.
#' @param trained_data Training dataset.
#' @param max_words Maximum number of words to consider using word frequency measure.
#' @return Given subset of data appended with pred_polarity column for predicted values.
#'
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate
#' @importFrom rlang .data
#' @importFrom keras texts_to_sequences pad_sequences unserialize_model predict_classes
#'
get_predictions <- function(data, maxlen, model_load_path, trained_data, max_words) {
  #Make sure polarity is 0/1
  data %>%
    dplyr::mutate(polarity = ifelse(.data$polarity=="Positive", 1, 0)) -> data

  tokenizer <- get_tokenizer(data = trained_data,
                             max_words = max_words)

  sequences <- keras::texts_to_sequences(tokenizer, data$text)
  x_test <- keras::pad_sequences(sequences, maxlen = maxlen)
  y_test <- as.array(data$polarity)

  model <- keras::unserialize_model(readRDS(model_load_path))

  model %>%
    keras::predict_classes(x_test) -> preds

  data %>%
    mutate(pred_polarity = preds)
}
