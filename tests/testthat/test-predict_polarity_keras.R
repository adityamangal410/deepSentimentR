context("Test Predict Polarity Keras")

library(deepSentimentR)
library(dplyr)
library(lubridate)
data("sentiment140_test")

test_data <- data.frame("user" = c("test_user1", "test_user1", "test_user2"),
                        "date" = c(as_datetime("2009-04-01"), as_datetime("2009-04-05"), as_datetime("2009-04-10")),
                        "text" = c("A sad tweet and very bad and unhappy",
                                   "A nice happy beautiful tweet",
                                   "Very sunny sky and bright and awesome feeling tweet"),
                        "polarity" = c(0, 4, 4),
                        "nouns" = c(4,4,4),
                        "adjectives" = c(1,1,1),
                        "prepositions" = c(1,1,1),
                        "articles" = c(2,2,2),
                        "pronouns" = c(3,2,2),
                        "verbs" = c(1,2,4),
                        "adverbs" = c(1,3,2),
                        "interjections" = c(0,0,0),
                        "id" = c(1,2,3),
                        "query" = c("test", "test", "test"))

test_that("should give valid results for lstm without glove", {
  result <- predict_polarity_keras(data = sentiment140_test,
                                   model_load_path = system.file("extdata",
                                                                 "train_no_glove_lstm.rds",
                                                                 package = "deepSentimentR",
                                                                 mustWork = TRUE))
  expect_true(! is.null(result$plot))
  expect_true(inherits(result$plot, "ggplot"))
  expect_true(is.data.frame(result$raw))
  expect_true(is.data.frame(result$predictions))
  expect_gt(result$accuracy, 0.6)
})

test_that("should give valid results for lstm with glove", {
  result <- predict_polarity_keras(data = sentiment140_test,
                                   model_load_path = system.file("extdata",
                                                                 "train_glove_lstm.rds",
                                                                 package = "deepSentimentR",
                                                                 mustWork = TRUE))
  expect_true(! is.null(result$plot))
  expect_true(inherits(result$plot, "ggplot"))
  expect_true(is.data.frame(result$raw))
  expect_true(is.data.frame(result$predictions))
  expect_gt(result$accuracy, 0.6)
})

test_that("should give valid results for conv_1d without glove", {
  result <- predict_polarity_keras(data = sentiment140_test,
                                   model_load_path = system.file("extdata",
                                                                 "train_no_glove_conv_1d.rds",
                                                                 package = "deepSentimentR",
                                                                 mustWork = TRUE))
  expect_true(! is.null(result$plot))
  expect_true(inherits(result$plot, "ggplot"))
  expect_true(is.data.frame(result$raw))
  expect_true(is.data.frame(result$predictions))
  expect_gt(result$accuracy, 0.6)
})

test_that("should give valid results for conv_1d with glove", {
  result <- predict_polarity_keras(data = sentiment140_test,
                                   model_load_path = system.file("extdata",
                                                                 "train_glove_conv_1d.rds",
                                                                 package = "deepSentimentR",
                                                                 mustWork = TRUE))
  expect_true(! is.null(result$plot))
  expect_true(inherits(result$plot, "ggplot"))
  expect_true(is.data.frame(result$raw))
  expect_true(is.data.frame(result$predictions))
  expect_gt(result$accuracy, 0.6)
})
