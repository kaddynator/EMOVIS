library(car);library(prophet); library(dplyr);
library(tidyverse); library(xts); library(shinythemes);library(readr);
library(forecast); library(reshape);

shiny_data <- read_csv("./emotion/data/new_data.csv")
shiny_data$day[1] <- "2017-02-07 00:00:00"
shiny_data$day <- as.Date(shiny_data$day)

shiny_data2 <- with(shiny_data, shiny_data[(day >= "2017-03-04" & day <= "2017-04-04"),])
            
## subsetting the dataset with one column of date and the other for emotion
myvars <- c("day","anger")
df <- shiny_data2[myvars]

# Parse date column
df <- mutate (
  df,
  ds = day,  # Create new ds column from date using mutate
  y = anger   # Create new y column from value using mutate
)

df <- column_to_rownames(df, var = "day")

# The BoxCox.lambda() function will choose a value of lambda
lam = BoxCox.lambda(df$anger, method = c("guerrero", "loglik"))
df$y = BoxCox(df$anger, lam)
df.m <- melt(df, measure.vars=c("anger", "y"))

## time series using prophet

m <- prophet(df)

future <- make_future_dataframe(m, periods = 1000, freq = 3600)
forecast <- predict(m, future)

plot(m, forecast)

prophet_plot_components(m, forecast)

inverse_forecast <- forecast
#inverse_forecast <- column_to_rownames(inverse_forecast, var = "ds")
inverse_forecast$yhat_untransformed = InvBoxCox(forecast$yhat, lam)
plot(m, inverse_forecast)
prophet_plot_components(m, inverse_forecast)

