# libraries
library(tidyverse); library(shiny); library(dygraphs); library(xts); library(shinythemes);library(readr)
library(car);library(prophet); library(dplyr); library(forecast); library(reshape); library(anytime);library("ggpubr");

# importing whole data - day-wise
shiny_data <- read_csv("./data/shiny_data.csv")
shiny_data$day[1] <- "2017-02-07 00:00:00"
shiny_data$day <- as.Date(shiny_data$day)
shiny_data <- select(shiny_data,"day","tweetcount", "affect", "posemo", "negemo","anx","anger","sad","WC")

names(shiny_data) <- c("day","tweetcount", "Affect", "Postive Emotion", "Negative Emotion","Anxiety","Anger","Sadness","WordCount")
#colnames(shiny_data) <- c("day","tweetcount", "Affect", "Postive Emotion", "Negative Emotion","Anxiety","Anger","Sadness","W")
#View(shiny_data)

##color pallete configurations
emotionname <- c( "affect", "posemo", "negemo","anx","anger","sad","Tone","WC")
emotioncolor <- c( "#9370DB","#FF8C00","#A52A2A","#008000","#ff0000","#0000ff","#FFC0CB","#000000")
colordata <- data.frame( "ename" = emotionname, "ecolor" = emotioncolor)

##importing hourly data
shiny_data2 <- read_csv("data/new_data.csv")
shiny_data2[1] <- NULL
shiny_data2 <- shiny_data2[-c(1), ]
shiny_data2 <- shiny_data2[c(4200:4945), ]
shiny_data2 <- select(shiny_data2,"day","tweetcount", "affect", "posemo", "negemo","anx","anger","sad","WC")
names(shiny_data2) <- c("day","tweetcount", "Affect", "Postive Emotion", "Negative Emotion","Anxiety","Anger","Sadness","WordCount")
#browser()
#names(shiny_data) <- c("day","tweetcount", "Affect", "Postive Emotion", "Negative Emotion","Anxiety","Anger","Sadness","WC")

##importing annotations yearly
annotations_year <- read_csv("data/year_annotation.csv")
annotations_year <-  annotations_year[c(1:7)]
annotations_year <- as.data.frame(annotations_year)

##importing august annotations
annotations_aug <- read_csv("data/aug_annotations.csv")
annotations_aug <- annotations_aug[,-c(1)]

##monthnum dataframe
number <- c( '01','02','03','04','05','06','07','08','09','10','11','12')
month <- c('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
monthnum <- data.frame( "number" = number, "month" = month)

# column options
col <- colnames(shiny_data)

##link creation
createLink <- function(val) {
  sprintf('<a href="https://www.google.com/#q=%s" target="_blank" class="btn btn-primary">Info</a>',val)
}

## Define UI
ui <- fluidPage(
  
  # see shinythemes and change below for a different theme (https://rstudio.github.io/shinythemes/)
  theme = shinytheme("flatly"),

    ## use shinyjs -------------------------
  shinyjs::useShinyjs(),
  ## include css file --------------------
  tags$head(tags$style(includeCSS("./www/mycss.css"))),
  
h1(tags$img(src = "https://images.wccbcharlotte.com/wp-content/uploads/2018/02/UNC-Charlotte.jpeg", width = "150px", height = "100px"),
    HTML("&nbsp;&nbsp;&nbsp;"),
    "Emotion Timeline Tool", 
    HTML("&nbsp;&nbsp;&nbsp;"),
    tags$img(src = "https://opticscenter.uncc.edu/sites/opticscenter.uncc.edu/files/media/CRI%20new%20logo%20-%20created%20May%2010%202011.jpg", width = "150px", height = "120px"), align = "center"),

h3(
  HTML("&nbsp;&nbsp;&nbsp;"),
  "Charlottesville Protest Data", 
  HTML("&nbsp;&nbsp;&nbsp;"), align = "center"
),

br(),br(),

  # sidebar
  sidebarLayout(
    sidebarPanel(
      ##normalization Factor             
      selectInput("normalizefactor", "Normalization Technique",
                  choices = list("Raw LIWC Intensity" = "None", 
                                 "Average by Tweet Count" = "ATC",
                                 "Average by Word Count" = "AWC",
                                 "Amplify by Tweet count"= "AMTC", 
                                 "Amplify by Word Count"="AMWC"), selected = "No Normalization"),
      
      ##normalization type
      #selectInput("normalizetype", "Normalization Type",choices = list("Average" = "Divide", "Amplify" = "Multiply"), selected = "Divide"),
      
      ##Emotion dimensions
      selectInput("yVariable1", "Select LIWC Emotion Dimension", 
                  choices = col[-1], multiple = TRUE, selected = "tweetcount"),
      
      checkboxInput("annotation", "Add Event Annotations"),
      textInput("plotTitle", "Input Plot Title"),
      #sliderInput("slide", "Choose tooltip size", min = 1, max = 20, value = 10)
      
      selectInput("Month", "Information Displayed by Month",
                  c("All",
                    unique(as.character(annotations_year$Month)))),
      
      selectInput("Day", "Information Displayed by Day",
                  c("All",
                    unique(as.character(annotations_year$Day)))),
      width = 3,br(),
      
      HTML("<hr size = '30'>"),
      (h4)("Sample Emotion Texts"),
      tableOutput("values"),
      (h4)("Sponsored by:"),
      tags$ul(
        tags$li("University of North Carolina - Charlotte, NC"), 
        tags$li("Carolina Research Institute, NC")
      ),br(),
      (h4)("Created by:"),
      tags$ul(
        tags$li(HTML("<a href='https://github.com/kaddynator'>Karthik Ravi </a>")),
        tags$li(HTML("<a href='https://levenslab.uncc.edu/home/lab-personnel/bradley-aleshire/'>Bradley Aleshire</a>")),
        tags$li(HTML("<a href='https://levenslab.uncc.edu/home/lab-personnel/michael-brunswick/'>Michael Brunswick</a>")),
        tags$li(HTML("<a href='https://webpages.uncc.edu/~oeltayeb/'>Omar Eltayeby</a>"))
      ),
      (h4)("Faculty Advisors:"),
      tags$ul(
        tags$li(HTML("<a href='https://webpages.uncc.edu/sshaikh2/'> Dr. Samira Shaikh </a>")),
        tags$li(HTML("<a href='https://levenslab.uncc.edu/'> Dr. Sara Levens </a>")),
        tags$li(HTML("<a href='https://twitter.com/gallicano?lang=en'> Dr. Tiffany Gallicano </a>"))
      )
   ),
    
    
    # Show a plot
    mainPanel(
      navbarPage(
        title = 'Emotion Timeframes: ',
        tabPanel("Protest - Timeline", 
                 dygraphOutput("distPlot"), br(),br(),
        navbarPage(
          title = "Annotation Descriptions", DT::dataTableOutput("annotations_year", width = '900px')
                   )
            ),
        tabPanel("August Protest Events",  dygraphOutput("augPlot"), br(), br(), fluidRow( tabsetPanel( id = 'dataset',
                               tabPanel("Annotation Descriptions", DT::dataTableOutput("annotations_aug", width = '900px'))))),
        
        ##dataset upload window 
        tabPanel("Upload Corner",
                 br(), (h4)("Here we have the option to upload the dataset for analysis"),br(),
                 ('Note: The dataset needs to be processed by LIWC and must contian the specified format'),
                 sidebarLayout(
                  # Sidebar panel for inputs ----
                   sidebarPanel(
                     
                     # Input: Select a file ----
                     fileInput("file1", "Choose the TimeLine Data",
                               multiple = TRUE,
                               accept = c("text/csv",
                                          "text/comma-separated-values,text/plain",
                                          ".csv")),
                     # Input: Select a file ----
                     fileInput("file2", "Choose the Annotations Data",
                               multiple = TRUE,
                               accept = c("text/csv",
                                          "text/comma-separated-values,text/plain",
                                          ".csv")),
                     # Input: Select a file ----
                     fileInput("file3", "Choose the News Content Data",
                               multiple = TRUE,
                               accept = c("text/csv",
                                          "text/comma-separated-values,text/plain",
                                          ".csv")),
                     
                     # Horizontal line ----
                     tags$hr(),
                     
                     # Input: Checkbox if file has header ----
                     checkboxInput("header", "Header", TRUE),
                     
                     # Input: Select separator ----
                     radioButtons("sep", "Separator",
                                  choices = c(Comma = ",",
                                              Semicolon = ";",
                                              Tab = "\t"),
                                  selected = ","),
                     
                     # Input: Select quotes ----
                     radioButtons("quote", "Quote",
                                  choices = c(None = "",
                                              "Double Quote" = '"',
                                              "Single Quote" = "'"),
                                  selected = '"'),
                     
                     # Horizontal line ----
                     tags$hr(),
                     
                     # Input: Select number of rows to display ----
                     radioButtons("disp", "Display",
                                  choices = c(Head = "head",
                                              All = "all"),
                                  selected = "head")
                   ),
                   
                   ## Main panel for displaying csv ----
                   mainPanel(
                     
                     # Output: Data file ----
                     tableOutput("contents")
                     
                   )
                   
                 )
                 ################
        ),
        tabPanel("Insights Corner",
                 br(), (h4)("In this section you can gain insights about the emotion behaviour and interaction between emotions"),br(),
                 dateRangeInput('dateRange_timeseries',
                                label = paste('Select the input Range for which you need to forecast the emotion'),
                                start = '2017-02-07', end = '2017-10-11',
                                min = '2017-02-07', max = '2017-10-11',
                                separator = " - ", format = "dd/mm/yy",
                                startview = 'year', weekstart = 1
                 ),
                 ##Emotion dimensions
                 selectizeInput("TimeSeriesEmotion", "Select Two Emotion for comparision", 
                                choices = col[-1], options = list(maxItems = 2), selected = 'Anger'),
                 
                 verbatimTextOutput("timeseriestext"),
                  
                 #display the table
                 #tableOutput("graph_ts"),
                 
                 #using datatable to display table
                 br(), (h4)("Dataset for Correlation:"),br(),
                 DT::dataTableOutput("ts_dataset_display"),
                 
                 #Heading and plot of correlation
                 br(), (h4)("Correlation Plot:"),br(),
                 
                 plotOutput(outputId = "corrPlot")
                 
              
    ),
    
    tabPanel("Forecast Corner",
          fluidPage(sidebarPanel(width=3,
                            tabsetPanel(
                              ## Tab prophet parameters ----------------------------
                              tabPanel(HTML("Time Series <br> Parameters"),
                                       
                                       ### paramter: growth
                                       h5(tags$b("growth")),
                                       
                                       helpText("If growth is logistic, the input dataframe must have a column cap that specifies the capacity at each ds.",
                                                style = "margin-bottom: 0px;"),
                                       
                                       radioButtons("growth","",
                                                    c('linear','logistic'), inline = TRUE),
                                       
                                       ### parameter: yearly.seasonality
                                       checkboxInput("yearly","yearly.seasonality", value = TRUE),
                                       
                                       ### parameter: weekly.seasonality 
                                       checkboxInput("monthly","weekly.seasonality", value = TRUE),
                                       ### parameter: n.changepoints
                                       numericInput("n.changepoints","n.changepoints", value = 25),
                                       
                                       ### parameter: seasonality.prior.scale
                                       numericInput("seasonality_scale","seasonality.prior.scale", value = 10),
                                       
                                       ### parameter: changepoint.prior.scale
                                       numericInput("changepoint_scale","changepoint.prior.scale", value = 0.05, step = 0.01),
                                       
                                       ### parameter: holidays.prior.scale
                                       numericInput("holidays_scale","holidays.prior.scale", value = 10),
                                       
                                       ### parameter: mcmc.samples
                                       numericInput("mcmc.samples", "mcmc.samples", value = 0),
                                       
                                       ### parameter: interval.width
                                       numericInput("interval.width", "interval.width", value= 0.8, step = 0.1),
                                       ### parameter: uncertainty.samples
                                       numericInput("uncertainty.samples","uncertainty.samples", value = 1000)
                                       ### parameter: holidays
                                       # h5(tags$b("holidays (optional)")),
                                       # 
                                       # helpText("Upload a data frame with columns holiday (character) and ds (date type) and optionally columns lower_window and upper_window which specify a range of days around the date to be included as holidays."),
                                       # 
                                       # fileInput("holidays_file","",
                                       #           accept = c(
                                       #             "text/csv",
                                       #             "text/comma-separated-values,text/plain",
                                       #             ".csv"))
                                       
                              ),
                              
                              ## Tab predict parameters -------------------------
                              tabPanel(HTML("predict <br> Parameters"),
                                       
                                       ## make_future_dataframe() parameters ------------------
                                       ### paramater: periods
                                       numericInput("periods","periods",value=365),
                                       
                                       ### parameter: freq
                                       selectInput("freq","freq",
                                                   choices = c('day', 'week', 'month', 'quarter','year')),
                                       
                                       ### parameter: include_history
                                       checkboxInput("include_history","include_history", value = TRUE)
                              ))
                            
    ),
    
    # Main panel -------------------------
    mainPanel(
      fluidRow(
        ## upload file -----------------
        column(width = 6,
               fileInput("ts_file","Choose CSV File",
                         accept = c(
                           "text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv"))),
        ## plot button -----------------
        column(width = 6,
               shinyjs::disabled(actionButton("plot_btn2", "Fit Time Series Model & Plot",
                                              style = "width:80%; margin-top: 25px;")))
      ),
      
      fluidRow(column(width = 12,
                      uiOutput("msg"))),
      
      fluidRow(column(width = 12,
                      uiOutput("msg2"))),
      
      fluidRow(
        column(width = 12
               # uiOutput("ch_points", style = "width:100")
               # conditionalPanel("input.ch_points_param",
               #                  dateInput("ch_date", "Add changepoints", value = NULL))
        )
      ),
      
      ## plot/results tabs --------------------------------
      fluidRow(column(width=12,
                      tabsetPanel(
                        tabPanel("Forecast Plot",
                                 conditionalPanel("input.plot_btn2",
                                                  div(id = "output-container1",
                                                      #tags$img(src = "spinner.gif", id = "loading-spinner"),
                                                      plotOutput("ts_plot")
                                                  )
                                 )
                        ),
                        tabPanel("Time Series Plot Components",
                                 # output.logistic_check=='no_error'
                                 conditionalPanel("input.plot_btn2",
                                                  div(id = "output-container2",
                                                      #tags$img(src = "spinner.gif", id = "loading-spinner"),
                                                      plotOutput("prophet_comp_plot")
                                                  )
                                 )
                        ),
                        
                        tabPanel("Forecast Results",
                                 conditionalPanel("output.data",
                                                  uiOutput("dw_button")
                                 ),
                                 
                                 # uiOutput("dw_button"),
                                 conditionalPanel("input.plot_btn2",
                                                  div(id = "output-container3",
                                                      tags$img(src = "spinner.gif",
                                                               id = "loading-spinner"),
                                                      dataTableOutput("data")))
                                 
                        )
                      )
      )
      ),
      
      ## test output --------
      verbatimTextOutput("test")
    )
    )
    
    )
    )
    )
   )
)

## Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  ##dataframe for the first window - "whole Timeline" 
  df <- reactive({
    
    if(input$normalizefactor == "None"){
      #shiny_data_new <- subset(shiny_data, format.Date(day, "%m")==(monthnum[which(monthnum$month == input$Month),1]))      
      counts <- select(shiny_data, day, tweetcount, input$yVariable1)
      #browser()
    } 
    
    else if (input$normalizefactor == "ATC"){
      
      counts <- select(shiny_data, day, tweetcount, tweetcount, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] / c(counts[2]))) %>%
        select(day, tweetcount ,ends_with("1"))
    }
    else if (input$normalizefactor == "AWC"){
      
      counts <- select(shiny_data, day, tweetcount, WordCount, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] / c(counts[2]))) %>%
        select(day,  tweetcount ,ends_with("1"))
    }
    else if (input$normalizefactor == "AMTC"){
      
      counts <- select(shiny_data, day, tweetcount, tweetcount, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] * c(counts[2]))) %>%
        select(day,  tweetcount ,ends_with("1"))
    }
    else if (input$normalizefactor == "AMWC"){
      
      counts <- select(shiny_data, day, tweetcount, WordCount, input$yVariable1)
      
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
    
    else if (input$normalizefactor == "ATC"){
      
      counts <- select(shiny_data2, day, tweetcount, tweetcount, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] / c(counts[2]))) %>%
        select(day, tweetcount ,ends_with("1"))
    }
    else if (input$normalizefactor == "AWC"){
      
      counts <- select(shiny_data2, day, tweetcount, WordCount, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] / c(counts[2]))) %>%
        select(day,  tweetcount ,ends_with("1"))
    }
    else if (input$normalizefactor == "AMTC"){
      
      counts <- select(shiny_data2, day, tweetcount, tweetcount, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] * c(counts[2]))) %>%
        select(day,  tweetcount ,ends_with("1"))
    }
    else if (input$normalizefactor == "AMWC"){
      
      counts <- select(shiny_data2, day, tweetcount, WordCount, input$yVariable1)
      
      counts <- bind_cols(counts, (counts[,-c(1,2)] * c(counts[2]))) %>%
        select(day,  tweetcount ,ends_with("1"))
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
      dySeries("tweetcount", axis = 'y2', strokeWidth = 1, strokePattern = "dashed")%>%
      dyOptions(maxNumberWidth = 20, axisLineWidth = 1.5, strokeWidth = 1.5) %>%  
      dyRangeSelector(retainDateWindow=TRUE)%>%
      dyShading(from = "2017-08-01", to = "2017-08-31", color = "#FFE6E6")
    
    if(input$annotation){
      m <- m %>%
        #dyAnnotation( as.Date(annotations_year$Date[2]) , text = " 0 " , tooltip = " Council votes to remove statue " , height = 20)
        dyAnnotation( " 2017-02-06 00:00:00 " , text = " 1 " , tooltip = " Council votes to remove statue " , height = 20) %>%
        dyAnnotation( " 2017-03-22 00:00:00 " , text = " 2 " , tooltip = " Lawsuit filed opposing statue removal " , height = 20) %>%
        dyAnnotation( " 2017-04-17 00:00:00 " , text = " 3 " , tooltip = " Council votes to sell statue " , height = 20) %>%
        dyAnnotation( " 2017-05-13 00:00:00 " , text = " 4 " , tooltip = " Protestors and counter-protestors in Robert E. Lee park " , height = 20) %>%
        dyAnnotation( " 2017-06-05 00:00:00 " , text = " 5 " , tooltip = " Council votes to rename city parks " , height = 20) %>%
        dyAnnotation( " 2017-07-06 00:00:00 " , text = " 6 " , tooltip = " Plaque removed " , height = 20) %>%
        dyAnnotation( " 2017-07-08 00:00:00 " , text = " 7 " , tooltip = " KKK members protest in Justice park " , height = 20) %>%
        dyAnnotation( " 2017-08-10 00:00:00 " , text = " 8 " , tooltip = " Lawsuit filed opposing the movement of Unite the Right rally " , height = 20) %>%
        dyAnnotation( " 2017-08-11 00:00:00 " , text = " 9 " , tooltip = " Unite the Right march starts " , height = 20) %>%
        dyAnnotation( " 2017-08-12 00:00:00 " , text = " 10 " , tooltip = " White nationals and counter-protestors clash, and Heather Heyer is killed " , height = 20) %>%
        dyAnnotation( " 2017-08-13 00:00:00 " , text = " 11 " , tooltip = " Rallies and vigils held, and violence erupts nationwide " , height = 20) %>%
        dyAnnotation( " 2017-08-14 00:00:00 " , text = " 12 " , tooltip = " Fields appears in court " , height = 20) %>%
        dyAnnotation( " 2017-08-16 00:00:00 " , text = " 13 " , tooltip = " Former Presidents advise Trump " , height = 20) %>%
        dyAnnotation( " 2017-08-18 00:00:00 " , text = " 14 " , tooltip = " Mass resignation, and Bannon is fired " , height = 20) %>%
        dyAnnotation( " 2017-08-19 00:00:00 " , text = " 15 " , tooltip = " Boston counter-protestors, and Mnuchin defends Trump " , height = 20)
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
      dySeries("tweetcount", axis = 'y2', strokeWidth = 1, strokePattern = "dashed")%>%
      dyRangeSelector(retainDateWindow=TRUE)%>%
      dyOptions(maxNumberWidth = 20, axisLineWidth = 1.5, strokeWidth = 1.5) %>% 
      dyOptions(useDataTimezone = TRUE) #%>%
    #dyShading(from = "2017-08-01", to = "2017-08-31", color = "#FFE6E6")
    
    ##annotations on the graph  
    if(input$annotation){
      m <- m %>%
        dyAnnotation( "2017-08-10 06:00:00" , text = " 0 " , tooltip = " Lawsuit filed opposing the movement of Unite the Right rally " , height = 20) %>%
        dyAnnotation( "2017-08-11 15:00:00" , text = " 1 " , tooltip = " State police and National Guard " , height = 20) %>%
        dyAnnotation( "2017-08-11 19:00:00" , text = " 2, 3 " , tooltip = " University of Virginina march begins, Signer condems UVA march " , height = 20,width = 30) %>%
        #dyAnnotation( "2017-08-11 19:00:00" , text = " 3 " , tooltip = " Signer condems UVA march " , height = 20) %>%
        dyAnnotation( "2017-08-11 20:00:00" , text = " 4 " , tooltip = " Court rules Emancipation Park " , height = 20) %>%
        dyAnnotation( "2017-08-12 09:00:00" , text = " 5 " , tooltip = " White nationals and counter-protestors arrive " , height = 20) %>%
        dyAnnotation( "2017-08-12 11:00:00" , text = " 6 " , tooltip = " White nationals and counter-protestors clash " , height = 20) %>%
        dyAnnotation( "2017-08-12 12:00:00" , text = " 7, 8 " , tooltip = " Unlawful assembly, State of emergency " , height = 20,width = 30) %>%
        #dyAnnotation( "2017-08-12 12:00:00" , text = " 8 " , tooltip = " State of emergency " , height = 20) %>%
        dyAnnotation( "2017-08-12 13:00:00" , text = " 9 " , tooltip = " Trump tweents condemnation " , height = 20) %>%
        dyAnnotation( "2017-08-12 14:00:00" , text = " 10 " , tooltip = " Counter-protestors targeted with vehicle " , height = 20) %>%
        dyAnnotation( "2017-08-12 16:00:00" , text = " 11 " , tooltip = " Trump blames many sides " , height = 20) %>%
        dyAnnotation( "2017-08-12 17:00:00" , text = " 12 " , tooltip = " Helicopter crash " , height = 20) %>%
        dyAnnotation( "2017-08-12 17:00:00" , text = " 13 " , tooltip = " Obama quotes Mandela " , height = 20) %>%
        dyAnnotation( "2017-08-12 18:00:00" , text = "14,15" , tooltip = " Marco Rubio tells Trump to act, Governor McAuliffe condems white supremacists " , height = 20,width = 40) %>%
        #dyAnnotation( "2017-08-12 18:00:00" , text = " 15 " , tooltip = " Governor McAuliffe condems white supremacists " , height = 20) %>%
        dyAnnotation( "2017-08-12 22:00:00" , text = " 16 " , tooltip = " James Alexander Fields Jr. is identifyed " , height = 20) %>%
        dyAnnotation( "2017-08-13 11:00:00" , text = " 17 " , tooltip = " Fields obsession with Nazism " , height = 20) %>%
        dyAnnotation( "2017-08-13 13:00:00" , text = " 18 " , tooltip = " Department of Justice launches an investigation " , height = 20) %>%
        dyAnnotation( "2017-08-13 14:00:00" , text = " 19 " , tooltip = " Jason Kressler's press conference " , height = 20) %>%
        dyAnnotation( "2017-08-13 16:00:00" , text = "21,20" , tooltip = " Rallies and vigils, Marcus Martin " , height = 20,width = 40) %>%
        #dyAnnotation( "2017-08-13 16:00:00" , text = " 21 " , tooltip = " Marcus Martin " , height = 20) %>%
        dyAnnotation( "2017-08-13 18:00:00" , text = " 22 " , tooltip = " Violence nationwide " , height = 20) %>%
        dyAnnotation( "2017-08-14 10:00:00" , text = " 23 " , tooltip = " Fields appears in court " , height = 20) %>%
        dyAnnotation( "2017-08-14 25:00:00" , text = " 24 " , tooltip = " Trump says racism is evil " , height = 20) %>%
        dyAnnotation( "2017-08-16 23:00:00" , text = " 25 " , tooltip = " Vigil honors those killed/injured " , height = 20) %>%
        dyAnnotation( "2017-08-16 24:00:00" , text = " 26 " , tooltip = " Former Presidents denounce racism " , height = 20) %>%
        dyAnnotation( "2018-08-18 10:00:00" , text = " 27 " , tooltip = " Mass resignation on Committee of the Arts and Humanities " , height = 20) %>%
        dyAnnotation( "2018-08-18 14:00:00" , text = " 28 " , tooltip = " Signer asks for special sessions " , height = 20) %>%
        dyAnnotation( "2018-08-18 17:00:00" , text = " 29 " , tooltip = " Governor McAuliffe denies special sessions " , height = 20) %>%
        dyAnnotation( "2018-08-18 18:00:00" , text = " 30 " , tooltip = " Steve Bannon fired " , height = 20) %>%
        dyAnnotation( "2017-08-19 12:00:00" , text = " 31 " , tooltip = " Boston counter-protestors " , height = 20) %>%
        dyAnnotation( "2017-08-19 21:00:00" , text = " 32 " , tooltip = " Mnuchin defends Trump " , height = 20)
    }
    m   
  })
  
  ##annotation - data table
  output$annotations_year <- DT::renderDataTable({
    DT::datatable({
      data3 <- annotations_year
      data3$Link <- gsub('N/A', '', data3$Link)
      data3$'Secondary Link' <- gsub('N/A', '', data3$'Secondary Link')
      data3$Link <- paste0("<a href='",data3$Link,"'target='_blank'>",data3$Link,"</a>")
      data3$'Secondary Link' <- paste0("<a href='",data3$'Secondary Link',"'target='_blank'>",data3$'Secondary Link',"</a>")
      if(input$Month != "All")
      {
        data3 <- data3[data3$Month == input$Month,]
      }
      if(input$Day != "All")
      {
        data3 <- data3[data3$Day == input$Day,]
      }
      data3 <- data3[,c(-2)]
      
      data3
    }, escape = FALSE,
    options = list(pageLength = 5, autoWidth = TRUE),
    rownames= FALSE
    
    #options = list(autoWidth = TRUE
                   # columnDefs = list(list(targets=c(0), visible=TRUE, width='10'),
                   #                   list(targets=c(1), visible=TRUE, width='70'),
                   #                   list(targets=c(2), visible=TRUE, width='70'),
                   #                   list(targets=c(3), visible=TRUE, width='300'),
                   #                   list(targets=c(4), visible=TRUE, width='300'),
                   #                   list(targets=c(5), visible=TRUE, width='70'),
                   #                   list(targets=c(6), visible=TRUE, width='70'),
                   #                   list(targets='_all', visible=FALSE)),
                   # deferRender=TRUE,
                   # scrollX=TRUE,scrollY=400,
                   # scrollCollapse=TRUE
    )
    #annotations_year[annotations_year$Month == input$Month,])#[, input$show_vars, drop = FALSE])   
  })
  
  ##annotation August - data table
  output$annotations_aug <- DT::renderDataTable({
    DT::datatable({
      data3 <- annotations_aug[,-c(2,3,4,5)]
      data3$Link <- paste0("<a href='",data3$Link,"'target='_blank'>",data3$Link,"</a>")
      if(input$Month != "All")
      {
        data3 <- data3[data3$Month == input$Month,]
      }
      if(input$Day != "All")
      {
        data3 <- data3[data3$Day == input$Day,]
      }
      
      data3
    }, escape = FALSE,
    options = list(autoWidth = TRUE,
                   columnDefs = list(list(targets=c(0), visible=TRUE, width='10'),
                                     list(targets=c(1), visible=TRUE, width='10'),
                                     list(targets=c(2), visible=TRUE, width='105'),
                                     list(targets=c(3), visible=TRUE, width='300'),
                                     list(targets=c(4), visible=TRUE, width='300'),
                                     list(targets=c(5), visible=TRUE, width='50'),
                                     list(targets='_all', visible=FALSE)),
                   deferRender=TRUE,
                   scrollX=TRUE,scrollY=400,
                   scrollCollapse=TRUE
                   ))
    #annotations_year[annotations_year$Month == input$Month,])#[, input$show_vars, drop = FALSE])   
  })
  
  ##display table under slidebar
  output$values <- renderTable({
    Emotion.Category <- c("Affect","Sadness","Angry","Positive Emotion","Negative Emotion","Anxiety")
    Examples.Text <- c("happy, cried","crying, grief, sad","hate, kill, annoyed","love, nice, sweet","hurt, ugly, nasty","worried, fearful")
    data.frame(Emotion.Category,Examples.Text)
    })
  
  ##csv file output
  output$contents <- renderTable({
    
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.
    
    req(input$file1)
    
    df <- read.csv(input$file1$datapath,
                   header = input$header,
                   sep = input$sep,
                   quote = input$quote) 
    if(input$disp == "head") {
      return(head(df))
    }
    else {
      return(df)
    }
    
    })
  
  ## time series forecast
  output$timeseriestext <- renderText({
    paste("For the Input Range :", 
          paste(as.character(input$dateRange_timeseries), collapse = " to "),
          "with the Emotion Selected as ", 
          paste(as.character(input$TimeSeriesEmotion))
      )
    })
  
  ##Display the Dataframe of the Time Series
  output$ts_dataset_display <- DT::renderDataTable({
      DT::datatable({
        shiny_data_ts <- (with(shiny_data2, shiny_data2[(day >=input$dateRange_timeseries[1]  & day <= input$dateRange_timeseries[2]),]))
        myvars <- c("day",input$TimeSeriesEmotion)
        shiny_data_ts <- shiny_data_ts[myvars]
        is.num <- sapply(shiny_data_ts, is.numeric)
        shiny_data_ts[is.num] <- lapply(shiny_data_ts[is.num], round, 4)
        shiny_data_ts$day = structure(shiny_data_ts$day,class=c('POSIXt','POSIXct'))
        shiny_data_ts
      }, escape = FALSE,
      options = list(pageLength = 5, autoWidth = TRUE),
      rownames= FALSE
      )
    })
  
  ##correlaiton plot
  output$corrPlot <- renderPlot({
    shiny_data_ts <- (with(shiny_data2, shiny_data2[(day >=input$dateRange_timeseries[1]  & day <= input$dateRange_timeseries[2]),]))
    myvars <- c("day",input$TimeSeriesEmotion)
    shiny_data_ts <- shiny_data_ts[myvars]
    is.num <- sapply(shiny_data_ts, is.numeric)
    shiny_data_ts[is.num] <- lapply(shiny_data_ts[is.num], round, 4)
    shiny_data_ts$day = structure(shiny_data_ts$day,class=c('POSIXt','POSIXct'))
    ggscatter(shiny_data_ts, x = myvars[1], y = myvars[2], 
              add = "reg.line", conf.int = TRUE, 
              cor.coef = TRUE, cor.method = "pearson",
              xlab = myvars[2], ylab = myvars[3])
    
    # x    <- faithful$waiting
    # bins <- seq(min(x), max(x), length.out = input$bins + 1)
    # hist(x, breaks = bins, col = "#75AADB", border = "white",
    #      xlab = "Waiting time to next eruption (in mins)",
    #      main = "Histogram of waiting times")
    
  })
  
  ######prophet
  
  ## function: duplicatedRecative values -----------------------------
  duplicatedRecative <- function(signal){
    values <- reactiveValues(val="")
    
    observe({
      values$val <- signal()
    })
    
    reactive(values$val)
  }
  
  ## read csv file data----------
  dat <- reactive({
    req(input$ts_file)
    
    file_in <- input$ts_file
    # read csv
    read.csv(file_in$datapath, header = T) %>% mutate(y = log(y))  
  })
  
  ## Toggle submit button state according to data ---------------
  observe({
    if(!(c("ds","y") %in% names(dat()) %>% mean ==1))
      shinyjs::disable("plot_btn2")
    else if(c("ds","y") %in% names(dat()) %>% mean ==1)
      shinyjs::enable("plot_btn2")
  })
  
  ## get holidays -------------
  holidays_upload <- reactive({
    if(is.null(input$holidays_file)) h <- NULL
    else h <- read.csv(input$holidays_file$datapath, header = T) 
    return(h)
  })
  
  ## logistic_check -------------------
  logistic_check <- eventReactive(input$plot_btn2, {
    # req(dat())
    if( (input$growth == "logistic") & !("cap" %in% names(dat())) )
    {
      return("error")
    }
    else 
      return("no_error")
  })
  
  ## create Time Series model -----------
  prophet_model <- eventReactive(input$plot_btn2,{
    req(dat(), 
        # ("ds" %in% dat()), "y" %in% names(dat()),
        input$n.changepoints,
        input$seasonality_scale, input$changepoint_scale,
        input$holidays_scale, input$mcmc.samples,
        input$mcmc.samples, input$interval.width,
        input$uncertainty.samples)
    
    
    
    if(input$growth == "logistic"){
      validate(
        need(try("cap" %in% names(dat())),
             "Error: for logistic 'growth', the input dataframe must have a column 'cap' that specifies the capacity at each 'ds'."))
      
    }
    
    # if(!identical(rv$dat_last[[1]],rv$dat_last[[2]]))
    #         
    # {
    #
    # mutate dataframe
    datx <- dat() %>% 
      mutate(y = log(y))
    
    kk <- prophet(datx,
                  growth = input$growth,
                  changepoints = NULL,
                  n.changepoints = input$n.changepoints,
                  yearly.seasonality = input$yearly,
                  weekly.seasonality = input$monthly,
                  holidays = holidays_upload(),
                  seasonality.prior.scale = input$seasonality_scale,
                  changepoint.prior.scale = input$changepoint_scale,
                  holidays.prior.scale = input$holidays_scale,
                  mcmc.samples = input$mcmc.samples,
                  interval.width = input$interval.width,
                  uncertainty.samples = input$uncertainty.samples,
                  fit = T)
    # print(kk$changepoints)
    
    return(kk)
    
    # } else
    #         return(p_model())
    
  })
  
  ## dup reactive --------------
  p_model <- duplicatedRecative(prophet_model)
  
  ## Make dataframe with future dates for forecasting -------------
  future <- eventReactive(input$plot_btn2,{
    req(p_model(),input$periods, input$freq)
    make_future_dataframe(p_model(),
                          periods = input$periods,
                          freq = input$freq,
                          include_history = input$include_history)
  })
  
  ## dup reactive --------------
  p_future <- duplicatedRecative(future)
  
  ## predict future values -----------------------
  forecast <- reactive({
    req(prophet_model(),p_future())
    predict(prophet_model(),p_future())
  })
  
  ## dup reactive --------------
  p_forecast <- duplicatedRecative(forecast)
  
  ## plot forecast -------------
  output$ts_plot <- renderPlot({
    # req(logistic_check()!="error")
    g <- plot(p_model(), forecast())
    g+theme_classic()
  })
  
  ## plot prophet components --------------
  output$prophet_comp_plot <- renderPlot({
    # req(logistic_check()!="error")
    prophet_plot_components(p_model(),forecast())
  })
  
  ## create datatable from forecast dataframe --------------------
  output$data <- renderDataTable({
    # req(logistic_check()!="error")
    datatable(forecast()) %>% 
      formatRound(columns=2:17,digits=4)
  })
  
  ## download button ----------------
  output$dw_button <- renderUI({
    
    req(forecast())
    downloadButton('downloadData', 'Download Data',
                   style = "width:20%;
                   margin-bottom: 25px;
                   margin-top: 25px;")
  })
  
  output$downloadData <- downloadHandler(
    filename = "forecast_data.csv",
    content = function(file) {
      write.csv(forecast(), file)
    }
  )
  
  ## error msg ------------------------
  output$msg <- renderUI({
    if(c("ds","y") %in% names(dat()) %>% mean !=1)
      "Invalid Input: dataframe should have at least two columns named (ds & y)"
  })
  # 
  # error msg2 ------------------------
  # output$msg2 <- renderUI({
  #         if(logistic_check()=="error")
  #         "Error"
  # })
  
  ## output test --------------
  # output$test <- renderPrint({
  #         # forecast() %>% length()
  # })
  
  
}

# Run the application 
shinyApp(ui = ui, server = server)