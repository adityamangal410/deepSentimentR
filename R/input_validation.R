#'
#'Constants for the package
#' @field max_input_data_size max # of rows in the data frame, to control the response time
#'
config_params = list(
    max_input_data_size = 50000,
    default_seed = 314159,
    col_names = c("id", "polarity", "user", "text", "date")
)

#' check if a data frame is valid sentiment data set
#' @description Method to check if a data frame is valid sentiment data set
#'
#' @param data data frame to check
#' @return bool true or false
#'
is_valid_sentiment_data_frame <- function (data) {
  if (!is.data.frame(data) || nrow(data) == 0) {
    return(FALSE)
  }

  if ( all(config_params$col_names %in% colnames(data) )) {
    return(TRUE)
  }
  return(FALSE)
}

#' Method to validate a data frame
#'
#' @description Method to validate a data frame
#'
#' @param data input data
#' @return Execution halts with error if invalid format found.
#'
validate_sentiment_data_frame <- function(data) {
  if (!is_valid_sentiment_data_frame(data)) {
    stop('validate_sentiment_data_frame: invalid data frame')
  }
}

#' Method to validate a list
#'
#' @description Method to validate a list
#'
#' @param input_list input list
#' @param message message text to report in case of failure (optional)
#' @return Execution halts with error if invalid format found.
#'
validate_list <- function(input_list, message) {
  if (!missing(input_list) && !is.vector(input_list)) {
    if (missing(message)) {
      message = "Aborting, invalid given list "
    }
    error = paste("validate_list:",
                  message, "c(",
                  paste(input_list, collapse = ","),
                  " ).")
    stop(error)
  }
}

#' Method to validate input data
#'
#' @description Method to validate input data
#'
#' @param start_date_time input start_date_time in POSIXct format
#' @param end_date_time input end_date_time in POSIXct format
#' @return Execution halts with error if invalid format found.
#'
validate_time_range <- function(start_date_time, end_date_time) {
  #both start_date_time and end_date_time should be specified.
  if ((missing(start_date_time) &&
       !missing(end_date_time)) ||
      (!missing(start_date_time) &&
       missing(end_date_time))) {
    stop("validate_time_range: Aborting because both start_date_time and end_date_time are required.")
  }
  # make sure the date/time data type is correct
  if ((!missing(start_date_time) &&
       !lubridate::is.POSIXct(start_date_time)) ||
      (!missing(end_date_time) &&
       !lubridate::is.POSIXct(end_date_time))) {
    stop("validate_time_range: Aborting because start/end date time is NOT of POSIXct type")
  }
}

#' Make clause for given parameters
#'
#' @description Make clause for given parameters
#'
#' @param user_list a vector of users for which to filter the dataset.
#' @param start_date_time input start_date_time in POSIXct format on which to filter the dataset
#' @param end_date_time input end_date_time in POSIXct format on which to filter the dataset
#' @param keyword_list a list of string keywords on which to filter the dataset
#' @return filter clause string
#'
#' @importFrom stringr str_c
#'
#' @keywords validation
#'
make_clause <- function(user_list, start_date_time, end_date_time, keyword_list) {

  users_condition <- get_user_list_condition(user_list = user_list)

  time_condition <- get_time_condition(start_date_time = start_date_time,
                                       end_date_time = end_date_time)

  keyword_condition <- get_keyword_condition(keyword_list = keyword_list)

  clause <- stringr::str_c(users_condition, " & ", time_condition, " & ", keyword_condition)

  return(clause)
}

#' Make sub-clause for given keywords
#'
#' @description Make sub-clause for given keywords
#'
#' @param keyword_list a list of string keywords on which to filter the dataset
#' @return filter sub-clause string
#'
#' @importFrom stringr str_c
#'
#' @keywords query
#'
get_keyword_condition <- function(keyword_list) {
  keyword_condition <- "TRUE"
  if(!missing(keyword_list) && !all(is.na(keyword_list))){
    keyword_condition <- stringr::str_c("( stringr::str_detect(text, pattern = \"",
                                        paste(keyword_list, collapse = "|"), "\" ))")
  }
  return(keyword_condition)
}

#' Make sub-clause for given time range
#'
#' @description Make sub-clause for given time range
#'
#' @param start_date_time input start_date_time in POSIXct format on which to filter the dataset
#' @param end_date_time input end_date_time in POSIXct format on which to filter the dataset
#' @return filter sub-clause string
#'
#' @importFrom stringr str_c
#'
#' @keywords query
#'
get_time_condition <- function(start_date_time, end_date_time) {
  time_condition <- "TRUE"
  if (!missing(start_date_time) && !missing(end_date_time)){
    time_condition <- stringr::str_c("( date >= \"", start_date_time, "\" & date <= \"", end_date_time, "\" )")
  }

  return(time_condition)
}

#' Make sub-clause for given users
#'
#' @description Make sub-clause for given users
#'
#' @param user_list a vector of users for which to filter the dataset.
#' @return filter sub-clause string
#'
#' @importFrom stringr str_c
#'
#' @keywords query
#'
get_user_list_condition <- function(user_list) {
  users_condition <- "TRUE"

  if (!missing(user_list) && !all(is.na(user_list))){
    users_condition <- stringr::str_c("( user %in% c( ")

    for (user in user_list) {
      users_condition <- stringr::str_c(users_condition, "\"", user, "\",")
    }

    users_condition <- substr(users_condition, 1, nchar(users_condition)-1)

    users_condition <- stringr::str_c(users_condition, " ))")
  }

  return(users_condition)
}

#'
#' subsample input data to max size
#' @param data input data
#' @param data_size defaults to the max input data size
#' @return sub sampled data if needed.
#'
subsample_input_data <- function(data, data_size=config_params$max_input_data_size) {
  validate_sentiment_data_frame(data)
  set.seed(config_params$default_seed)
  if (dim(data)[1] > data_size) {
    data <- data %>%
      dplyr::sample_n(data_size)
  }

  return(data)
}


