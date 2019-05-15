#' Train LSTM model
#'
#' @name train_lstm
#'
#' @description Train LSTM model using keras on the given dataset
#'
#' @param data the sentiment140 train dataset with \code{text} for text of the tweet and \code{polarity} for polarity.
#' @param max_words Maximum number of words to consider using word frequency measure.
#' @param maxlen Maximum length of a sequence.
#' @param embedding_dim Output dimension of the embedding layer.
#' @param epochs Number of epochs to run the training for.
#' @param batch_size Batch Size for model fitting.
#' @param validation_split Split ratio for validation
#' @param lstm_units Number of units i.e. output dimension of lstm layer.
#' @param seed Seed for shuffling training data.
#' @param model_save_path File path location for saving model.
#' @return plot of the training operation showing train vs validation loss and accuracy.
#'
#' @export
#'
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate
#' @importFrom rlang .data
#' @importFrom keras texts_to_sequences compile optimizer_rmsprop fit serialize_model
#' @importFrom graphics plot
#'
#' @keywords modelling keras
#'
#' @examples
#' \dontrun{
#'   data(sentiment140_train)
#'   train_lstm(model_save_path = "./train_no_glove_lstm.h5")
#' }
#'
utils::globalVariables(c("sentiment140_train"))
train_lstm <- function(data = sentiment140_train,
                       max_words = keras_config_params$max_words,
                       maxlen = keras_config_params$maxlen,
                       embedding_dim = keras_config_params$embedding_dim,
                       epochs = 20L,
                       batch_size = 32L,
                       validation_split = 0.2,
                       lstm_units = 32L,
                       seed = config_params$default_seed,
                       model_save_path) {

  #Make sure polarity is 0/1
  data %>%
    mutate(polarity = ifelse(.data$polarity=="Positive", 1, 0)) -> data

  #Fit tokenizer
  tokenizer <- get_tokenizer(data = data,
                             max_words = max_words)

  #Generate Sequences
  sequences <- keras::texts_to_sequences(tokenizer, data$text)
  word_index <- tokenizer$word_index

  cat("Found", length(word_index), "unique_tokens.\n")

  #Generate Training Data
  training_data <- generate_training_data(data = data,
                                          sequences = sequences,
                                          maxlen = maxlen,
                                          seed = seed)

  #Create Model
  model <- create_lstm_model(max_words = max_words,
                             embedding_dim = embedding_dim,
                             maxlen = maxlen,
                             lstm_units = lstm_units)

  #Compile Model
  model %>% keras::compile(
    optimizer = keras::optimizer_rmsprop(lr = 1e-4),
    loss = "binary_crossentropy",
    metrics = c("acc")
  )

  #Fit model
  history <- model %>% keras::fit(
    training_data$x_train, training_data$y_train,
    epochs = epochs,
    batch_size = batch_size,
    validation_split = validation_split
  )

  saveRDS(keras::serialize_model(model = model), file = model_save_path)

  return(graphics::plot(history))
}
