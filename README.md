# EMOVIS

This repository contains the codes and instructions files for the EMOVIS tool. 

The file project.Rproj is the project file that needs to be loaded to the R studio platform. Once we load this project file to the R studio, we got all the codes of the project inside the R studio cloud.

The files inside the folder "emotion" contain the codes for the visualization tool.  

# Data Source:
EMOVIS is built for a sample dataset of the [Charlottesville Protest Event 2017](https://en.wikipedia.org/wiki/Unite_the_Right_rally) event.  The Twitter Social Media Data related to this event is collected based on the Hashtags related to this event which are manually selected. 

Some of the sample hastags used are as follows: 

## #Add image of the hashtags


# Adding New Data Source:

In order to add new dataset into the EMOVIS tool, the files inside [DATA](https://github.com/kaddynator/EMOVIS/tree/master/emotion) needs to be altered to your specific use case. 

1. [Annotation Year](https://github.com/kaddynator/EMOVIS/blob/master/emotion/data/annotations_year.csv)  :
This file contians the datatable descriptions that appear for the whole protest timeline.
2. [Annotations Specific](https://github.com/kaddynator/EMOVIS/blob/master/emotion/data/aug_annotations.csv) :
This data set contains news information related to the events that happened during the protest timeline during which the protest was taking place actively. 
3. [Hourly Data](https://github.com/kaddynator/EMOVIS/blob/master/emotion/data/shiny_data_hours.csv) :
This Dataset contains emotion details with a precision of hourly basis. 
 
The NEWS descriptions data are collected from trusted internet sources. The sources are mentioned as one of the column in the dataset.  
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTE5NTg2Njc3NTUsMTcyMjUxODc4NywtMT
g2MDU4OTQ3OCwtMTcwMzE4NDcwMywxMjQ0ODEwMTc2LDM5NTQz
MDU2MCwyMTE4NzgyOTA5LC0xNDEwNTkyMDQzLC01NDE2MjU3Nz
UsNDk3MDU3NzQxXX0=
-->