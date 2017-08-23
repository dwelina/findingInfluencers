###################################################
# Finding Influencers in YouTube data
# Code by Paula Räisänen
# Built under R 3.3.0 "Supposedly Educational"
###################################################

# Uncomment to install required packages

# install.packages("RPostgreSQL")
# install.packages("tuber")
# install.packages("qdap")
# install.packages("stringr")
# install.packages("dplyr")
# install.packages("tidytext")
# install.packages("topicmodels")
# install.packages("ggplot2")
# install.packages("tibble")
# install.packages("httr")

# Import packages for use
library(RPostgreSQL)
library(tuber)
library(qdap)
library(stringr)
library(dplyr)
library(tidytext)
library(topicmodels)
library(ggplot2)
library(tibble)
library(httr)

# Connect to PostgreSQL
# Set up authentication
user_name <- "<user>"
pwd <- "<pwd>"
database <- "<database_name>"

# Set up driver to use and connect. Using default arguments for host and port since I have Postgre running locally.
drv <- dbDriver("PostgreSQL")
conn <- dbConnect(drv, user=user_name, password=pwd, host="localhost", port=5432, dbname=database)

# Querying all YouTube data from table youtube_video_example
data <- dbGetQuery(conn, "SELECT * FROM youtube_video_example")

# No need to hold the connection open so closing it as this point anymore
dbDisconnect(conn)

# Get a subset of the data for performance reasons (10 000 rows)
data_ss <- head(data, 10000)

# Hoping to do some text mining on the data so will need to clean unwanted things like URLs and punctuation
data_ss$description <- gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", data_ss$description)
data_ss$description <- gsub("[[:punct:]]", "", data_ss$description)
data_ss$description <- gsub("[[:digit:]]", "", data_ss$description)
data_ss$description <- Trim(clean(data_ss$description))
data_ss$description <- tolower(data_ss$description)

# Authentication for YouTube API called by the tuber package
app_id <- "<your_app_id>"
app_secret <- "your_app_secret"
yt_oauth(app_id, app_secret, token = '')

# Get video language and append it to the dataframe - this will take a while, be patient
data_ss$language <- lapply(data_ss$id, function(x){
  get_video_details(x)$defaultAudioLanguage 
}) 

# Choose only videos in English for topic mining purposes
data_ss <- subset(data_ss, language == "en" | language == "en_US" | language == "en_GB")

# For topic mining we need only the video id and the text that we are going to get the topics from i.e. the descreption column
vid_descriptions <- cbind(data_ss$id, data_ss$description)
vid_descriptions <- as.data.frame(vid_descriptions)
colnames(vid_descriptions) <- c("id", "desc")
vid_descriptions <- subset(vid_descriptions, desc != "")

# Tokenising the descriptions
#Uncomment if having trouble with strings being factors
#vid_descriptions <- data.frame(lapply(vid_descriptions, as.character), stringsAsFactors=FALSE)
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
data_ss <- merge(data_ss, video_lda.topics, by="id", all.x = TRUE)

# Aggregate by channel_id and topic
dataAggregated <- data_ss %>%
  group_by(channel_id, topic) %>%
  summarize(count = n())

# Choose the topic for each channel to be the highest occurring topic
channelTopics <- dataAggregated[order(dataAggregated$channel_id, -abs(dataAggregated$count) ), ] #sort by id and reverse of abs(value)
channelTopics <- channelTopics[!duplicated(channelTopics$channel_id), ] # take the first row within each id
channelTopics <- na.omit(channelTopics)

# Get subscribercounts for a channel
channelTopics$subscription_count <- lapply(channelTopics$channel_id, function(x){
  get_channel_stats(x)$statistics$subscriberCount
}) 

# Get data for top10 channels by subscription count for each topic
channelTopics$subscription_count <- as.integer(channelTopics$subscription_count)
channelTopics <- channelTopics[order(-channelTopics$subscription_count), ]
channelTopics_top10 <- by(channelTopics, channelTopics["topic"], head, n=10)
channelTopics_top10 <- Reduce(rbind, channelTopics_top9)

# Choose a topic and POST to API using httr
topic_number <- "2"
channelTopics_top10_t2 <- subset(channelTopics_top10, topic == topic_number)

# Data posted as json
post_json <- list(unique(channelTopics_top10_t2$channel_id))
res <- POST("https://api.example.com/matches/{campaign_id}/{channel_id}", body = post_json, encode = "json")