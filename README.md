# SAS 9.4 Missing Data Imputation and Analyses Code with User Guide

This imputation and analysis code with a user guide is a supplement to a study titled: 

How Much Missing Accelerometer Outcome Data is Too Much to Impute in a Small Sample
Randomized Control Trial? A SAS Tutorial for Missing Data Handling and Analyses

Diego Arguello

Department of Health Science, Northeastern University Boston, MA 
& Department of Medicine, Massachussetts General Hospital Boston, MA 

This code was written for SAS 9.4 and provides a step-by-step guide on best practice methods for imputing and analyzing a sample (3-group x 2-timepoint)
randomized control trial (RCT) dataset containing arbitrary missing physical behavior data observations under the missing at random assumption. 
In this example we consider an yearlong RCT setting where physical behaviors (i.e., sedentary, standing and stepping time) were objectively measured
from accelerometers and some observations are missing, thus reducing the statistical power to detect effects of the interventions. The aim is
to compare the intervention's effects on mean daily sedentary, standing, and stepping time within- and between-groups across repeated measures. The imputation methodology presented in this code is applicable to various other study designs when measuring physical behavior outcomes (e.g., observational studies, RCTs with a different number of randomization groups or repeated measures, or missing days in 24-hour wear protocols), and the code may be modifiable by researchers familiar with SAS 9.4 to accommodate different study designs. 

Description of Dataset "SampleMissing" that accompanies SAS code: 

"SampleMissing.csv" (CSV Format) and "samplemissing.sas7bdat" (SAS 9.4 Format) contain baseline and month-12 follow-up 
data on three physical activity outcomes of interest (mean daily sedentary, standing and stepping hours) from the complete case sample (N=42) of 
a cluster RCT titled, "Modifying the Workplace to Decrease Sedentary Behavior and Improve Health", where 
subjects were randomized into one of three study conditions: seated control (N=13), sit-to-stand desk (N=13), 
or treadmill desk (N=16) and the objective was to study the effects of these active workstations on physical 
behavior change. To simulate missing at random data in this example, 3 observations were removed for each of the 
three physical activity outcomes of interest from each study group at both baseline and month-12 timepoints 
(i.e., total missing data 21.4%) using random sampling with replacement (see manuscript for details). 
The dataset is formatted in long format whereby each group's data is stacked by timepoint in consequent order.
