context("Test Time Series")

library(deepSentimentR)
library(dplyr)
library(lubridate)

test_data <- data.frame("user" = c("test_user1", "test_user1", "test_user2"),
                        "date" = c(as_datetime("2009-04-01"), as_datetime("2009-04-05"), as_datetime("2009-04-10")),
                        "text" = c("Sample tweet 1 from user1", "Sample tweet 2 from user1", "Sample tweet 1 from user2"),
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

test_that("no filters shows all records", {
  expect_equal(dim(test_data)[1], dim(time_series(test_data)$raw)[1])
})

test_that("user filter works", {
  expect_equal(2, dim(time_series(test_data, user_list = c("test_user1"))$raw)[1])
})

test_that("date filter works", {
  expect_equal(2, dim(time_series(test_data,
                                  start_date_time = as_datetime("2009-03-31"),
                                  end_date_time = as_datetime("2009-04-06"))$raw)[1])
})

test_that("keyword filter works", {
  expect_equal(2, dim(time_series(test_data, keyword_list = c("user1"))$raw)[1])
})

test_that("all filters work", {
  expect_equal(1, dim(time_series(test_data,
                                  user_list = c("test_user1"),
                                  start_date_time = as_datetime("2009-03-31"),
                                  end_date_time = as_datetime("2009-04-06"),
                                  keyword_list = c("tweet 1"))$raw)[1])
})


test_that("should fail for non-date as date arguments", {
  expect_error(time_series(test_data,
                           start_date_time = "2019",
                           end_date_time = "2020"))
})

test_that("only start date is given without end date", {
  expect_error(time_series(test_data,
                           start_date_time = as_datetime("2009-03-31")))
})

test_that("keyword_list should be a valid list", {
  expect_error(time_series(test_data,
                           keyword_list = NULL))
})

test_that("user_list should be a valid list", {
  expect_error(time_series(test_data,
                           user_list= NULL))
})

test_that("empty keyword list should give full data frame", {
  result <- time_series(test_data,
                        keyword_list=list())
  expect_equal(dim(result$raw)[1], dim(test_data)[1])
})

test_that("empty user list should give full data frame", {
  result <- time_series(test_data,
                        user_list=list())
  expect_equal(dim(result$raw)[1], dim(test_data)[1])
})

test_that("should give valid results", {
  result <- time_series(test_data)
  expect_true(! is.null(result$plot_date))
  expect_true(inherits(result$plot_date, "ggplot"))
  expect_true(! is.null(result$plot_day))
  expect_true(inherits(result$plot_day, "ggplot"))
  expect_true(is.data.frame(result$raw))
  expect_true(is.data.frame(result$date_counts))
  expect_equal(dim(result$date_counts)[1], 3)
  expect_true(is.data.frame(result$day_counts))
  expect_equal(dim(result$day_counts)[1], 3)
  expect_equal(dim(dplyr::filter(result$date_counts, date == as_datetime("2009-04-01")))[1], 1)
  expect_equal(dim(dplyr::filter(result$day_counts, day == 1))[1], 1)
})
