# Melvin's Index

Melvin's Index is method of normalizing cycle threshold values (Ct-values) from quantitative polymerase chain reaction (qPCR) in studies of virus in wastewater. I came up with the method because there was a lot of arguement over what Ct-values meant. That is all fine, cogitate away, but I needed to report some meaningful information to wastewater treatment plant supervisors in rural Minnesota they they could then take to their city councils. The Index acheived my goal and science kept ticking along arguing about Ct-values.

The index performs quantile normalization on data obtained via qPCR after converting to Log(virus copies/ liter). The Indexing protocol includes quantile normalization followed by standardization to an internal control (in this case the Pepper Mild Mottle Virus (PMMoV)) followed by rescaling so that it is all on a 0 to 1.0 scale.

Originally I was used JMP to manually run through the rather tedious process. Rebecca Freese took the process and produced the R-code that you find in this repository.

The original publication is:
Melvin, R.G., Hendrickson, E.N., Chaudhry, N. et al. A novel wastewater-based epidemiology indexing method predicts SARS-CoV-2 disease prevalence across treatment facilities in metropolitan and regional populations. Sci Rep 11, 21368 (2021). https://doi.org/10.1038/s41598-021-00853-y

The code was originally placed at https://github.com/simmonslab/dirtywatercooler. I have copied it here for convenience of finding it by name. Please reference the github repository specified in the publication.
