% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/train_conv_1d.R
\name{train_conv_1d}
\alias{train_conv_1d}
\title{Train 1-dimensional Convolution Network}
\arguments{
\item{data}{the sentiment140 train dataset with \code{text} for text of the tweet and \code{polarity} for polarity.}

\item{max_words}{Maximum number of words to consider using word frequency measure.}

\item{maxlen}{Maximum length of a sequence.}

\item{embedding_dim}{Output dimension of the embedding layer.}

\item{epochs}{Number of epochs to run the training for.}

\item{batch_size}{Batch Size for model fitting.}

\item{validation_split}{Split ratio for validation}

\item{conv1d_filters}{Number of filters i.e. output dimension for convolution layers.}

\item{conv1d_kernel_size}{Window size for convolution layers.}

\item{conv1d_pool_size}{Pool size for max pooling.}

\item{seed}{Seed for shuffling training data.}

\item{model_save_path}{File path location for saving model.}
}
\value{
plot of the training operation showing train vs validation loss and accuracy.
}
\description{
Train 1-dimensional Convolution Network using keras on the given dataset
}
\examples{
\dontrun{
  data(sentiment140_train)
  train_conv_1d(model_save_path = "./train_no_glove_conv_1d.h5")
}

}
\keyword{keras}
\keyword{modelling}
