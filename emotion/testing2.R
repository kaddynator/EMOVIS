# libraries
library(tidyverse); library(shiny); library(dygraphs); library(xts)

# importing whole data - day-wise
shiny_data <- read_csv("./data/shiny_data.csv")
shiny_data$day[1] <- "2017-02-07 00:00:00"
shiny_data$day <- as.Date(shiny_data$day)

##importing hourly data
library(readr)
shiny_data2 <- read_csv("data/new_data.csv")
shiny_data2[1] <- NULL
shiny_data2 <- shiny_data2[-c(1), ]
shiny_data2 <- shiny_data2[c(4200:4945), ]

##importing annotations yearly
annotations_year <- read_csv("data/annotations_year.csv")
annotations_year <-  annotations_year[c(-1)]
annotations_year <- as.data.frame(annotations_year)

##importing august annotations
annotations_aug <- read_csv("data/aug_annotations.csv")
annotations_aug <- annotations_aug[,-c(1)]


##monthnum dataframe
number <- c( '01','02','03','04','05','06','07','08','09','10','11','12')
month <- c('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
monthnum <- data.frame( "number" = x, "month" = y)

# data
# shiny_data2 <- read_csv("./data/new_data.csv")
# shiny_data2$day[1] <- "2017-02-07 00:00:00"
# shiny_data2$day <- as.POSIXct(shiny_data2$day)

# column options
col <- colnames(shiny_data)

##link creation
createLink <- function(val) {
  sprintf('<a href="https://www.google.com/#q=%s" target="_blank" class="btn btn-primary">Info</a>',val)
}

## Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Charlottesville Emotions"),
  
  # sidebar
  sidebarLayout(
    sidebarPanel(
      ##normalization Factor             
      selectInput("normalizefactor", "Normalization Factor",
                  choices = list("No Normalization" = "None", "Tweet Count" = "tweetcount",
                                 "Word Count" = "WC"), selected = "No Normalization"),
      
      ##normalization type
      selectInput("normalizetype", "Normalization Type",
                  choices = list("Divide" = "Divide", "Multiply" = "Multiply"), selected = "Divide"),
      
      ##Emotion dimensions
      selectInput("yVariable1", "Dimension 1", 
                  choices = col[-1],  selected = "sad", multiple = TRUE),
    
      checkboxInput("annotation", "Add Event Annotations"),
      textInput("plotTitle", "Plot Title"),
      #sliderInput("slide", "Choose tooltip size", min = 1, max = 20, value = 10)
      
      selectInput("Month", "Information Month:",
                  c("All",
                    unique(as.character(annotations_year$Month)))),
      
      selectInput("Day", "Information Day:",
                  c("All",
                    unique(as.character(annotations_year$Day))))
    ),
    
    
    # Show a plot
    mainPanel(
      navbarPage(
        title = 'Emotion Timeframes: ',
        tabPanel("Whole - Timeline", 
                 dygraphOutput("distPlot"),
                 fluidRow( tabsetPanel( id = 'dataset',
                                        tabPanel("Annotation Descriptions", DT::dataTableOutput("annotations_year"))))),
        tabPanel("August",  dygraphOutput("augPlot"),fluidRow( tabsetPanel( id = 'dataset',
                                                                            tabPanel("Annotation Descriptions", DT::dataTableOutput("annotations_aug")))))
        

        )
        )
      )
)
      # ,
      # 
      # tabsetPanel(type = "tabs",
      #             tabPanel("Whole - Timeline", dygraphOutput("distPlot")),
      #             tabPanel("August", dygraphOutput("augPlot"))),
      # 
      # fluidRow(
      # tabsetPanel(
      #   id = 'dataset',
      #   tabPanel("annotations", DT::dataTableOutput("annotations"))a
      # )
      # )


# Define server logic required to draw a histogram
server <- function(input, output) {
  
  ##dataframe for the first window - "whole Timeline" 
  df <- reactive({
    
    
    if(input$normalizefactor == "None"){
      #shiny_data_new <- subset(shiny_data, format.Date(day, "%m")==(monthnum[which(monthnum$month == input$Month),1]))      
      counts <- select(shiny_data, day, tweetcount, input$yVariable1)
    } 
    
    else if (input$normalizetype == "Divide"){
      
      counts <- select(shiny_data, day, tweetcount, input$normalizefactor, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] / c(counts[2]))) %>%
        select(day, tweetcount ,ends_with("1"))
    }
    else if (input$normalizetype == "Multiply"){
      
      counts <- select(shiny_data, day, tweetcount, input$normalizefactor, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] * c(counts[2]))) %>%
        select(day,  tweetcount ,ends_with("1"))
    }
    
    
    dailyCounts <- xts(
      x = counts[,-1],
      order.by = counts$day
    )
    
    dailyCounts
  })
  
  ##dataframe for the second window - august timeline
  df2 <- reactive({
    
    if(input$normalizefactor == "None"){
      counts <- select(shiny_data2, day,tweetcount, input$yVariable1)
    }       
    
    else if (input$normalizetype == "Divide"){
      
      counts <- select(shiny_data2, day, tweetcount, input$normalizefactor, input$yVariable1)
      #browser()
      counts <- bind_cols(counts, (counts[,-c(1,2)] / c(counts[2]))) %>%
        #browser()
        select(day, tweetcount, ends_with("1"))
      print(counts)
      
    }
    else if (input$normalizetype == "Multiply"){
      
      counts <- select(shiny_data2, day, tweetcount, input$normalizefactor, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] * c(counts[2]))) %>%
        select(day, tweetcount, ends_with("1"))
    }
    
    dailyCounts <- xts(
      x = counts[,-1],
      order.by = counts$day
    )
    
    dailyCounts
  })
  
  ##rendering the dygraph - main page
  output$distPlot <- renderDygraph({
    m <- dygraph(df(), main = input$plotTitle) %>% 
      dyRangeSelector() %>%
      dyRoller(rollPeriod = 1) %>%
      dyAxis("y2", label = "tweetcount", independentTicks = TRUE) %>%
      dySeries("tweetcount", axis = 'y2', strokeWidth = 1, strokePattern = "dashed") %>%
      dyShading(from = "2017-08-01", to = "2017-08-31", color = "#FFE6E6")
    
    if(input$annotation){
      m <- m %>%
        dyAnnotation( " 2017-02-06 00:00:00 " , text = " 0 " , tooltip = " Council votes to remove statue " , height = 20) %>%
        dyAnnotation( " 2017-03-22 00:00:00 " , text = " 1 " , tooltip = " Lawsuit filed opposing statue removal " , height = 20) %>%
        dyAnnotation( " 2017-04-17 00:00:00 " , text = " 2 " , tooltip = " Council votes to sell statue " , height = 20) %>%
        dyAnnotation( " 2017-05-13 00:00:00 " , text = " 3 " , tooltip = " Protestors and counter-protestors in Robert E. Lee park " , height = 20) %>%
        dyAnnotation( " 2017-05-06 00:00:00 " , text = " 4 " , tooltip = " Council votes to rename city parks " , height = 20) %>%
        dyAnnotation( " 2017-06-07 00:00:00 " , text = " 5 " , tooltip = " Plaque removed " , height = 20) %>%
        dyAnnotation( " 2017-08-07 00:00:00 " , text = " 6 " , tooltip = " KKK members protest in Justice park " , height = 20) %>%
        dyAnnotation( " 2017-10-08 00:00:00 " , text = " 7 " , tooltip = " Lawsuit filed opposing the movement of Unite the Right rally " , height = 20) %>%
        dyAnnotation( " 2017-11-08 00:00:00 " , text = " 8 " , tooltip = " Unite the Right march starts " , height = 20) %>%
        dyAnnotation( " 2017-12-08 00:00:00 " , text = " 9 " , tooltip = " White nationals and counter-protestors clash, and Heather Heyer is killed " , height = 20) %>%
        dyAnnotation( " 2017-08-13 00:00:00 " , text = " 10 " , tooltip = " Rallies and vigils held, and violence erupts nationwide " , height = 20) %>%
        dyAnnotation( " 2017-08-14 00:00:00 " , text = " 11 " , tooltip = " Fields appears in court " , height = 20) %>%
        dyAnnotation( " 2017-08-16 00:00:00 " , text = " 12 " , tooltip = " Former Presidents advise Trump " , height = 20) %>%
        dyAnnotation( " 2017-08-18 00:00:00 " , text = " 13 " , tooltip = " Mass resignation, and Bannon is fired " , height = 20) %>%
        dyAnnotation( " 2017-08-19 00:00:00 " , text = " 14 " , tooltip = " Boston counter-protestors, and Mnuchin defends Trump " , height = 20)
    }    
    
    m   
  })
  
  ##plot on new tab - august month alone
  output$augPlot <- renderDygraph({
    m <- dygraph(df2(), main = input$plotTitle) %>% 
      dyRangeSelector() %>%
      dyRoller(rollPeriod = 1) %>%
      dyRangeSelector(dateWindow = c("2017-08-11", "2017-08-27")) %>%
      dyAxis("y2", label = "tweetcount", independentTicks = TRUE) %>%
      dySeries("tweetcount", axis = 'y2', strokeWidth = 1, strokePattern = "dashed") #%>%
    #dyShading(from = "2017-08-01", to = "2017-08-31", color = "#FFE6E6")
    
    ##annotations on the graph  
    if(input$annotation){
      m <- m %>%
        dyAnnotation( "2017-08-10 06:00:00" , text = " 0 " , tooltip = " Lawsuit filed opposing the movement of Unite the Right rally " , height = 20) %>%
        dyAnnotation( "2017-08-11 14:55:00" , text = " 1 " , tooltip = " State police and National Guard " , height = 20) %>%
        dyAnnotation( "2017-08-11 19:00:00" , text = " 2 " , tooltip = " University of Virginina march begins " , height = 20) %>%
        dyAnnotation( "2017-08-11 19:11:00" , text = " 3 " , tooltip = " Signer condems UVA march " , height = 20) %>%
        dyAnnotation( "2017-08-11 20:00:00" , text = " 4 " , tooltip = " Court rules Emancipation Park " , height = 20) %>%
        dyAnnotation( "2017-08-12 08:30:00" , text = " 5 " , tooltip = " White nationals and counter-protestors arrive " , height = 20) %>%
        dyAnnotation( "2017-08-12 10:30:00" , text = " 6 " , tooltip = " White nationals and counter-protestors clash " , height = 20) %>%
        dyAnnotation( "2017-08-12 11:35:00" , text = " 7 " , tooltip = " Unlawful assembly " , height = 20) %>%
        dyAnnotation( "2017-08-12 11:52:00" , text = " 8 " , tooltip = " State of emergency " , height = 20) %>%
        dyAnnotation( "2017-08-12 13:19:00" , text = " 9 " , tooltip = " Trump tweents condemnation " , height = 20) %>%
        dyAnnotation( "2017-08-12 13:40:00" , text = " 10 " , tooltip = " Counter-protestors targeted with vehicle " , height = 20) %>%
        dyAnnotation( "2017-08-12 15:30:00" , text = " 11 " , tooltip = " Trump blames many sides " , height = 20) %>%
        dyAnnotation( "2017-08-12 17:00:00" , text = " 12 " , tooltip = " Helicopter crash " , height = 20) %>%
        dyAnnotation( "2017-08-12 17:06:00" , text = " 13 " , tooltip = " Obama quotes Mandela " , height = 20) %>%
        dyAnnotation( "2017-08-12 17:30:00" , text = " 14 " , tooltip = " Marco Rubio tells Trump to act " , height = 20) %>%
        dyAnnotation( "2017-08-12 18:00:00" , text = " 15 " , tooltip = " Governor McAuliffe condems white supremacists " , height = 20) %>%
        dyAnnotation( "2017-08-12 21:45:00" , text = " 16 " , tooltip = " James Alexander Fields Jr. is identifyed " , height = 20) %>%
        dyAnnotation( "2017-08-13 12:50:00" , text = " 17 " , tooltip = " Department of Justice launches an investigation " , height = 20) %>%
        dyAnnotation( "2017-08-13 14:00:00" , text = " 18 " , tooltip = " Jason Kressler's press conference " , height = 20) %>%
        dyAnnotation( "2017-08-13 16:00:00" , text = " 19 " , tooltip = " Rallies and vigils " , height = 20) %>%
        dyAnnotation( "2017-08-13 16:24:00" , text = " 20 " , tooltip = " Marcus Martin " , height = 20) %>%
        dyAnnotation( "2017-08-13 17:30:00" , text = " 21 " , tooltip = " Violence nationwide " , height = 20) %>%
        dyAnnotation( "2017-08-14 10:00:00" , text = " 22 " , tooltip = " Fields appears in court " , height = 20) %>%
        dyAnnotation( "2017-08-13 10:30:00" , text = " 23 " , tooltip = " Fields obsession with Nazism " , height = 20) %>%
        dyAnnotation( "2017-08-14 24:30:00" , text = " 24 " , tooltip = " Trump says racism is evil " , height = 20) %>%
        dyAnnotation( "2017-08-16 24:00:00" , text = " 25 " , tooltip = " Former Presidents denounce racism " , height = 20) %>%
        dyAnnotation( "2017-08-16 22:30:00" , text = " 26 " , tooltip = " Vigil honors those killed/injured " , height = 20) %>%
        dyAnnotation( "2018-08-18 10:08:00" , text = " 27 " , tooltip = " Mass resignation on Committee of the Arts and Humanities " , height = 20) %>%
        dyAnnotation( "2018-08-18 14:20:00" , text = " 28 " , tooltip = " Signer asks for special sessions " , height = 20) %>%
        dyAnnotation( "2018-08-18 16:40:00" , text = " 29 " , tooltip = " Governor McAuliffe denies special sessions " , height = 20) %>%
        dyAnnotation( "2018-08-18 18:00:00" , text = " 30 " , tooltip = " Steve Bannon fired " , height = 20) %>%
        dyAnnotation( "2017-08-19 11:30:00" , text = " 31 " , tooltip = " Boston counter-protestors " , height = 20) %>%
        dyAnnotation( "2017-08-19 20:38:00" , text = " 32 " , tooltip = " Mnuchin defends Trump " , height = 20)
    }
    m   
  })
  
  ##annotation - data table
  output$annotations_year <- DT::renderDataTable({
    DT::datatable({
      data3 <- annotations_year
      if(input$Month != "All")
      {
        data3 <- data3[data3$Month == input$Month,]
      }
      if(input$Day != "All")
      {
        data3 <- data3[data3$Day == input$Day,]
      }
      
      data3
    }, escape = FALSE)
    #annotations_year[annotations_year$Month == input$Month,])#[, input$show_vars, drop = FALSE])   
  })

  ##annotation August - data table
  output$annotations_aug <- DT::renderDataTable({
    DT::datatable({
      data3 <- annotations_aug
      if(input$Month != "All")
      {
        data3 <- data3[data3$Month == input$Month,]
      }
      if(input$Day != "All")
      {
        data3 <- data3[data3$Day == input$Day,]
      }
      
      data3
    }, escape = FALSE)
    #annotations_year[annotations_year$Month == input$Month,])#[, input$show_vars, drop = FALSE])   
  })
  
  }


# Run the application 
shinyApp(ui = ui, server = server)