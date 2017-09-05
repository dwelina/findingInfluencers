# findingInfluencers

## Algorithm for finding influencers in YouTube

The objective is to develop an algorithm to find influencers in YouTube for a specific product (initially will be used for games but will be expanded to other areas of influencer marketing in the future). This algorithm (and app that is built for demonstration purposes) should be considered as a prototype to evaluate capability of the idea behind algorithm. This prototype does not take into account the viability of the solution or any design aspects. 

Since it is quite hard to define the essence of a game/product especially without subject matter expertise the approach should be as data driven as possible with some human input to drill deeper into the data.

The data available from YouTube consist of individual video data and has the following features:

"id"               "channel_id"       "title"            "description"     "view_count"       "comment_count"    "like_count"       "dislike_count"   "duration"         "tags"             "published"

The following steps are applied to the data:

Topic mining using Latent Dirichlet Allocation (LDA) is applied to the description text of the videos to find underlying topics in the descriptions of the videos. The algorithm gets the most common words in each topic and the user would select the topic that mostly suits the product he has in mind. Choosing a topic will narrow down the data set to only the channel that are mostly about this topic.

Once we have found the channels related to a desired topic we are going to have look at the “tags” feature in the data which will contain the hashtags/tags that the creator of the video has given to the video. We will run a correlation analysis on each channel having a set of hashtags given to their video. Channels that have common tags will have a correlation between them and the more common tags channels share, the higher the correlation will be. In this way we can find clusters of channels that are creating videos that have similar tags and assumably similar games. From these clusters we can have a look at each one separately.

Now that we have drilled to the desired data set that will only contain relevant channels for us it is time to focus on the numbers like
-	the subscriber count of the channel
-	average sentiment of the videos = like_count/dislike_count
-	average action count = (comment_count+ like_count+ dislike_count)/view_count
-	etc.

Further development:
-	Get more data into the algorithm
-	Optimize the number of topics in such a way that there are as many topics as possible but the topics must be distinct from another
-	See how the threshold of correlation affects the quality of final data set and choose a fixed threshold OR such a threshold that the final set has at least N channels to choose from
-	Get scoring of relevancy from the user to set a baseline to aid further development
-	Add more info to the result set such as percentile of subscriber count for a region, geographical analysis of subscribers etc.
-	Ultimately design the whole thing for user interaction and recode as a production ready service



