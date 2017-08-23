library(shiny)
library(data.table)
library(dplyr)
library(foreach)
library(readr)
library(qdap)
library(stringr)
library(dplyr)
library(tidytext)
library(topicmodels)
library(ggplot2)
library(tibble)
library(ggpubr)

# Navigate to a working directory where you have you Shiny files and data

data <- read_csv("youtube_dataEN.csv")
data <- as.data.frame(data) 

# Hoping to do some text mining on the data so will need to clean unwanted things like URLs and punctuation

data$description <- gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", data$description)

# Hoping to do some text mining on the data so will need to clean unwanted things like URLs and punctuation
data$description <- gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", data$description)
data$description <- gsub("[[:punct:]]", "", data$description)
data$description <- gsub("[[:digit:]]", "", data$description)
data$description <- tolower(data$description)
  
# For topic mining we need only the video id and the text that we are going to get the topics from i.e. the descreption column
vid_descriptions <- cbind(data$id, data$description)
vid_descriptions <- as.data.frame(vid_descriptions)
colnames(vid_descriptions) <- c("id", "desc")
vid_descriptions <- subset(vid_descriptions, desc != "")

# Tokenising the descriptions
vid_descriptions <- data.frame(lapply(vid_descriptions, as.character), stringsAsFactors=FALSE)

token_counts <- vid_descriptions %>%
  unnest_tokens(tokens, desc) %>%
  anti_join(stop_words, by = c("tokens" = "word")) %>%
  count(id, tokens, sort = TRUE)

# Creating document term matrix
video_dtm <- token_counts %>%
  cast_dtm(id, tokens, n)

# Remove zero values from matrix so it can be cast to the LDA-function
rowTotals <- apply(video_dtm, 1, sum)
video_dtm.new   <- video_dtm[rowTotals> 0, ]

# Find topics using LDA
video_lda <- LDA(video_dtm.new, k = 6, control = list(seed = 123))

# Get top terms by topic to a data frame
tidy_lda <- tidy(video_lda)

top_terms <- tidy_lda %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

top_terms$topic <- factor(top_terms$topic)