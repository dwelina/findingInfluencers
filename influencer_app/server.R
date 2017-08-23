function(input, output, session) {


top_words_perTopic <- reactive({
    #subset(top_terms, topic == input$topic)
    top_terms
    
  })

    
  output$plot1 <- renderPlot({
    
   ggbarplot(top_words_perTopic(), x = "term", y = "beta",
            fill = "topic",               # change fill color by cyl
            color = "white",            # Set bar border colors to white
            palette = "jco",            # jco journal color palett. see ?ggpar
            sort.val = "asc",           # Sort the value in ascending order
            sort.by.groups = TRUE,      # Sort inside each group
            x.text.angle = 90           # Rotate vertically x axis texts
            )
  
    })
  

}


