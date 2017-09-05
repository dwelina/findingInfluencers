library(shiny)
library(data.table)
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
library(tidytext)
library(widyr)
library(ggraph)
library(igraph)

# Navigate to a working directory where you have you Shiny files and data


#data <- read_csv("youtube_dataEN.csv")
#data <- as.data.frame(data)
data <- read_csv("/Users/pcraisan/Desktop/rwds/Shiny/findingInfluencers/youtube_dataEN.csv")


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

# Get topic with the highest probability for each video and add this information to original data
video_lda.topics <- as.matrix(topics(video_lda))
video_lda.topics <- as.data.frame(video_lda.topics)
video_lda.topics <- rownames_to_column(video_lda.topics, "id")
colnames(video_lda.topics) <- c("id", "topic")
data <- merge(data, video_lda.topics, by="id", all.x = TRUE)

# Get top terms by topic to a data frame
tidy_lda <- tidy(video_lda)

top_terms <- tidy_lda %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

top_terms$topic <- factor(top_terms$topic)

# Get channel name and tags and calculate correlations

getChannelCors <- function(data_ss){
  	channel_tokens <- data_ss[, c(13,10)]

	channel_tokens$tags <- gsub("\"", " ", channel_tokens$tags)
	channel_tokens$tags <- gsub(",", " ", channel_tokens$tags)

	channel_tokens <- channel_tokens %>%
		unnest_tokens(tag, tags)
		
	tokens_by_channel <- channel_tokens %>%
	  count(channel_title, tag, sort = TRUE) %>%
	  ungroup()
	  
	channel_cors <- tokens_by_channel %>%
	  pairwise_cor(channel_title, tag, n, sort = TRUE)
  
  return(channel_cors)
}