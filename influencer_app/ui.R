pageWithSidebar(
  
  headerPanel('Channel topics'),
  
  sidebarPanel(
    selectInput('topic', 'Topic', unique(top_terms$topic), selected = NULL)
  ),
  
  mainPanel(
    plotOutput('plot1'),
    plotOutput('plot2'),
    tableOutput('table1')
  )
)