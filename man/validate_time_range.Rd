% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/input_validation.R
\name{validate_time_range}
\alias{validate_time_range}
\title{Method to validate input data}
\usage{
validate_time_range(start_date_time, end_date_time)
}
\arguments{
\item{start_date_time}{input start_date_time in POSIXct format}

\item{end_date_time}{input end_date_time in POSIXct format}
}
\value{
Execution halts with error if invalid format found.
}
\description{
Method to validate input data
}
