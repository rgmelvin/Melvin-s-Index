###  Write script to calculate Melvin Index    
###  By Rebecca Freese, BDAC, frees048@umn.edu          
###  Updated: January 20, 2021 

# I suggest using RStudio and not just R. This will make you life a whole lot easier.
##################################################################################################################################

## setup- this section will install and load all necessary packages for the rest of this script. Run this each time you start up R.
packages <- c("data.table", "lubridate", "readxl", "ggplot2", "tidyquant") #list the necessary packages
install.packages(setdiff(packages, rownames(installed.packages())))  #install only those not already installed
lapply(packages, library, character.only = TRUE)

##################################################################################################################################

#Read in and format data
# The variable names referenced here are consistent with the data from from Rich (ex."WasteWaterDataCompilation(13_01_21)withConversion"), and not with the variable names from HST. 

# Change the below file path to that on your computer. I can work on reading this right from Google Drive, but let's get this running first

# type "getwd()" in the consol to find out where R is looking for the file, and then modify or add more direction to get R to look in the right place. For example, I have my wd set to "S:/CTSI_Share/CTSI/BDAC/Projects/freese/Simmons", and inside that folder, I have another folder called "data" with the wastewater dataset. I just need to specify the rest of the file path, "data/file name.xlsx" to get R to find it, but you will pribably need to speciy the whole file path in the code beleow.
data <- setDT(read_excel("data/WasteWaterDataCompilation(13_01_21)withConversion.xlsx"))

data[, SampleDate := dmy(SampleDate)] #formatting sample date
setkey(data, Facility, SampleDate, Target, Repeat, Measure) #ordering data by facility, date, and target

View(data) #take a look. does everything look as expected so far? Cool!

##################################################################################################################################
# Calculate Melvin index. As long as the variable names are the same as I've written here, this next section should run just fine.

# 1) average over over measures within any repeats by facility, date, target and then 2) further averaging over repeats
data <- data[, .(mean_CT = mean(Ct, na.rm = TRUE), 
                 `mean_Log(Copies/L)` = mean(`Log(Copies/L)`, na.rm = TRUE)), 
             by = .(Facility, SampleDate, Target, Repeat)][,
                                                           .(mean_CT = mean(mean_CT, na.rm = TRUE), 
                                                             `mean_Log(Copies/L)` = mean(`mean_Log(Copies/L)`, na.rm = TRUE)), 
                                                           by = .(Facility, SampleDate, Target)]

#assign quantile bin based on distribution of each target - not facility specific, don't include ct = 51 values. 
#can be expanded to find facility specific distributions in the future, if needed.
# play around with probs = 0:5/5 to get different numbers of bins, ex. 0:6/6 for 6, etc.
data[mean_CT != 51, Q5 := cut(`mean_Log(Copies/L)`, quantile(`mean_Log(Copies/L)`, probs = 0:5/5), 
                              labels = FALSE, include.lowest = TRUE), by = Target]

#assign the ct = 51s to the lowest bin
data[mean_CT == 51, Q5 := 1]

#convert to wide format by target
data_wide <- dcast(data[, .(Facility, SampleDate, Target, Q5)],
                   Facility + SampleDate ~ Target, value.var = "Q5")
setnames(data_wide, c("1", "2", "PMMoV"), c("N1_Q5", "N2_Q5", "PMMoV_Q5")) #rename new variables

#standardize Q5 to pepper
data_wide[, `:=`(N1_STD_Q5 = N1_Q5/PMMoV_Q5, 
                 N2_STD_Q5 = N2_Q5/PMMoV_Q5,
                 PMMoV_STD_Q5 = PMMoV_Q5/PMMoV_Q5)]

#add and divide by medians to make scale relative
N1_median <- data[Target == "1", median(`mean_Log(Copies/L)`, na.rm = TRUE)]
N2_median <- data[Target == "2", median(`mean_Log(Copies/L)`, na.rm = TRUE)]
PMMoV_median <- data[Target == "PMMoV", median(`mean_Log(Copies/L)`, na.rm = TRUE)]

data_wide[, `:=`(N1_REL_STD_Q5 = N1_STD_Q5 * (N1_median/PMMoV_median), 
                 N2_REL_STD_Q5 = N2_STD_Q5 * (N2_median/PMMoV_median),
                 PMMoV_REL_STD_Q5 = PMMoV_STD_Q5 * (PMMoV_median/PMMoV_median))]

#natural log relative standard Q5s, add and divide by e 
data_wide[, `:=`(N1_MelvinIndex = (log(N1_REL_STD_Q5)+exp(1))/exp(1),
                 N2_MelvinIndex = (log(N2_REL_STD_Q5)+exp(1))/exp(1), 
                 PMMoV_MelvinIndex = (log(PMMoV_REL_STD_Q5)+exp(1))/exp(1))]

##################################################################################################################################
#make data into long format
data_long <- melt(data_wide, id.vars = c("Facility", "SampleDate"), measure.vars = c("N1_MelvinIndex", "N2_MelvinIndex", "PMMoV_MelvinIndex"),
                  variable.name = "Target", value.name = "MelvinIndex")
data_long[, Target := sub("_MelvinIndex", "", Target)]

theme_set(theme_bw())

#an individual facility plot with exponential weighted moving averages
ggplot(data_long[Facility == "Albert_Lea"], aes(x = SampleDate, y = MelvinIndex, group = Target, color = Target)) + 
  geom_point() + 
  geom_ma(ma_fun = EMA, n = 5, wilder = TRUE) # n here is the number of periods to average over.


