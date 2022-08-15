/*
How Much Missing Accelerometer Outcome Data is Too Much to Impute in a Small Sample
Randomized Control Trial? A SAS Tutorial for Missing Data Handling and Statistical Analyses

Imputation and Analyses Code with User Guide 

Diego Arguello, Anne N. Thorndike, Gregory Cloutier, Carmen Castaneda-Sceppa, John Griffith, and Dinesh John

Department of Health Science, Northeastern University Boston, MA 
& Department of Medicine, Massachussetts General Hospital Boston, MA 


The code below provides a step-by-step guide on best practice methods for imputing and analyzing a sample (3-group x 2-timepoint)
randomized control trial (RCT) dataset containing arbitrary missing physical behavior data observations under the missing at random assumption. 
In this example we consider an yearlong RCT setting where physical behaviors (i.e., sedentary, standing and stepping time) were objectively measured
from accelerometers and some observations are missing, thus reducing the statistical power to detect effects of the interventions. The aim is
to compare the intervention's effects on mean daily sedentary, standing, and stepping time within- and between-groups across repeated measures.
*/ 

/*Step 1: Setup File Directory, Import and format Dataset*/ 

	/*Step 1a: Create Local Library to store Outputs. 

Here a folder titled "SampleImputation" has been created in the local documents directory and called 
as the directory to store files using the SAS "Libname" function denoting the libary name within SAS as "SampleI".*/ 

Libname SampleI "C:\Users\diego\Documents\SampleImputation"; 

	/*Step 1b: Import Dataset: 

Description of Dataset "SampleMissing": 

"SampleMissing.csv" contains baseline and month-12 follow-up data on three physical activity outcomes 
of interest (mean daily Sedentary, standing and stepping hours) from the complete case sample (N=42) of 
our cluster RCT, "Modifying the Workplace to Decrease Sedentary Behavior and Improve Health", where 
subjects were randomized into one of three study conditions: seated control (N=13), sit-to-stand desk (N=13), 
or treadmill desk (N=16) and the objective was to study the effects of these active workstations on physical 
behavior change. To simulate missing at random data in this example, 3 observations were removed for each of the 
three physical activity outcomes of interest from each study group at both baseline and month-12 timepoints 
(i.e., total missing data 21.4%) using random sampling with replacement (see manuscript for details). 
The dataset is formatted in long format whereby each group's data is stacked by timepoint in consequent order.

Variable Summary: 
a. Physical Activity Outcomes: denoted as Sedentary, standing and stepping for short.  
b. Identifier variables:
	i. CompGroup: six comparison groups of interest denoting the randomization group*timepoint interaction term of interest. 

		1= "Seated Control Baseline"
		2= "Sit-to-Stand Desk Baseline"
		3= "Treadmill Desk Baseline"
		4= "Seated Control Month-12"
		5= "Sit-to-Stand Desk Month-12"
		6= "Treadmill Desk Month-12"

	ii. Participant_ID: 42 unique IDs with repeated measures (Baseline to Month-12 Follow-up),
		"WS" is short for "Workstation Study". 

		Seated Control group participant IDs: WS01, WS10, WS12, WS14, WS21, WS22, WS24, WS25, WS26, WS37, WS45, WS67, WS70
		Sit-to-Stand Desk group participant IDs: WS04, WS05, WS06, WS07, WS08, WS09, WS11, WS27, WS61, WS62, WS63, WS64, WS66
		Treadmill Desk group participant IDs: WS02, WS17, WS29, WS30, WS31, WS32, WS33, WS34, WS35, WS36, WS54, WS56, WS57, WS58, WS59, WS60

	iii. Age__Years_: subject age at the start of the trial
	iv. Gender: M=Male, F=Female 
	v. Ethnicity: Non-hisp= not hispanic, hisp= hispanic
	vi. Race: AA-Blk= African American/Black, Cauc= Caucasian, Asian, and Other. 
	vii. Hypertension: history of hypertension yes or no. 
	viii. Diabetes: history of diabetes yes or no. 
	ix. Rand: randomization group- seated desk control, sit-to-stand desk and treadmill desk. 
	x. Cluster: 20 unique cluster IDs that the 42 respective subjects were assigned to. We note that while this was 
	   a cluster randomized trial design we found no significant effects of cluster randomization on the physical activity 
	   outcomes of interest (See: Arguello D, Thorndike AN, Cloutier G, Morton A, Castaneda-Sceppa C, John D. Effects of an 
	   "Active-Workstation" Cluster RCT on Daily Waking Physical Behaviors. Med Sci Sports Exerc. 2021 Jul 1;53(7):1434-1445. 
	   doi: 10.1249/MSS.0000000000002594. PMID: 33449603; PMCID: PMC8205935.). Therefore, we chose to impute missing data and 
	   analyze study effects at the participant-group level while accounting for the statistically insignifant random effect 
	   of cluster randomization design in our final statisical analysis using linear mixed models (see details in manuscript). 

		Seated Desk Control group cluster IDs: 1, 7, 8, 10, 21, 23
		Sit-to-Stand Desk group cluster IDs: 2, 4, 5, 6, 16, 19, 20, 22
		Treadmill Desk group cluster IDs: 3, 9, 11, 15, 17, 18

	xi. Timepoint: 1= baseline, 2= Month-12 Follow-up 

c. Health Outcome Variables: these are the auxilliary variables that are used in the consequent steps below to perform 
   joint multiple imputation of missing data in the physical activity outcomes of interest. As such, these variables
   contain no missing data. The auxilliary variables in our sample dataset consist of four categories of health outcome
   variables measured in our RCT. 

	i. Anthropometrics: Body_Weight_kg= body mass from digital scale in kg, Height_cm, Waist_Circ__cm and Hip_Circ__cm = waist and hip
	   circumference in cm, Waist_Hip_Ratio = waist to hip circumferenc ratio, and BMI= body mass index in kg/m^2. 
	ii. Hemodynamics: SBP_mmHg and DBP_mmHg = resting systolic and diastolic blood pressure measured in mmHg, and HR_BPM= 
		resting heart rate in beats per minute. 
	iii. Blood Biomarkers (Fasted 12 hours): HbA1C= hemoglobin-A1C (%), and Glucose, Insulin, Fibrinogen, Cortisol, TNF_Alpha= tumor necrosis 
		 factor alpha, IGF_1= insulin-like growth factor 1, IL_6= Interleukin 6, Total_Chol= total cholesterol, LDL= low-density lipoprotein,
		 HDL= high-density lipoprotein and Triglycerides all in mg/dL. 
	iv. Body Composition measured via Dual Energy Absorptiometry (DXA): DXA_FFM= Fat-Free Mass in kg, DXA_Fat_mass= Fat Mass in kg, Total_BMD=
		Bone Mineral Density in g/cm^2, Total_BMC= Bone Mineral Content in g, Lean_Mass in kg, Lean_Mass_Perc (%), Total_Mass= body mass via DXA in kg, 
		Body_Fat_Perc (%), Android_Fat_Perc (%), Gynoid_Fat_Perc (%), Android_Gynoid_Ratio= android to gynoid fat ratio, 
		Fat_Mass_HeightSquared_Ratio= fat mass to height squared ratio, Trunk_Fat_Perc (%), Leg_Fat_Perc (%) Trunk_Leg_Fat_Ratio= trunk to leg fat ratio,
		Trunk_Limb_Fat_Mass_Ratio= trunk to limb fat ratio, and Lean_Mass_HeightSquared_Ratio= lean mass to height squared ratio. */ 

/* Data import step using the SAS "proc import" function*/ 

proc import datafile="C:\Users\diego\Documents\SampleImputation\SampleMissing.csv"
out=SampleI.SampleMissing dbms=CSV replace; 
getnames=yes; run; 

	/*Step 1c: Format dataset - here the numerical CompGroup variable is reformated to output as text in our consequent 
outputs to denote the randomization group*timepoint interaction term. */ 

Proc format; 
value CompGroup  1="A) Seated Control Baseline"
				 2="B) Sit-to-Stand Desk Baseline"
			     3="C) Treadmill Desk Baseline"
				 4="D) Seated Control Month-12"
				 5="E) Sit-to-Stand Desk Month-12"
				 6="F) Treadmill Desk Month-12";

/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/

/*Step 2: convert long formatted dataset into wide formats by comparison group. 

Since our analyses unit of interest is at the participant-group level, missing data imputation must be done
by comparison group whereby complete data on physical activity outcomes and auxiliary variables within each 
randomization group*timepoint combination (i.e., CompGroup) are used to predict and fill in missing values within
each respective CompGroup. 

The macro "SplitCG" splits the long formatted dateset into six wide formatted datasets by comparison group. Here variables
are ammended with a "_1_" or "_2_" to denote baseline and month-12 follow-up, respectively. In our dataset outputs here and 
and throughout the consequent code we denote the three respective randomization groups as control, desk (i.e., sit-to-stand) 
and treadmill for short. Files are output in the same "SampleI" directory where the original "SampleMissing" data was stored*/ 

	/*Step 2a: Load Macro to perform functions*/ 

%MACRO SplitCG(DataIN);
/*CompGroup=1, Seated Control Baseline*/ 
Data SAMPLEI.SampleData_Control_1;
set SampleI.&DataIn; 
/*Physical Activity Outcomes*/ 
_1_Sedentary=Sedentary;
_1_Standing=Standing;
_1_Stepping=Stepping;
/*Health Outcomes*/ 
_1_Body_Weight_kg=Body_Weight_kg;
_1_Height_cm=Height_cm;
_1_Waist_Circ__cm=Waist_Circ__cm;
_1_Hip_Circ__cm=Hip_Circ__cm;
_1_Waist_Hip_Ratio=Waist_Hip_Ratio;
_1_BMI=BMI;
_1_SBP_mmHg=SBP_mmHg;
_1_DBP_mmHg=DBP_mmHg_;
_1_HR_BPM=HR_BPM;
_1_HbA1C=HbA1C;
_1_Glucose=Glucose;
_1_Insulin=Insulin;
_1_Fibrinogen=Fibrinogen;
_1_Cortisol=Cortisol;
_1_TNF_Alpha=TNF_Alpha;
_1_IGF_1=IGF_1;
_1_IL_6=IL_6;
_1_Total_Chol=Total_Chol;
_1_LDL=LDL;
_1_HDL=HDL;
_1_Triglycerides=Triglycerides;
_1_DXA_FFM=DXA_FFM;
_1_DXA_Fat_mass=DXA_Fat_mass;
_1_Total_BMD=Total_BMD;
_1_Total_BMC=Total_BMC;
_1_Lean_Mass=Lean_Mass;
_1_Lean_Mass_Perc=Lean_Mass_Perc;
_1_Total_Mass=Total_Mass;
_1_Body_Fat_Perc=Body_Fat_Perc;
_1_Android_Fat_Perc=Android_Fat_Perc;
_1_Gynoid_Fat_Perc=Gynoid_Fat_Perc;
_1_Android_Gynoid_Ratio=Android_Gynoid_Ratio;
_1_Fat_Mass_HeightSquared_Ratio=Fat_Mass_HeightSquared_Ratio;
_1_Trunk_Fat_Perc=Trunk_Fat_Perc;
_1_Leg_Fat_Perc=Leg_Fat_Perc;
_1_Trunk_Leg_Fat_Ratio=Trunk_Leg_Fat_Ratio;
_1_Trunk_Limb_Fat_Mass_Ratio=Trunk_Limb_Fat_Mass_Ratio;
_1_Lean_Mass_HeightSquared_Ratio=Lean_Mass_HeightSquared_Ratio;

Keep 
/*Identifier Variables*/ 
CompGroup 
Participant_ID
Age__Years_
Gender
Ethnicity
Race
Hypertension
Diabetes
Rand
Cluster
Timepoint
/*Physical Activity Outcome Variables*/ 
_1_Sedentary
_1_Standing
_1_Stepping
/*Health Outcome Variables*/ 
_1_Body_Weight_kg
_1_Height_cm
_1_Waist_Circ__cm
_1_Hip_Circ__cm
_1_Waist_Hip_Ratio
_1_BMI
_1_SBP_mmHg
_1_DBP_mmHg
_1_HR_BPM
_1_HbA1C
_1_Glucose
_1_Insulin
_1_Fibrinogen
_1_Cortisol
_1_TNF_Alpha
_1_IGF_1
_1_IL_6
_1_Total_Chol
_1_LDL
_1_HDL
_1_Triglycerides
_1_DXA_FFM
_1_DXA_Fat_mass
_1_Total_BMD
_1_Total_BMC
_1_Lean_Mass
_1_Lean_Mass_Perc
_1_Total_Mass
_1_Body_Fat_Perc
_1_Android_Fat_Perc
_1_Gynoid_Fat_Perc
_1_Android_Gynoid_Ratio
_1_Fat_Mass_HeightSquared_Ratio
_1_Trunk_Fat_Perc
_1_Leg_Fat_Perc
_1_Trunk_Leg_Fat_Ratio
_1_Trunk_Limb_Fat_Mass_Ratio
_1_Lean_Mass_HeightSquared_Ratio
; 
where CompGroup=1; 
run; 
quit; 

/*CompGroup=2, Sit-to-Stand Desk Baseline*/ 
Data SAMPLEI.SampleData_Desk_1;
set SampleI.&DataIn; 
/*Physical Activity Outcomes*/ 
_1_Sedentary=Sedentary;
_1_Standing=Standing;
_1_Stepping=Stepping;
/*Health Outcomes*/ 
_1_Body_Weight_kg=Body_Weight_kg;
_1_Height_cm=Height_cm;
_1_Waist_Circ__cm=Waist_Circ__cm;
_1_Hip_Circ__cm=Hip_Circ__cm;
_1_Waist_Hip_Ratio=Waist_Hip_Ratio;
_1_BMI=BMI;
_1_SBP_mmHg=SBP_mmHg;
_1_DBP_mmHg=DBP_mmHg_;
_1_HR_BPM=HR_BPM;
_1_HbA1C=HbA1C;
_1_Glucose=Glucose;
_1_Insulin=Insulin;
_1_Fibrinogen=Fibrinogen;
_1_Cortisol=Cortisol;
_1_TNF_Alpha=TNF_Alpha;
_1_IGF_1=IGF_1;
_1_IL_6=IL_6;
_1_Total_Chol=Total_Chol;
_1_LDL=LDL;
_1_HDL=HDL;
_1_Triglycerides=Triglycerides;
_1_DXA_FFM=DXA_FFM;
_1_DXA_Fat_mass=DXA_Fat_mass;
_1_Total_BMD=Total_BMD;
_1_Total_BMC=Total_BMC;
_1_Lean_Mass=Lean_Mass;
_1_Lean_Mass_Perc=Lean_Mass_Perc;
_1_Total_Mass=Total_Mass;
_1_Body_Fat_Perc=Body_Fat_Perc;
_1_Android_Fat_Perc=Android_Fat_Perc;
_1_Gynoid_Fat_Perc=Gynoid_Fat_Perc;
_1_Android_Gynoid_Ratio=Android_Gynoid_Ratio;
_1_Fat_Mass_HeightSquared_Ratio=Fat_Mass_HeightSquared_Ratio;
_1_Trunk_Fat_Perc=Trunk_Fat_Perc;
_1_Leg_Fat_Perc=Leg_Fat_Perc;
_1_Trunk_Leg_Fat_Ratio=Trunk_Leg_Fat_Ratio;
_1_Trunk_Limb_Fat_Mass_Ratio=Trunk_Limb_Fat_Mass_Ratio;
_1_Lean_Mass_HeightSquared_Ratio=Lean_Mass_HeightSquared_Ratio;
Keep 
/*Identifiers*/ 
CompGroup
Participant_ID
Age__Years_
Gender
Ethnicity
Race
Hypertension
Diabetes
Rand
Cluster
Timepoint
/*Physical Activity Outcomes*/ 
_1_Sedentary
_1_Standing
_1_Stepping
/*Health Outcomes*/ 
_1_Body_Weight_kg
_1_Height_cm
_1_Waist_Circ__cm
_1_Hip_Circ__cm
_1_Waist_Hip_Ratio
_1_BMI
_1_SBP_mmHg
_1_DBP_mmHg
_1_HR_BPM
_1_HbA1C
_1_Glucose
_1_Insulin
_1_Fibrinogen
_1_Cortisol
_1_TNF_Alpha
_1_IGF_1
_1_IL_6
_1_Total_Chol
_1_LDL
_1_HDL
_1_Triglycerides
_1_DXA_FFM
_1_DXA_Fat_mass
_1_Total_BMD
_1_Total_BMC
_1_Lean_Mass
_1_Lean_Mass_Perc
_1_Total_Mass
_1_Body_Fat_Perc
_1_Android_Fat_Perc
_1_Gynoid_Fat_Perc
_1_Android_Gynoid_Ratio
_1_Fat_Mass_HeightSquared_Ratio
_1_Trunk_Fat_Perc
_1_Leg_Fat_Perc
_1_Trunk_Leg_Fat_Ratio
_1_Trunk_Limb_Fat_Mass_Ratio
_1_Lean_Mass_HeightSquared_Ratio
; 
where CompGroup=2; 
run; 
quit; 


/*CompGroup=3, Treadmill Desk Baseline*/ 
Data SAMPLEI.SampleData_Treadmill_1;
set SampleI.&DataIn;  
/*Physical Activity Outcomes*/ 
_1_Sedentary=Sedentary;
_1_Standing=Standing;
_1_Stepping=Stepping;
/*Health Outcomes*/ 
_1_Body_Weight_kg=Body_Weight_kg;
_1_Height_cm=Height_cm;
_1_Waist_Circ__cm=Waist_Circ__cm;
_1_Hip_Circ__cm=Hip_Circ__cm;
_1_Waist_Hip_Ratio=Waist_Hip_Ratio;
_1_BMI=BMI;
_1_SBP_mmHg=SBP_mmHg;
_1_DBP_mmHg=DBP_mmHg_;
_1_HR_BPM=HR_BPM;
_1_HbA1C=HbA1C;
_1_Glucose=Glucose;
_1_Insulin=Insulin;
_1_Fibrinogen=Fibrinogen;
_1_Cortisol=Cortisol;
_1_TNF_Alpha=TNF_Alpha;
_1_IGF_1=IGF_1;
_1_IL_6=IL_6;
_1_Total_Chol=Total_Chol;
_1_LDL=LDL;
_1_HDL=HDL;
_1_Triglycerides=Triglycerides;
_1_DXA_FFM=DXA_FFM;
_1_DXA_Fat_mass=DXA_Fat_mass;
_1_Total_BMD=Total_BMD;
_1_Total_BMC=Total_BMC;
_1_Lean_Mass=Lean_Mass;
_1_Lean_Mass_Perc=Lean_Mass_Perc;
_1_Total_Mass=Total_Mass;
_1_Body_Fat_Perc=Body_Fat_Perc;
_1_Android_Fat_Perc=Android_Fat_Perc;
_1_Gynoid_Fat_Perc=Gynoid_Fat_Perc;
_1_Android_Gynoid_Ratio=Android_Gynoid_Ratio;
_1_Fat_Mass_HeightSquared_Ratio=Fat_Mass_HeightSquared_Ratio;
_1_Trunk_Fat_Perc=Trunk_Fat_Perc;
_1_Leg_Fat_Perc=Leg_Fat_Perc;
_1_Trunk_Leg_Fat_Ratio=Trunk_Leg_Fat_Ratio;
_1_Trunk_Limb_Fat_Mass_Ratio=Trunk_Limb_Fat_Mass_Ratio;
_1_Lean_Mass_HeightSquared_Ratio=Lean_Mass_HeightSquared_Ratio;
Keep 
/*Identifiers*/ 
CompGroup
Participant_ID
Age__Years_
Gender
Ethnicity
Race
Hypertension
Diabetes
Rand
Cluster
Timepoint
/*Physical Activity Outcomes*/ 
_1_Sedentary
_1_Standing
_1_Stepping
/*Health Outcomes*/ 
_1_Body_Weight_kg
_1_Height_cm
_1_Waist_Circ__cm
_1_Hip_Circ__cm
_1_Waist_Hip_Ratio
_1_BMI
_1_SBP_mmHg
_1_DBP_mmHg
_1_HR_BPM
_1_HbA1C
_1_Glucose
_1_Insulin
_1_Fibrinogen
_1_Cortisol
_1_TNF_Alpha
_1_IGF_1
_1_IL_6
_1_Total_Chol
_1_LDL
_1_HDL
_1_Triglycerides
_1_DXA_FFM
_1_DXA_Fat_mass
_1_Total_BMD
_1_Total_BMC
_1_Lean_Mass
_1_Lean_Mass_Perc
_1_Total_Mass
_1_Body_Fat_Perc
_1_Android_Fat_Perc
_1_Gynoid_Fat_Perc
_1_Android_Gynoid_Ratio
_1_Fat_Mass_HeightSquared_Ratio
_1_Trunk_Fat_Perc
_1_Leg_Fat_Perc
_1_Trunk_Leg_Fat_Ratio
_1_Trunk_Limb_Fat_Mass_Ratio
_1_Lean_Mass_HeightSquared_Ratio
; 
where CompGroup=3; 
run; 
quit; 



/*CompGroup=4, Seated Control Month-12*/ 
Data SAMPLEI.SampleData_Control_2;
set SampleI.&DataIn; 
/*Physical Activity Outcomes*/ 
_2_Sedentary=Sedentary;
_2_Standing=Standing;
_2_Stepping=Stepping;
/*Health Outcomes*/ 
_2_Body_Weight_kg=Body_Weight_kg;
_2_Height_cm=Height_cm;
_2_Waist_Circ__cm=Waist_Circ__cm;
_2_Hip_Circ__cm=Hip_Circ__cm;
_2_Waist_Hip_Ratio=Waist_Hip_Ratio;
_2_BMI=BMI;
_2_SBP_mmHg=SBP_mmHg;
_2_DBP_mmHg=DBP_mmHg_;
_2_HR_BPM=HR_BPM;
_2_HbA1C=HbA1C;
_2_Glucose=Glucose;
_2_Insulin=Insulin;
_2_Fibrinogen=Fibrinogen;
_2_Cortisol=Cortisol;
_2_TNF_Alpha=TNF_Alpha;
_2_IGF_1=IGF_1;
_2_IL_6=IL_6;
_2_Total_Chol=Total_Chol;
_2_LDL=LDL;
_2_HDL=HDL;
_2_Triglycerides=Triglycerides;
_2_DXA_FFM=DXA_FFM;
_2_DXA_Fat_mass=DXA_Fat_mass;
_2_Total_BMD=Total_BMD;
_2_Total_BMC=Total_BMC;
_2_Lean_Mass=Lean_Mass;
_2_Lean_Mass_Perc=Lean_Mass_Perc;
_2_Total_Mass=Total_Mass;
_2_Body_Fat_Perc=Body_Fat_Perc;
_2_Android_Fat_Perc=Android_Fat_Perc;
_2_Gynoid_Fat_Perc=Gynoid_Fat_Perc;
_2_Android_Gynoid_Ratio=Android_Gynoid_Ratio;
_2_Fat_Mass_HeightSquared_Ratio=Fat_Mass_HeightSquared_Ratio;
_2_Trunk_Fat_Perc=Trunk_Fat_Perc;
_2_Leg_Fat_Perc=Leg_Fat_Perc;
_2_Trunk_Leg_Fat_Ratio=Trunk_Leg_Fat_Ratio;
_2_Trunk_Limb_Fat_Mass_Ratio=Trunk_Limb_Fat_Mass_Ratio;
_2_Lean_Mass_HeightSquared_Ratio=Lean_Mass_HeightSquared_Ratio;

Keep 
/*Identifiers*/ 
CompGroup
Participant_ID
Age__Years_
Gender
Ethnicity
Race
Hypertension
Diabetes
Rand
Cluster
Timepoint
/*Physical Activity Outcomes*/ 
_2_Sedentary
_2_Standing
_2_Stepping
/*Health Outcomes*/ 
_2_Body_Weight_kg
_2_Height_cm
_2_Waist_Circ__cm
_2_Hip_Circ__cm
_2_Waist_Hip_Ratio
_2_BMI
_2_SBP_mmHg
_2_DBP_mmHg
_2_HR_BPM
_2_HbA1C
_2_Glucose
_2_Insulin
_2_Fibrinogen
_2_Cortisol
_2_TNF_Alpha
_2_IGF_1
_2_IL_6
_2_Total_Chol
_2_LDL
_2_HDL
_2_Triglycerides
_2_DXA_FFM
_2_DXA_Fat_mass
_2_Total_BMD
_2_Total_BMC
_2_Lean_Mass
_2_Lean_Mass_Perc
_2_Total_Mass
_2_Body_Fat_Perc
_2_Android_Fat_Perc
_2_Gynoid_Fat_Perc
_2_Android_Gynoid_Ratio
_2_Fat_Mass_HeightSquared_Ratio
_2_Trunk_Fat_Perc
_2_Leg_Fat_Perc
_2_Trunk_Leg_Fat_Ratio
_2_Trunk_Limb_Fat_Mass_Ratio
_2_Lean_Mass_HeightSquared_Ratio
; 
where CompGroup=4; 
run; 
quit; 


/*CompGroup=5, Sit-to-Stand Desk Month-12*/ 
Data SAMPLEI.SampleData_Desk_2;
set SampleI.&DataIn; 
/*Physical Activity Outcomes*/ 
_2_Sedentary=Sedentary;
_2_Standing=Standing;
_2_Stepping=Stepping;
/*Health Outcomes*/ 
_2_Body_Weight_kg=Body_Weight_kg;
_2_Height_cm=Height_cm;
_2_Waist_Circ__cm=Waist_Circ__cm;
_2_Hip_Circ__cm=Hip_Circ__cm;
_2_Waist_Hip_Ratio=Waist_Hip_Ratio;
_2_BMI=BMI;
_2_SBP_mmHg=SBP_mmHg;
_2_DBP_mmHg=DBP_mmHg_;
_2_HR_BPM=HR_BPM;
_2_HbA1C=HbA1C;
_2_Glucose=Glucose;
_2_Insulin=Insulin;
_2_Fibrinogen=Fibrinogen;
_2_Cortisol=Cortisol;
_2_TNF_Alpha=TNF_Alpha;
_2_IGF_1=IGF_1;
_2_IL_6=IL_6;
_2_Total_Chol=Total_Chol;
_2_LDL=LDL;
_2_HDL=HDL;
_2_Triglycerides=Triglycerides;
_2_DXA_FFM=DXA_FFM;
_2_DXA_Fat_mass=DXA_Fat_mass;
_2_Total_BMD=Total_BMD;
_2_Total_BMC=Total_BMC;
_2_Lean_Mass=Lean_Mass;
_2_Lean_Mass_Perc=Lean_Mass_Perc;
_2_Total_Mass=Total_Mass;
_2_Body_Fat_Perc=Body_Fat_Perc;
_2_Android_Fat_Perc=Android_Fat_Perc;
_2_Gynoid_Fat_Perc=Gynoid_Fat_Perc;
_2_Android_Gynoid_Ratio=Android_Gynoid_Ratio;
_2_Fat_Mass_HeightSquared_Ratio=Fat_Mass_HeightSquared_Ratio;
_2_Trunk_Fat_Perc=Trunk_Fat_Perc;
_2_Leg_Fat_Perc=Leg_Fat_Perc;
_2_Trunk_Leg_Fat_Ratio=Trunk_Leg_Fat_Ratio;
_2_Trunk_Limb_Fat_Mass_Ratio=Trunk_Limb_Fat_Mass_Ratio;
_2_Lean_Mass_HeightSquared_Ratio=Lean_Mass_HeightSquared_Ratio;

Keep 
/*Identifiers*/ 
CompGroup
Participant_ID
Age__Years_
Gender
Ethnicity
Race
Hypertension
Diabetes
Rand
Cluster
Timepoint
/*Physical Activity Outcomes*/ 
_2_Sedentary
_2_Standing
_2_Stepping
/*Health Outcomes*/ 
_2_Body_Weight_kg
_2_Height_cm
_2_Waist_Circ__cm
_2_Hip_Circ__cm
_2_Waist_Hip_Ratio
_2_BMI
_2_SBP_mmHg
_2_DBP_mmHg
_2_HR_BPM
_2_HbA1C
_2_Glucose
_2_Insulin
_2_Fibrinogen
_2_Cortisol
_2_TNF_Alpha
_2_IGF_1
_2_IL_6
_2_Total_Chol
_2_LDL
_2_HDL
_2_Triglycerides
_2_DXA_FFM
_2_DXA_Fat_mass
_2_Total_BMD
_2_Total_BMC
_2_Lean_Mass
_2_Lean_Mass_Perc
_2_Total_Mass
_2_Body_Fat_Perc
_2_Android_Fat_Perc
_2_Gynoid_Fat_Perc
_2_Android_Gynoid_Ratio
_2_Fat_Mass_HeightSquared_Ratio
_2_Trunk_Fat_Perc
_2_Leg_Fat_Perc
_2_Trunk_Leg_Fat_Ratio
_2_Trunk_Limb_Fat_Mass_Ratio
_2_Lean_Mass_HeightSquared_Ratio
; 
where CompGroup=5; 
run; 
quit; 

/*CompGroup=6, Treadmill Desk Month-12*/ 
Data SAMPLEI.SampleData_Treadmill_2;
set SampleI.&DataIn; 
/*Physical Activity Outcomes*/ 
_2_Sedentary=Sedentary;
_2_Standing=Standing;
_2_Stepping=Stepping;
/*Health Outcomes*/ 
_2_Body_Weight_kg=Body_Weight_kg;
_2_Height_cm=Height_cm;
_2_Waist_Circ__cm=Waist_Circ__cm;
_2_Hip_Circ__cm=Hip_Circ__cm;
_2_Waist_Hip_Ratio=Waist_Hip_Ratio;
_2_BMI=BMI;
_2_SBP_mmHg=SBP_mmHg;
_2_DBP_mmHg=DBP_mmHg_;
_2_HR_BPM=HR_BPM;
_2_HbA1C=HbA1C;
_2_Glucose=Glucose;
_2_Insulin=Insulin;
_2_Fibrinogen=Fibrinogen;
_2_Cortisol=Cortisol;
_2_TNF_Alpha=TNF_Alpha;
_2_IGF_1=IGF_1;
_2_IL_6=IL_6;
_2_Total_Chol=Total_Chol;
_2_LDL=LDL;
_2_HDL=HDL;
_2_Triglycerides=Triglycerides;
_2_DXA_FFM=DXA_FFM;
_2_DXA_Fat_mass=DXA_Fat_mass;
_2_Total_BMD=Total_BMD;
_2_Total_BMC=Total_BMC;
_2_Lean_Mass=Lean_Mass;
_2_Lean_Mass_Perc=Lean_Mass_Perc;
_2_Total_Mass=Total_Mass;
_2_Body_Fat_Perc=Body_Fat_Perc;
_2_Android_Fat_Perc=Android_Fat_Perc;
_2_Gynoid_Fat_Perc=Gynoid_Fat_Perc;
_2_Android_Gynoid_Ratio=Android_Gynoid_Ratio;
_2_Fat_Mass_HeightSquared_Ratio=Fat_Mass_HeightSquared_Ratio;
_2_Trunk_Fat_Perc=Trunk_Fat_Perc;
_2_Leg_Fat_Perc=Leg_Fat_Perc;
_2_Trunk_Leg_Fat_Ratio=Trunk_Leg_Fat_Ratio;
_2_Trunk_Limb_Fat_Mass_Ratio=Trunk_Limb_Fat_Mass_Ratio;
_2_Lean_Mass_HeightSquared_Ratio=Lean_Mass_HeightSquared_Ratio;

Keep 
/*Identifiers*/ 
CompGroup
Participant_ID
Age__Years_
Gender
Ethnicity
Race
Hypertension
Diabetes
Rand
Cluster
Timepoint
/*Physical Activity Outcomes*/ 
_2_Sedentary
_2_Standing
_2_Stepping
/*Health Outcomes*/ 
_2_Body_Weight_kg
_2_Height_cm
_2_Waist_Circ__cm
_2_Hip_Circ__cm
_2_Waist_Hip_Ratio
_2_BMI
_2_SBP_mmHg
_2_DBP_mmHg
_2_HR_BPM
_2_HbA1C
_2_Glucose
_2_Insulin
_2_Fibrinogen
_2_Cortisol
_2_TNF_Alpha
_2_IGF_1
_2_IL_6
_2_Total_Chol
_2_LDL
_2_HDL
_2_Triglycerides
_2_DXA_FFM
_2_DXA_Fat_mass
_2_Total_BMD
_2_Total_BMC
_2_Lean_Mass
_2_Lean_Mass_Perc
_2_Total_Mass
_2_Body_Fat_Perc
_2_Android_Fat_Perc
_2_Gynoid_Fat_Perc
_2_Android_Gynoid_Ratio
_2_Fat_Mass_HeightSquared_Ratio
_2_Trunk_Fat_Perc
_2_Leg_Fat_Perc
_2_Trunk_Leg_Fat_Ratio
_2_Trunk_Limb_Fat_Mass_Ratio
_2_Lean_Mass_HeightSquared_Ratio
; 
where CompGroup=6; 
run; 
quit; 

%MEND;

	/*Step 2b: Run Code*/ 

%SplitCG(SampleMissing); 


/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/

/*Step 3: Identify auxilliary variables from health outcomes to use in the six respective imputation models. 

The macros "Corr_1" (baseline) and "Corr_2" (month-12 follow-up) below calculate the Pearson Correlation Coefficients between 
the three physical activity outcomes of interest and auxilliary health outcome variables.Per recommendation from the literature 
on multiple imputation we select auxilliary variables that have an absolute correlation >0.4, as this ensures optimal performance 
in imputation models (see manuscript for details). We note that selecting the appropriate auxilliary variable is an iterative process 
dependent on the proportion of missing data, and imputation models with auxilliary variables that have correlation >0.4 may still fail to
converge. In such cases of non-convergence another auxilliary variable with an absolute correlation >0.4 should be selected
until convergence is achieved. Having multiple auxilliary variables to select from, as we do in our RCT, can thus be beneficial
in cases where missing data imputation is warranted.*/ 

	/*Step 3a: here the Libname function is used again to load a sub directory titled "AuxilliaryVariableCorrelations" where our 
pearson correlation coefficients will be output. These files can then be opened in SAS and inspected to select the appropriate 
auxiliary variables*/ 

Libname AuxCorr "C:\Users\diego\Documents\SampleImputation\AuxilliaryVariableCorrelations"; 


	/*Step 3b: load the macros "Corr_1" and "Corr_2" to generate correlation outputs*/
 
/*Corr_1 Macro for Baseline CompGroups*/ 
%MACRO Corr_1(DataIn, DataOut);
   
Proc Corr Data=SampleI.&DataIn
outs= AuxCorr.&DataOut noprint;
var
/*Physical Activity Outcome Variables*/ 
_1_Sedentary
_1_Standing
_1_Stepping
/*Auxilliary Health Outcome Variables*/ 
_1_Body_Weight_kg
_1_Height_cm
_1_Waist_Circ__cm
_1_Hip_Circ__cm
_1_Waist_Hip_Ratio
_1_BMI
_1_SBP_mmHg
_1_DBP_mmHg
_1_HR_BPM
_1_HbA1C
_1_Glucose
_1_Insulin
_1_Fibrinogen
_1_Cortisol
_1_TNF_Alpha
_1_IGF_1
_1_IL_6
_1_Total_Chol
_1_LDL
_1_HDL
_1_Triglycerides
_1_DXA_FFM
_1_DXA_Fat_mass
_1_Total_BMD
_1_Total_BMC
_1_Lean_Mass
_1_Lean_Mass_Perc
_1_Total_Mass
_1_Body_Fat_Perc
_1_Android_Fat_Perc
_1_Gynoid_Fat_Perc
_1_Android_Gynoid_Ratio
_1_Fat_Mass_HeightSquared_Ratio
_1_Trunk_Fat_Perc
_1_Leg_Fat_Perc
_1_Trunk_Leg_Fat_Ratio
_1_Trunk_Limb_Fat_Mass_Ratio
_1_Lean_Mass_HeightSquared_Ratio
;
Run; 
quit; 

%MEND;

/*Corr_2 Macro for month-12 follow-up CompGroups*/ 
%MACRO Corr_2(DataIn, DataOut);
   
Proc Corr Data=SampleI.&DataIn
outs= AuxCorr.&DataOut noprint;
var
/*Physical Activity Outcome Variables*/ 
_2_Sedentary
_2_Standing
_2_Stepping
/*Auxilliary Health Outcome Variables*/ 
_2_Body_Weight_kg
_2_Height_cm
_2_Waist_Circ__cm
_2_Hip_Circ__cm
_2_Waist_Hip_Ratio
_2_BMI
_2_SBP_mmHg
_2_DBP_mmHg
_2_HR_BPM
_2_HbA1C
_2_Glucose
_2_Insulin
_2_Fibrinogen
_2_Cortisol
_2_TNF_Alpha
_2_IGF_1
_2_IL_6
_2_Total_Chol
_2_LDL
_2_HDL
_2_Triglycerides
_2_DXA_FFM
_2_DXA_Fat_mass
_2_Total_BMD
_2_Total_BMC
_2_Lean_Mass
_2_Lean_Mass_Perc
_2_Total_Mass
_2_Body_Fat_Perc
_2_Android_Fat_Perc
_2_Gynoid_Fat_Perc
_2_Android_Gynoid_Ratio
_2_Fat_Mass_HeightSquared_Ratio
_2_Trunk_Fat_Perc
_2_Leg_Fat_Perc
_2_Trunk_Leg_Fat_Ratio
_2_Trunk_Limb_Fat_Mass_Ratio
_2_Lean_Mass_HeightSquared_Ratio
;
Run; 
quit; 

%MEND;

	/*Step 3c: run code*/ 

/*CompGroup=1, seated control baseline*/ 
%Corr_1(sampledata_control_1, sampledata_C1_AuxCorr);
/*CompGroup=2, sit-to-stand desk baseline*/
%Corr_1(sampledata_desk_1, sampledata_D1_AuxCorr);
/*CompGroup=3, treadmill desk baseline*/
%Corr_1(sampledata_treadmill_1, sampledata_T1_AuxCorr);

/*CompGroup=4, seated control month-12 follow-up*/ 
%Corr_2(sampledata_control_2, sampledata_C2_AuxCorr);
/*CompGroup=5, sit-to-stand desk month-12 follow-up*/
%Corr_2(sampledata_desk_2, sampledata_D2_AuxCorr);
/*CompGroup=6, treadmill desk baseline follow-up*/
%Corr_2(sampledata_treadmill_2, sampledata_T2_AuxCorr); 


/* The following auxilliary variables displayed below by CompGroup*Variable were chosen 
for the consequent imputation models in the steps that follow. The respective
pearson correlation coefficients results for these auxilliary variables are listed below. 

Comparison Group	Sedentary				Standing			Stepping

CompGroup 1         _1_Body_Weight_kg	_1_Body_Weight_kg	_1_Body_Weight_kg
					Correlation=0.42	Correlation=0.47	Correlation=0.45
	
CompGroup 2			_1_Waist_Circ__cm	_1_DBP_mmHg			_1_Waist_Hip_Ratio
					Correlation=0.53	Correlation=0.49	Correlation=0.58
	 	
CompGroup 3			_1_Total_Mass		_1_HbA1C			_1_Waist_Circ__cm
					Correlation=0.45	Correlation=0.53	Correlation=0.44

CompGroup 4			_2_Waist_Circ__cm	_2_Waist_Circ__cm	_2_Waist_Circ__cm
					Correlation=0.64	Correlation=0.56	Correlation=0.47
	
CompGroup 5			_2_Hip_Circ__cm		_2_Waist_Circ__cm	_2_Hip_Circ__cm
					Correlation=0.56	Correlation=0.41	Correlation=0.43
	
CompGroup 6			_2_Leg_Fat_Perc		_2_Waist_Hip_Ratio	_2_Body_Weight_kg
					Correlation=0.41	Correlation=0.49	Correlation=0.42
*/ 


/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/

/*Step 4: Missing Data Imputation- Below we demonstrate a three phase approach to missing data imputation. 

	First, a pilot imputation is done to obtain a preliminary standard error and 95% confidence interval 
of the fraction of missing information, which indicates the quality of the parameter estimates generated 
by joint multiple imputation conditioned on the amount of missing data. This provides information on the target 
coefficient of variation, which is a measure of between imputation variance. Per recommendation from the 
literature (see manuscript) we chose 20 imputations for our pilot phases. A seperate pilot joint imputation
model is run for each CompGroup*Variable combition. In our case this is a total of 18 (6 compGroups x 3 physical
activity variables) pilot imputations models. 

	Secondly, the estimated fraction of missing information and the coeffiecient of variation obtained from
the first step are used to empirically determine the necessary number of imputations each dataset will need
to ensure that efficient and replicable outcomes are produced for both point estimates and standard errors. 
The code for this step was developed by statistician Paul Von Hippel and is downloadable in a macro titled
"%mi_combine" available from missingdata.org. 

	References:

	Barnard, J., & Rubin, D. B. (1999). “Small-sample degrees of freedom with multiple imputation.” 
  	Biometrika, 86(4), 948–955. https://doi.org/10.1093/biomet/86.4.948

	von Hippel, P.T. (2015). “New confidence intervals and bias calculations show that maximum 
	likelihood can beat multiple imputation in small samples.” Structural Equation Modeling, 
	23(3): 423-437. https://arxiv.org/abs/1307.5875. 

	Thirdly, a second imputation model is run for each compgroup*variable combination using the recommended 
number of imputations from step 2. For logistical purposes we choose a uniform number of imputations for each 
physical activity variable across all compgroups following the highest recommended number of imputations among
the six respective compgroups. This ensures that each compgroup has the same number of imputation distributions 
when the imputed datasets are merged into a long format dataset again to generate pooled estimates in the 
consequent analyses step. Selecting a higher number of imputations than the %mi_combine macro suggests will not 
diminish the efficiency and replicability of point estimates and standard error, but will require more computing 
resources if one comparison group requires much more imputations than the others to achieve stability. */ 


	/*Step 4a: Pilot Imputation*/ 

/*Load directory to output final pilot imputation results: Here a sub directory titled "PilotImputations" has been created 
within the "SampleImputations" directory and called as the directory to store files using the SAS "Libname" function 
denoting the libary name within SAS as "PI".*/ 

Libname PI "C:\Users\diego\Documents\SampleImputation\PilotImputations"; 

/*Load the macro %PI to generate pilot imputation results. 

  Below we use the following abbreviations in our output file names: 

  C1= seated control group at baseline
  C2= seated control group at month-12 
  D1= sit-to-stand desk group at baseline
  D2= sit-to-stand desk group at month-12
  T1= treadmill desk group at baseline
  T2= treadmill desk group at month-12

  PIA= pilot imputation for variable A, which is Sedentary
  PIB= pilot imputation for variable B, which is standing
  PIC= pilot imputation for variable C, which is stepping 

This step uses the  "Proc MI" SAS package. The "minimum=0" specification ensures the process does not
output non-plausible negative values, the "seed=15" specification ensures our results are replicable if the models 
are run again (note any seed value will work and produce the same output as long as the same number is used again 
for each respective model), and the "nimpute=20" specification indicates the number of imputations (20 in the pilot case).
Each imputation model in the %PI macro below contains the respective auxilliary variable identified in step 3c. */ 


%Macro PI;

/*Pilot Imputations for Variable A=Sedentary*/ 
	/*Sedentary Control Baseline = C1*/ 
Proc MI data=  SAMPLEI.sampledata_control_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIA_C1;
mcmc; 
  Var /* Add Auxilliary Variables*/ _1_Body_Weight_kg
  /*Add imputation variables of interest*/_1_Sedentary; 
run;

Proc univariate data=SAMPLEI.SampleData_PIA_C1 noprint; 
Var _1_Sedentary; 
output out=SAMPLEI.SampleData_PIA_UNI_C1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIA_UNI_C1;
set SAMPLEI.SampleData_PIA_UNI_C1;
Label="_1_Sedentary";
run; 

	/*Sedentary Control Month-12 = C2*/ 
Proc MI data=  SAMPLEI.sampledata_control_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIA_C2;
mcmc; 
  Var /* Add Auxilliary Variables*/ _2_Waist_Circ__cm
  /*Add imputation variables of interest*/_2_Sedentary; 
run;

Proc univariate data=SAMPLEI.SampleData_PIA_C2 noprint; 
Var _2_Sedentary; 
output out=SAMPLEI.SampleData_PIA_UNI_C2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIA_UNI_C2;
set SAMPLEI.SampleData_PIA_UNI_C2;
Label="_2_Sedentary";
run; 

	/*Sedentary Sit-to-Stand Desk Baseline = D1*/ 
Proc MI data=  SAMPLEI.sampledata_Desk_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIA_D1;
mcmc; 
  Var /* Add Auxilliary Variables*/ _1_Waist_Circ__cm
  /*Add imputation variables of interest*/_1_Sedentary; 
run;

Proc univariate data=SAMPLEI.SampleData_PIA_D1 noprint; 
Var _1_Sedentary; 
output out=SAMPLEI.SampleData_PIA_UNI_D1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIA_UNI_D1;
set SAMPLEI.SampleData_PIA_UNI_D1;
Label="_1_Sedentary";
run; 

	/*Sedentary Sit-to-Stand Desk Month-12 = D2*/ 
Proc MI data=  SAMPLEI.sampledata_Desk_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIA_D2;
mcmc; 
  Var /* Add Auxilliary Variables*/ _2_Hip_Circ__cm
  /*Add imputation variables of interest*/_2_Sedentary; 
run;

Proc univariate data=SAMPLEI.SampleData_PIA_D2 noprint; 
Var _2_Sedentary; 
output out=SAMPLEI.SampleData_PIA_UNI_D2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIA_UNI_D2;
set SAMPLEI.SampleData_PIA_UNI_D2;
Label="_2_Sedentary";
run; 

	/*Sedentary Treadmill Desk Baseline = T1*/ 
Proc MI data=  SAMPLEI.sampledata_Treadmill_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIA_T1;
mcmc; 
  Var /* Add Auxilliary Variables*/ _1_Total_Mass
  /*Add imputation variables of interest*/_1_Sedentary; 
run;

Proc univariate data=SAMPLEI.SampleData_PIA_T1 noprint; 
Var _1_Sedentary; 
output out=SAMPLEI.SampleData_PIA_UNI_T1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIA_UNI_T1;
set SAMPLEI.SampleData_PIA_UNI_T1;
Label="_1_Sedentary";
run; 

	/*Sedentary Treadmill Desk Month-12 = T2*/ 
Proc MI data=  SAMPLEI.sampledata_Treadmill_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIA_T2;
mcmc; 
  Var /* Add Auxilliary Variables*/ _2_Leg_Fat_Perc
  /*Add imputation variables of interest*/_2_Sedentary; 
run;

Proc univariate data=SAMPLEI.SampleData_PIA_T2 noprint; 
Var _2_Sedentary; 
output out=SAMPLEI.SampleData_PIA_UNI_T2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIA_UNI_T2;
set SAMPLEI.SampleData_PIA_UNI_T2;
Label="_2_Sedentary";
run; 

/*Pilot Imputations for Variable B=Standing*/ 
	/*Standing Control Baseline = C1*/ 
Proc MI data=  SAMPLEI.sampledata_control_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIB_C1;
mcmc; 
  Var /* Add Auxilliary Variables*/ _1_Body_Weight_kg
  /*Add imputation variables of interest*/_1_Standing; 
run;

Proc univariate data=SAMPLEI.SampleData_PIB_C1 noprint; 
Var _1_Standing; 
output out=SAMPLEI.SampleData_PIB_UNI_C1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIB_UNI_C1;
set SAMPLEI.SampleData_PIB_UNI_C1;
Label="_1_Standing";
run; 

	/*Standing Control Month-12 = C2*/ 
Proc MI data=  SAMPLEI.sampledata_control_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIB_C2;
mcmc; 
  Var /* Add Auxilliary Variables*/ _2_Waist_Circ__cm 
  /*Add imputation variables of interest*/_2_Standing; 
run;

Proc univariate data=SAMPLEI.SampleData_PIB_C2 noprint; 
Var _2_Standing; 
output out=SAMPLEI.SampleData_PIB_UNI_C2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIB_UNI_C2;
set SAMPLEI.SampleData_PIB_UNI_C2;
Label="_2_Standing";
run; 

	/*Standing Sit-to-Stand Desk Baseline = D1*/ 
Proc MI data=  SAMPLEI.sampledata_Desk_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIB_D1;
mcmc; 
  Var /* Add Auxilliary Variables*/ _1_DBP_mmHg
  /*Add imputation variables of interest*/_1_Standing; 
run;

Proc univariate data=SAMPLEI.SampleData_PIB_D1 noprint; 
Var _1_Standing; 
output out=SAMPLEI.SampleData_PIB_UNI_D1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIB_UNI_D1;
set SAMPLEI.SampleData_PIB_UNI_D1;
Label="_1_Standing";
run; 

	/*Standing Sit-to-Stand Desk Month-12 = D2*/ 
Proc MI data=  SAMPLEI.sampledata_Desk_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIB_D2;
mcmc; 
  Var /* Add Auxilliary Variables*/ _2_Hip_Circ__cm
  /*Add imputation variables of interest*/_2_Standing; 
run;

Proc univariate data=SAMPLEI.SampleData_PIB_D2 noprint; 
Var _2_Standing; 
output out=SAMPLEI.SampleData_PIB_UNI_D2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIB_UNI_D2;
set SAMPLEI.SampleData_PIB_UNI_D2;
Label="_2_Standing";
run; 

	/*Standing Treadmill Desk Baseline = T1*/ 
Proc MI data=  SAMPLEI.sampledata_Treadmill_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIB_T1;
mcmc; 
  Var /* Add Auxilliary Variables*/ _1_HbA1C
  /*Add imputation variables of interest*/_1_Standing; 
run;

Proc univariate data=SAMPLEI.SampleData_PIB_T1 noprint; 
Var _1_Standing; 
output out=SAMPLEI.SampleData_PIB_UNI_T1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIB_UNI_T1;
set SAMPLEI.SampleData_PIB_UNI_T1;
Label="_1_Standing";
run; 

	/*Standing Treadmill Desk Month-12 = T2*/ 
Proc MI data=  SAMPLEI.sampledata_Treadmill_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIB_T2;
mcmc; 
  Var /* Add Auxilliary Variables*/ _2_Waist_Hip_Ratio
  /*Add imputation variables of interest*/_2_Standing; 
run;

Proc univariate data=SAMPLEI.SampleData_PIB_T2 noprint; 
Var _2_Standing; 
output out=SAMPLEI.SampleData_PIB_UNI_T2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIB_UNI_T2;
set SAMPLEI.SampleData_PIB_UNI_T2;
Label="_2_Standing";
run;

/*Pilot Imputations for Variable C=Stepping*/ 
	/*Stepping Control Baseline = C1*/ 
Proc MI data=  SAMPLEI.sampledata_control_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIC_C1;
mcmc; 
  Var /* Add Auxilliary Variables*/ _1_Body_Weight_kg
  /*Add imputation variables of interest*/_1_Stepping; 
run;

Proc univariate data=SAMPLEI.SampleData_PIC_C1 noprint; 
Var _1_Stepping; 
output out=SAMPLEI.SampleData_PIC_UNI_C1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIC_UNI_C1;
set SAMPLEI.SampleData_PIC_UNI_C1;
Label="_1_Stepping";
run; 

	/*Stepping Control Month-12 = C2*/ 
Proc MI data=  SAMPLEI.sampledata_control_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIC_C2;
mcmc; 
  Var /* Add Auxilliary Variables*/ _2_Waist_Circ__cm
  /*Add imputation variables of interest*/_2_Stepping; 
run;

Proc univariate data=SAMPLEI.SampleData_PIC_C2 noprint; 
Var _2_Stepping; 
output out=SAMPLEI.SampleData_PIC_UNI_C2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIC_UNI_C2;
set SAMPLEI.SampleData_PIC_UNI_C2;
Label="_2_Stepping";
run; 

	/*Stepping Sit-to-Stand Desk Baseline = D1*/ 
Proc MI data=  SAMPLEI.sampledata_Desk_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIC_D1;
mcmc; 
  Var /* Add Auxilliary Variables*/ _1_Waist_Hip_Ratio
  /*Add imputation variables of interest*/_1_Stepping; 
run;

Proc univariate data=SAMPLEI.SampleData_PIC_D1 noprint; 
Var _1_Stepping; 
output out=SAMPLEI.SampleData_PIC_UNI_D1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIC_UNI_D1;
set SAMPLEI.SampleData_PIC_UNI_D1;
Label="_1_Stepping";
run; 

	/*Stepping Sit-to-Stand Desk Month-12 = D2*/ 
Proc MI data=  SAMPLEI.sampledata_Desk_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIC_D2;
mcmc; 
  Var /* Add Auxilliary Variables*/ _2_Hip_Circ__cm
  /*Add imputation variables of interest*/_2_Stepping; 
run;

Proc univariate data=SAMPLEI.SampleData_PIC_D2 noprint; 
Var _2_Stepping; 
output out=SAMPLEI.SampleData_PIC_UNI_D2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIC_UNI_D2;
set SAMPLEI.SampleData_PIC_UNI_D2;
Label="_2_Stepping";
run; 

	/*Stepping Treadmill Desk Baseline = T1*/ 
Proc MI data=  SAMPLEI.sampledata_Treadmill_1 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIC_T1;
mcmc;  
  Var /* Add Auxilliary Variables*/ _1_Waist_Circ__cm
  /*Add imputation variables of interest*/_1_Stepping; 
run;

Proc univariate data=SAMPLEI.SampleData_PIC_T1 noprint; 
Var _1_Stepping; 
output out=SAMPLEI.SampleData_PIC_UNI_T1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIC_UNI_T1;
set SAMPLEI.SampleData_PIC_UNI_T1;
Label="_1_Stepping";
run; 

	/*Stepping Treadmill Desk Month-12 = T2*/ 
Proc MI data=  SAMPLEI.sampledata_Treadmill_2 minimum=0 seed=15 nimpute=20 noprint out= SAMPLEI.SampleData_PIC_T2;
mcmc;  
  Var /* Add Auxilliary Variables*/ _2_Body_Weight_kg
  /*Add imputation variables of interest*/_2_Stepping; 
run;

Proc univariate data=SAMPLEI.SampleData_PIC_T2 noprint; 
Var _2_Stepping; 
output out=SAMPLEI.SampleData_PIC_UNI_T2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

data PI.SampleData_PIC_UNI_T2;
set SAMPLEI.SampleData_PIC_UNI_T2;
Label="_2_Stepping";
run;

%MEND;

/*Run Code*/
%PI; 

	/*Step 4b: Selecting the number of necessary imputations per model*/ 

/*Load directories to output recommended imputations: Here sub directories titled "IdealImputations" and "FinalOutput"
have been created within the "SampleImputations" and "IdealImputations" directories respectively and called as the 
directory to store files using the SAS "Libname" function denoting the libary names within SAS as "Ideal_m" and 
"M_Output.*/ 

Libname Ideal_M "C:\Users\diego\Documents\SampleImputation/IdealImputations"; 
Libname M_Output "C:\Users\diego\Documents\SampleImputation/IdealImputations\FinalOutput"; 

/*Load Macros to determine ideal number of imputations: 

  Here we call Paul Von Hippel's %mi_combine macro within our %Ideal_M macro, which extracts the output of interest, 
  "Recommended_M=recommended_imputations" to then merge by physical activity variables and compute the max value across
  all compgroups indicating the uniform number of imputations that should be run across all compgroups for each respective
  imputation variable of interest. When calling the %mi_combine macro we also specify the degrees of freedom (N-1) for 
  each respective model (see details below in Von Hippel's %mi_combine macro annotation).*/ 

/*Macro: %mi_combine
  Author: Paul von Hippel
  Version: 1.0
  Date: July 19, 2017
  Summary: This macro combines the multiple point estimates and standard errors produced by
           analyzing multiply imputed (MI) datasets as though they were complete.
           It outputs a single MI point estimate and SE estimate and confidence interval,
           as well as an estimate and confidence interval for the fraction of missing information.
           It estimates the number of imputations that would be needed to produce an SE 
           estimate that is replicable according to the criterion specified by the argument target_sd_se.
           This macro can be used to implement a two-stage procedure for selecting an appropriate number of imputations,
           as described in my article "How many imputations do you need?"
           An implementation of the two-step procedure that uses this macro is available in the file downloadable from
		   MissingData.org 

	References:

	Barnard, J., & Rubin, D. B. (1999). “Small-sample degrees of freedom with multiple imputation.” 
  	Biometrika, 86(4), 948–955. https://doi.org/10.1093/biomet/86.4.948

	von Hippel, P.T. (2015). “New confidence intervals and bias calculations show that maximum 
	likelihood can beat multiple imputation in small samples.” Structural Equation Modeling, 
	23(3): 423-437. https://arxiv.org/abs/1307.5875. 

	End References*/  


	/*Load %mi_combine Macro*/ 

%macro mi_combine (inests=, /* Input dataset, which contains M point estimates and SEs 
                               produced by analyzing multiply imputed (MI) datasets 
                               as though they were complete. */
                   outests=mi_ests, /* Output dataset, containing
				                        a single MI point estimate, SE estimate, and confidence interval (CI),
                                        an estimate and CI for the fraction of missing information              
				                        a recommendation for the number of imputations that would be needed 
				                         to produce an SE estimate that is replicable 
				                         according to the criterion specified by the argument target_sd_se. */
                   est=, /* Column in the input dataset which contains point estimates. */
                   se=, /* Column in the input dataset which contains SE estimates. */
                   label=, /* Column in the input dataset which indicates what parameter the 
				               point estimate and SE estimate refer to 
				               -- e.g., the intercept, and slope of X1 and X2 in a regression model. */
				   target_sd_se=.01, /* A target for the SD of an SE estimate across all possible
				                         sets of M imputations. */
                   df_comp=&DF, /* The degrees of freedom that the estimates would have 
				                       if the data were complete 
                                       -- e.g., df_comp=n-1 for a simple linear regression.
				                      This is only necessary for small datasets and is used 
				                       to calculate the small-sample MI df formula of Barnard & Rubin (1999).
			                        */
                   confidence=.95, /* Confidence level for all confidence intervals in the output */
                   print=0, /* 1 if you want the results printed to the Output or Results window.
				               0 if you don't. */
                   df_min=3 /* Puts a lower bound of 3 on the estimated degrees of freedom. 
				                See von Hippel (2015) for justification. */
);
data work.mi_input;
 set &inests;
 SESq = &se**2;
 df_comp = &df_comp;
run;
proc sort data=work.mi_input;
  by &label;
run;
proc means data=work.mi_input mean var n;
 var &est SESq df_comp;
 by &label;
 ods output Summary=&outests;
run;
data &outests;
 set &outests;
 Est = &est._mean;
 imputations = &est._n;
 within_var = SESq_Mean;
 between_var = (1+1/imputations) * &est._Var;
 total_var = within_var + between_var;
 SE = sqrt (total_var);
 t = Est / SE;
 frac_missing = between_var / total_var; /* Can be 0 or 1 in rare cases */
 df_comp = df_comp_mean;
 df_obs = (df_comp+1)/(df_comp+3) * (1-frac_missing) * df_comp;
 if frac_missing=0 then do;
  df_rubin=5000;
  df=df_obs;
 end;
 else do;
  df_rubin = (imputations - 1) / frac_missing**2; /* Rubin (1987). OK for large samples. */
  df = (1/df_rubin + 1/df_obs)**-1; /* Barnard & Rubin (1999). Better, esp. in small samples */
  df = max (&df_min, df); /* Lower bound. von Hippel (2014) */
 end;
 p = 2 * (1-probt(abs(t),df));
 ci_half_width = se * tinv (1-(1-&confidence)/2, df);
 lcl = est - ci_half_width;
 ucl = est + ci_half_width;
 confidence = &confidence;
 %let to_keep = &label imputations est se df confidence lcl ucl t p frac_missing;
 keep &to_keep /* df_comp */ ;
run;
data &outests;
 retain &to_keep;
 set &outests;
run;
data &outests;
 set &outests;
 logit_frac_missing = log (frac_missing / (1-frac_missing));
 logit_SE = sqrt (2 / imputations);
 z = QUANTILE('NORMAL', 1 - (1-&confidence)/2);
 logit_lcl = logit_frac_missing - z * logit_SE;
 logit_ucl = logit_frac_missing + z * logit_SE;
 frac_missing_lcl = logistic (logit_lcl);
 frac_missing_ucl = logistic (logit_ucl);
 format frac_missing: 4.2;
 format df 6.0;
 target_SD_SE = &target_SD_se;
 target_cv_se = &target_SD_se / se;
 recommended_imputations = ceil (1 + (1/2) * (frac_missing_ucl / target_cv_se)**2);
 drop logit_: z;
run;
%global recommended_imputations;
proc sql;
  select max(recommended_imputations) into :recommended_imputations
  from &outests;
quit;
%if &print=1 %then %do;
proc print data=&outests;
outfile 
run;
%end; 
%mend;

	/*Load %Ideal_M macro*/ 

%Macro Ideal_M;
ODS exclude all; 

/*Variable A = Sedentary*/ 
	/*Control Baseline*/ 
Title "PI.SAMPLEDATA_PIA_UNI_C1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIA_UNI_C1, outests=Ideal_M.SAMPLEDATA_PIA_C1_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIA_C1_M_B; 
set Ideal_M.SAMPLEDATA_PIA_C1_M;
Dataset="SAMPLEDATA_PIA_C1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Control Month-12*/ 
Title "PI.SAMPLEDATA_PIA_UNI_C2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIA_UNI_C2, outests=Ideal_M.SAMPLEDATA_PIA_C2_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIA_C2_M_B; 
set Ideal_M.SAMPLEDATA_PIA_C2_M;
Dataset="SAMPLEDATA_PIA_C2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Sit-to-Stand Desk Baseline*/ 
Title "PI.SAMPLEDATA_PIA_UNI_D1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIA_UNI_D1, outests=Ideal_M.SAMPLEDATA_PIA_D1_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIA_D1_M_B; 
set Ideal_M.SAMPLEDATA_PIA_D1_M;
Dataset="SAMPLEDATA_PIA_D1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Sit-to-Stand Desk Month-12*/ 
Title "PI.SAMPLEDATA_PIA_UNI_D2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIA_UNI_D2, outests=Ideal_M.SAMPLEDATA_PIA_D2_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIA_D2_M_B; 
set Ideal_M.SAMPLEDATA_PIA_D2_M;
Dataset="SAMPLEDATA_PIA_D2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Treadmill Desk Baseline*/ 
Title "PI.SAMPLEDATA_PIA_UNI_T1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIA_UNI_T1, outests=Ideal_M.SAMPLEDATA_PIA_T1_M, est=mean, se=stderr, label=Label, df_comp=15, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIA_T1_M_B; 
set Ideal_M.SAMPLEDATA_PIA_T1_M;
Dataset="SAMPLEDATA_PIA_T1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Treadmill Desk Month-12*/ 
Title "PI.SAMPLEDATA_PIA_UNI_T2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIA_UNI_T2, outests=Ideal_M.SAMPLEDATA_PIA_T2_M, est=mean, se=stderr, label=Label, df_comp=15, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIA_T2_M_B; 
set Ideal_M.SAMPLEDATA_PIA_T2_M;
Dataset="SAMPLEDATA_PIA_T2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

/*Variable B= Standing*/ 
	/*Control Baseline*/ 
Title "PI.SAMPLEDATA_PIB_UNI_C1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIB_UNI_C1, outests=Ideal_M.SAMPLEDATA_PIB_C1_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIB_C1_M_B; 
set Ideal_M.SAMPLEDATA_PIB_C1_M;
Dataset="SAMPLEDATA_PIB_C1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Control Month-12*/ 
Title "PI.SAMPLEDATA_PIB_UNI_C2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIB_UNI_C2, outests=Ideal_M.SAMPLEDATA_PIB_C2_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIB_C2_M_B; 
set Ideal_M.SAMPLEDATA_PIB_C2_M;
Dataset="SAMPLEDATA_PIB_C2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Sit-to-Stand Desk Baseline*/ 
Title "PI.SAMPLEDATA_PIB_UNI_D1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIB_UNI_D1, outests=Ideal_M.SAMPLEDATA_PIB_D1_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIB_D1_M_B; 
set Ideal_M.SAMPLEDATA_PIB_D1_M;
Dataset="SAMPLEDATA_PIB_D1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Sit-to-Stand Desk Month-12*/ 
Title "PI.SAMPLEDATA_PIB_UNI_D2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIB_UNI_D2, outests=Ideal_M.SAMPLEDATA_PIB_D2_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIB_D2_M_B; 
set Ideal_M.SAMPLEDATA_PIB_D2_M;
Dataset="SAMPLEDATA_PIB_D2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Treadmill Desk Baseline*/ 
Title "PI.SAMPLEDATA_PIB_UNI_T1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIB_UNI_T1, outests=Ideal_M.SAMPLEDATA_PIB_T1_M, est=mean, se=stderr, label=Label, df_comp=15, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIB_T1_M_B; 
set Ideal_M.SAMPLEDATA_PIB_T1_M;
Dataset="SAMPLEDATA_PIB_T1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Treadmill Desk Month-12*/ 
Title "PI.SAMPLEDATA_PIB_UNI_T2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIB_UNI_T2, outests=Ideal_M.SAMPLEDATA_PIB_T2_M, est=mean, se=stderr, label=Label, df_comp=15, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIB_T2_M_B; 
set Ideal_M.SAMPLEDATA_PIB_T2_M;
Dataset="SAMPLEDATA_PIB_T2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit;

	/*Control Baseline*/ 
Title "PI.SAMPLEDATA_PIC_UNI_C1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIC_UNI_C1, outests=Ideal_M.SAMPLEDATA_PIC_C1_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIC_C1_M_B; 
set Ideal_M.SAMPLEDATA_PIC_C1_M;
Dataset="SAMPLEDATA_PIC_C1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Control Month-12*/ 
Title "PI.SAMPLEDATA_PIC_UNI_C2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIC_UNI_C2, outests=Ideal_M.SAMPLEDATA_PIC_C2_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIC_C2_M_B; 
set Ideal_M.SAMPLEDATA_PIC_C2_M;
Dataset="SAMPLEDATA_PIC_C2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Sit-to-Stand Desk Baseline*/ 
Title "PI.SAMPLEDATA_PIC_UNI_D1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIC_UNI_D1, outests=Ideal_M.SAMPLEDATA_PIC_D1_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIC_D1_M_B; 
set Ideal_M.SAMPLEDATA_PIC_D1_M;
Dataset="SAMPLEDATA_PIC_D1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Sit-to-Stand Desk Month-12*/ 
Title "PI.SAMPLEDATA_PIC_UNI_D2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIC_UNI_D2, outests=Ideal_M.SAMPLEDATA_PIC_D2_M, est=mean, se=stderr, label=Label, df_comp=12, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIC_D2_M_B; 
set Ideal_M.SAMPLEDATA_PIC_D2_M;
Dataset="SAMPLEDATA_PIC_D2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Treadmill Desk Baseline*/ 
Title "PI.SAMPLEDATA_PIC_UNI_T1_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIC_UNI_T1, outests=Ideal_M.SAMPLEDATA_PIC_T1_M, est=mean, se=stderr, label=Label, df_comp=15, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIC_T1_M_B; 
set Ideal_M.SAMPLEDATA_PIC_T1_M;
Dataset="SAMPLEDATA_PIC_T1_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit; 

	/*Treadmill Desk Month-12*/ 
Title "PI.SAMPLEDATA_PIC_UNI_T2_B"; 
%MI_Combine(inests=PI.SAMPLEDATA_PIC_UNI_T2, outests=Ideal_M.SAMPLEDATA_PIC_T2_M, est=mean, se=stderr, label=Label, df_comp=15, target_sd_se=0.01);

Data Ideal_M.SAMPLEDATA_PIC_T2_M_B; 
set Ideal_M.SAMPLEDATA_PIC_T2_M;
Dataset="SAMPLEDATA_PIC_T2_M";
Variable=Label; 
Recommended_M=recommended_imputations;
Keep 
Dataset
Variable
Recommended_M
;
run;
quit;


%mend;


/*Run Code to output recommended imputations*/
%Ideal_M; 

ODS exclude none;  
/*Merge Outputs*/

Data M_output.SampleData_recommended_m_merged;
merge 
/*Variable A= Sedentary*/
Ideal_M.sampledata_pia_c1_m_b
Ideal_M.sampledata_pia_c2_m_b
Ideal_M.sampledata_pia_d1_m_b
Ideal_M.sampledata_pia_d2_m_b
Ideal_M.sampledata_pia_t1_m_b
Ideal_M.sampledata_pia_t2_m_b
/*Variable B= Standing*/
Ideal_M.sampledata_pib_c1_m_b
Ideal_M.sampledata_pib_c2_m_b
Ideal_M.sampledata_pib_d1_m_b
Ideal_M.sampledata_pib_d2_m_b
Ideal_M.sampledata_pib_t1_m_b
Ideal_M.sampledata_pib_t2_m_b
/*Variable C= Stepping*/ 
Ideal_M.sampledata_pic_c1_m_b
Ideal_M.sampledata_pic_c2_m_b
Ideal_M.sampledata_pic_d1_m_b
Ideal_M.sampledata_pic_d2_m_b
Ideal_M.sampledata_pic_t1_m_b
Ideal_M.sampledata_pic_t2_m_b
; 
by Dataset; 
If Variable= "_1_Sedentary" then Var="Sedentary";
If Variable= "_2_Sedentary" then Var="Sedentary";

If Variable= "_1_Standing" then Var="Standing_";
If Variable= "_2_Standing" then Var="Standing_";

If Variable= "_1_Stepping" then Var="Stepping_";
If Variable= "_2_Stepping" then Var="Stepping_";
Keep 
Dataset
Var
Recommended_M
;
run; 
quit; 

/*Compute max reccomended number of imputations for each physical activity variable of interest*/
ods exclude table;  
Proc Tabulate data=M_output.SampleData_recommended_m_merged 
out=M_output.SampleData_uniform_recommended_m; 
Var Recommended_M;
Table Recommended_M*Max; 
by var; 
run; 
quit; 

Data M_output.SampleData_uniform_recommended_m;
set M_output.SampleData_uniform_recommended_m; 
Variable=Var; 
keep 
Variable
Recommended_M_Max
; 
run; 
quit; 


	/*Step 4c: Second imputation with a uniform number of ideal imputations (M) at each compgroup level. 

/* From the "SampleData_uniform_recommended_m" output we can see that the ideal number of imputations (M)
for Sedentary, standing and stepping are 235, 197, and 71 imputations, respectively. We now run a second set
of imputations for all 18 models, adjusting the "nimpute=" function to these respective values.

The macro %M_Impute below uses the SAS "Proc MI" package to perform this second imputation phase, uses the SAS
"MIAnalyze" package to output pooled results of summary statistics (by comparison group) computed at each imputation 
level, and merges the imputed datasets by comparison groups into long formatted datasets that can then used in the final 
statistical analyses to compute effects by imputation level and generate pooled parameter estimates. */ 



/*Load directory to output final uniform imputation results: Here a sub directory titled "UniformImputations" has been 
created within the "SampleImputations" directory and called as the directory to store files using the SAS 
"Libname" function denoting the libary name within SAS as "M_UniIMP".*/ 

Libname M_UniIMP "C:\Users\diego\Documents\SampleImputation\UniformImputations"; 


/*Load Macro %M_Impute: 

  Below we use the following abbreviations in our output file names: 

  C1= seated control group at baseline
  C2= seated control group at month-12 
  D1= sit-to-stand desk group at baseline
  D2= sit-to-stand desk group at month-12
  T1= treadmill desk group at baseline
  T2= treadmill desk group at month-12

  UMA= uniform imputations for variable A (Sedentary) with recommended ideal M imputations
  UMB= uniform imputations for variable B (Standing) with recommended ideal M imputations
  UMC= uniform imputations for variable C (Stepping) with recommended ideal M imputations
*/

%Macro M_Impute;
ODS exclude all; 

/*Uniform Ideal M Imputations for Variable A=Sedentary*/ 
	/*Sedentary Control Baseline = C1*/ 
Proc MI data=  SampleI.SampleData_control_1 minimum=0 seed=15 nimpute=235 noprint out= M_UniImp.SampleData_MI_UMA_C1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_Body_Weight_kg
  /*Add imputation variables of interest*/_1_Sedentary; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMA_C1 noprint; 
Var _1_Sedentary; 
output out=M_UniImp.SampleData_MI_UMA_UNI_C1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMA_C1_B;
set M_UniImp.SampleData_MI_UMA_C1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Sedentary;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMA_C1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMA_UNI_C1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMA_MA_C1; 
run; 

Data M_UniImp.SampleData_UMA_Imp_SStats_C1; 
set M_UniImp.SampleData_MI_UMA_MA_C1; 
CompGroup=1; 
VARID="UMA";
RAND="Seated Control___";
Timepoint=1;
DatasetID=1; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMA_UNI_C1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMA_MA_C1; run; 

	/*Sedentary Control Month-12 = C2*/ 
Proc MI data=  SampleI.SampleData_control_2 minimum=0 seed=15 nimpute=235 noprint out= M_UniImp.SampleData_MI_UMA_C2;
  mcmc;
  Var /* Add Auxilliary Variables*/ _2_Waist_Circ__cm
  /*Add imputation variables of interest*/_2_Sedentary; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMA_C2 noprint; 
Var _2_Sedentary; 
output out=M_UniImp.SampleData_MI_UMA_UNI_C2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMA_C2_B;
set M_UniImp.SampleData_MI_UMA_C2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Sedentary;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMA_C2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMA_UNI_C2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMA_MA_C2; 
run; 

Data M_UniImp.SampleData_UMA_Imp_SStats_C2; 
set M_UniImp.SampleData_MI_UMA_MA_C2; 
CompGroup=4; 
VARID="UMA";
RAND="Seated Control___";
Timepoint=2;
DatasetID=2; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMA_UNI_C2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMA_MA_C2; run;


	/*Sedentary Desk Baseline = D1*/ 
Proc MI data=  SampleI.SampleData_desk_1 minimum=0 seed=15 nimpute=235 noprint out= M_UniImp.SampleData_MI_UMA_D1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_Waist_Circ__cm
  /*Add imputation variables of interest*/_1_Sedentary; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMA_D1 noprint; 
Var _1_Sedentary; 
output out=M_UniImp.SampleData_MI_UMA_UNI_D1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMA_D1_B;
set M_UniImp.SampleData_MI_UMA_D1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Sedentary;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMA_D1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMA_UNI_D1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMA_MA_D1; 
run; 

Data M_UniImp.SampleData_UMA_Imp_SStats_D1; 
set M_UniImp.SampleData_MI_UMA_MA_D1; 
CompGroup=2; 
VARID="UMA";
RAND="Sit-to-Stand Desk";
Timepoint=1;
DatasetID=3; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMA_UNI_D1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMA_MA_D1; run; 

	/*Sedentary Desk Month-12 = D2*/ 
Proc MI data=  SampleI.SampleData_desk_2 minimum=0 seed=15 nimpute=235 noprint out= M_UniImp.SampleData_MI_UMA_D2;
  mcmc;
  Var /* Add Auxilliary Variables*/ _2_Hip_Circ__cm
  /*Add imputation variables of interest*/_2_Sedentary; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMA_D2 noprint; 
Var _2_Sedentary; 
output out=M_UniImp.SampleData_MI_UMA_UNI_D2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMA_D2_B;
set M_UniImp.SampleData_MI_UMA_D2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Sedentary;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMA_D2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMA_UNI_D2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMA_MA_D2; 
run; 

Data M_UniImp.SampleData_UMA_Imp_SStats_D2; 
set M_UniImp.SampleData_MI_UMA_MA_D2; 
CompGroup=5; 
VARID="UMA";
RAND="Sit-to-Stand Desk";
Timepoint=2;
DatasetID=4; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMA_UNI_D2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMA_MA_D2; run;


	/*Sedentary Treadmill Baseline = T1*/ 
Proc MI data=  SampleI.SampleData_treadmill_1 minimum=0 seed=15 nimpute=235 noprint out= M_UniImp.SampleData_MI_UMA_T1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_Total_Mass
  /*Add imputation variables of interest*/_1_Sedentary; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMA_T1 noprint; 
Var _1_Sedentary; 
output out=M_UniImp.SampleData_MI_UMA_UNI_T1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMA_T1_B;
set M_UniImp.SampleData_MI_UMA_T1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Sedentary;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMA_T1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMA_UNI_T1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMA_MA_T1; 
run; 

Data M_UniImp.SampleData_UMA_Imp_SStats_T1; 
set M_UniImp.SampleData_MI_UMA_MA_T1; 
CompGroup=3; 
VARID="UMA";
RAND="Treadmill Desk___";
Timepoint=1;
DatasetID=5; 
N=16; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMA_UNI_T1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMA_MA_T1; run; 

	/*Sedentary Treadmill Month-12 = T2*/ 
Proc MI data=  SampleI.SampleData_treadmill_2 minimum=0 seed=15 nimpute=235 noprint out= M_UniImp.SampleData_MI_UMA_T2;
  mcmc;
  Var /* Add Auxilliary Variables*/ _2_Leg_Fat_Perc
  /*Add imputation variables of interest*/_2_Sedentary; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMA_T2 noprint; 
Var _2_Sedentary; 
output out=M_UniImp.SampleData_MI_UMA_UNI_T2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMA_T2_B;
set M_UniImp.SampleData_MI_UMA_T2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Sedentary;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMA_T2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMA_UNI_T2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMA_MA_T2; 
run; 

Data M_UniImp.SampleData_UMA_Imp_SStats_T2; 
set M_UniImp.SampleData_MI_UMA_MA_T2; 
CompGroup=6; 
VARID="UMA";
RAND="Treadmill Desk___";
Timepoint=2;
DatasetID=6; 
N=16; 
Stdev= Stderr*(SQRT(N));
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMA_UNI_T2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMA_MA_T2; run;

/*Merge Summary Stats*/ 
Data M_UniImp.SampleData_UMA_imp_sstats; 
merge 
M_UniImp.SampleData_UMA_imp_sstats_c1
M_UniImp.SampleData_UMA_imp_sstats_c2
M_UniImp.SampleData_UMA_imp_sstats_d1
M_UniImp.SampleData_UMA_imp_sstats_d2
M_UniImp.SampleData_UMA_imp_sstats_t1
M_UniImp.SampleData_UMA_imp_sstats_t2
;
By DatasetID;
Outcome= "Daily Sedentary Time_ (Hours)"; 
run; 

Proc Delete data=M_UniImp.SampleData_UMA_imp_sstats_c1; run;
Proc Delete data=M_UniImp.SampleData_UMA_imp_sstats_c2; run;
Proc Delete data=M_UniImp.SampleData_UMA_imp_sstats_d1; run;
Proc Delete data=M_UniImp.SampleData_UMA_imp_sstats_d2; run;
Proc Delete data=M_UniImp.SampleData_UMA_imp_sstats_t1; run;
Proc Delete data=M_UniImp.SampleData_UMA_imp_sstats_t2; run;


/*Step 3: Generate Long Format Datasets*/

/*Generate Long Format Dataset For Var Sedentary*/ 
	/*Step 1: Merge Imputed Datasets by ID*/ 
	Proc sort data=M_UniImp.SampleData_mi_UMA_c1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMA_c2_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMA_d1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMA_d2_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMA_t1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMA_t2_b; by Participant_ID; run; Quit;
		/*Merge Control*/
	Data M_UniImp.SampleData_MI_UMA_C; 
	merge 
	M_UniImp.SampleData_mi_UMA_c1_b
	M_UniImp.SampleData_mi_UMA_c2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMA_C; by _Imputation_; run; quit;
		/*Merge Desk*/ 
	Data M_UniImp.SampleData_MI_UMA_D; 
	merge 
	M_UniImp.SampleData_mi_UMA_D1_b
	M_UniImp.SampleData_mi_UMA_D2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMA_D; by _Imputation_; run; quit;

		/*Merge Treadmill*/ 
	Data M_UniImp.SampleData_MI_UMA_T; 
	merge 
	M_UniImp.SampleData_mi_UMA_T1_b
	M_UniImp.SampleData_mi_UMA_T2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMA_T; by _Imputation_; run; quit;

	Proc Delete data=M_UniImp.SampleData_mi_UMA_c1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMA_c2_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMA_d1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMA_d2_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMA_t1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMA_t2_b; run; Quit;
	/*Step 2: Convert from wide to long format*/ 
		/*Control*/ 
	Data M_UniImp.SampleData_MI_UMA_C_Long;
	set M_UniImp.SampleData_MI_UMA_C;
	Sedentary= _1_Sedentary; Timepoint=1; Compgroup=1; Output; 
	Sedentary= _2_Sedentary; Timepoint=2; Compgroup=4; Output;
	Drop _1_Sedentary _2_Sedentary; 
	run; quit; 
		/*Desk*/ 
	Data M_UniImp.SampleData_MI_UMA_D_Long;
	set M_UniImp.SampleData_MI_UMA_D;
	Sedentary= _1_Sedentary; Timepoint=1; Compgroup=2; Output; 
	Sedentary= _2_Sedentary; Timepoint=2; Compgroup=5; Output;
	Drop _1_Sedentary _2_Sedentary; 
	run; quit; 
		/*Treadmill*/ 
	Data M_UniImp.SampleData_MI_UMA_T_Long;
	set M_UniImp.SampleData_MI_UMA_T;
	Sedentary= _1_Sedentary; Timepoint=1; Compgroup=3; Output; 
	Sedentary= _2_Sedentary; Timepoint=2; Compgroup=6; Output;
	Drop _1_Sedentary _2_Sedentary; 
	run; quit; 

	Proc delete data=M_UniImp.SampleData_MI_UMA_C; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMA_D; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMA_T; run; quit;
	/*Step 3: Merge Long Format Datasets by ID*/ 
	Proc Sort data= M_UniImp.SampleData_MI_UMA_C_Long; by Participant_ID; run; quit; 
	Proc Sort data= M_UniImp.SampleData_MI_UMA_D_Long; by Participant_ID; run; quit; 
	Proc Sort data= M_UniImp.SampleData_MI_UMA_T_Long; by Participant_ID; run; quit; 

	Data M_UniImp.SampleData_MI_UMA_Long;
	Merge 
	M_UniImp.SampleData_MI_UMA_C_Long
	M_UniImp.SampleData_MI_UMA_D_Long
	M_UniImp.SampleData_MI_UMA_T_Long
	;
	by Participant_ID; 
	run; quit; 

	Proc sort data=M_UniImp.SampleData_MI_UMA_Long; by _Imputation_; run; quit; 

	Proc delete data=M_UniImp.SampleData_MI_UMA_C_Long; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMA_D_Long; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMA_T_Long; run; quit;

/*End Uniform Ideal M Imputations for Var Sedentary*/ 


/*Uniform Ideal M Imputations for Variable B=Standing*/ 
	/*Standing Control Baseline = C1*/ 
Proc MI data=  SampleI.SampleData_control_1 minimum=0 seed=15 nimpute=197 noprint out= M_UniImp.SampleData_MI_UMB_C1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_Body_Weight_kg 
  /*Add imputation variables of interest*/_1_Standing; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMB_C1 noprint; 
Var _1_Standing; 
output out=M_UniImp.SampleData_MI_UMB_UNI_C1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMB_C1_B;
set M_UniImp.SampleData_MI_UMB_C1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Standing;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMB_C1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMB_UNI_C1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMB_MA_C1; 
run; 

Data M_UniImp.SampleData_UMB_Imp_SStats_C1; 
set M_UniImp.SampleData_MI_UMB_MA_C1; 
CompGroup=1; 
VARID="UMB";
RAND="Seated Control___";
Timepoint=1;
DatasetID=1; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMB_UNI_C1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMB_MA_C1; run; 

	/*Standing Control Month-12 = C2*/ 
Proc MI data=  SampleI.SampleData_control_2 minimum=0 seed=15 nimpute=197 noprint out= M_UniImp.SampleData_MI_UMB_C2;
  mcmc;
  Var /* Add Auxilliary Variables*/ _2_Waist_Circ__cm
  /*Add imputation variables of interest*/_2_Standing; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMB_C2 noprint; 
Var _2_Standing; 
output out=M_UniImp.SampleData_MI_UMB_UNI_C2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMB_C2_B;
set M_UniImp.SampleData_MI_UMB_C2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Standing;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMB_C2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMB_UNI_C2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMB_MA_C2; 
run; 

Data M_UniImp.SampleData_UMB_Imp_SStats_C2; 
set M_UniImp.SampleData_MI_UMB_MA_C2; 
CompGroup=4; 
VARID="UMB";
RAND="Seated Control___";
Timepoint=2;
DatasetID=2; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMB_UNI_C2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMB_MA_C2; run;


	/*Standing Desk Baseline = D1*/ 
Proc MI data=  SampleI.SampleData_desk_1 minimum=0 seed=15 nimpute=197 noprint out= M_UniImp.SampleData_MI_UMB_D1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_DBP_mmHg
  /*Add imputation variables of interest*/_1_Standing; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMB_D1 noprint; 
Var _1_Standing; 
output out=M_UniImp.SampleData_MI_UMB_UNI_D1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMB_D1_B;
set M_UniImp.SampleData_MI_UMB_D1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Standing;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMB_D1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMB_UNI_D1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMB_MA_D1; 
run; 

Data M_UniImp.SampleData_UMB_Imp_SStats_D1; 
set M_UniImp.SampleData_MI_UMB_MA_D1; 
CompGroup=2; 
VARID="UMB";
RAND="Sit-to-Stand Desk";
Timepoint=1;
DatasetID=3; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMB_UNI_D1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMB_MA_D1; run; 

	/*Standing Desk Month-12 = D2*/ 
Proc MI data=  SampleI.SampleData_desk_2 minimum=0 seed=15 nimpute=197 noprint out= M_UniImp.SampleData_MI_UMB_D2;
  mcmc;
  Var /* Add Auxilliary Variables*/ _2_Waist_Circ__cm
  /*Add imputation variables of interest*/_2_Standing; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMB_D2 noprint; 
Var _2_Standing; 
output out=M_UniImp.SampleData_MI_UMB_UNI_D2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMB_D2_B;
set M_UniImp.SampleData_MI_UMB_D2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Standing;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMB_D2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMB_UNI_D2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMB_MA_D2; 
run; 

Data M_UniImp.SampleData_UMB_Imp_SStats_D2; 
set M_UniImp.SampleData_MI_UMB_MA_D2; 
CompGroup=5; 
VARID="UMB";
RAND="Sit-to-Stand Desk";
Timepoint=2;
DatasetID=4; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMB_UNI_D2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMB_MA_D2; run;


	/*Standing Treadmill Baseline = T1*/ 
Proc MI data=  SampleI.SampleData_treadmill_1 minimum=0 seed=15 nimpute=197 noprint out= M_UniImp.SampleData_MI_UMB_T1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_HbA1C
  /*Add imputation variables of interest*/_1_Standing; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMB_T1 noprint; 
Var _1_Standing; 
output out=M_UniImp.SampleData_MI_UMB_UNI_T1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMB_T1_B;
set M_UniImp.SampleData_MI_UMB_T1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Standing;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMB_T1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMB_UNI_T1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMB_MA_T1; 
run; 

Data M_UniImp.SampleData_UMB_Imp_SStats_T1; 
set M_UniImp.SampleData_MI_UMB_MA_T1; 
CompGroup=3; 
VARID="UMB";
RAND="Treadmill Desk___";
Timepoint=1;
DatasetID=5; 
N=16; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMB_UNI_T1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMB_MA_T1; run; 

	/*Standing Treadmill Month-12 = T2*/ 
Proc MI data=  SampleI.SampleData_treadmill_2 minimum=0 seed=15 nimpute=197 noprint out= M_UniImp.SampleData_MI_UMB_T2;
  mcmc;
  Var /* Add Auxilliary Variables*/  _2_Waist_Hip_Ratio
  /*Add imputation variables of interest*/_2_Standing; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMB_T2 noprint; 
Var _2_Standing; 
output out=M_UniImp.SampleData_MI_UMB_UNI_T2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMB_T2_B;
set M_UniImp.SampleData_MI_UMB_T2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Standing;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMB_T2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMB_UNI_T2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMB_MA_T2; 
run; 

Data M_UniImp.SampleData_UMB_Imp_SStats_T2; 
set M_UniImp.SampleData_MI_UMB_MA_T2; 
CompGroup=6; 
VARID="UMB";
RAND="Treadmill Desk___";
Timepoint=2;
DatasetID=6; 
N=16; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMB_UNI_T2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMB_MA_T2; run;

/*Merge Summary Stats*/ 
Data M_UniImp.SampleData_UMB_imp_sstats; 
merge 
M_UniImp.SampleData_UMB_imp_sstats_c1
M_UniImp.SampleData_UMB_imp_sstats_c2
M_UniImp.SampleData_UMB_imp_sstats_d1
M_UniImp.SampleData_UMB_imp_sstats_d2
M_UniImp.SampleData_UMB_imp_sstats_t1
M_UniImp.SampleData_UMB_imp_sstats_t2
;
By DatasetID;
Outcome="Daily Standing Time (Hours)"; 
run; 

Proc Delete data=M_UniImp.SampleData_UMB_imp_sstats_c1; run;
Proc Delete data=M_UniImp.SampleData_UMB_imp_sstats_c2; run;
Proc Delete data=M_UniImp.SampleData_UMB_imp_sstats_d1; run;
Proc Delete data=M_UniImp.SampleData_UMB_imp_sstats_d2; run;
Proc Delete data=M_UniImp.SampleData_UMB_imp_sstats_t1; run;
Proc Delete data=M_UniImp.SampleData_UMB_imp_sstats_t2; run;


/*Step 3: Generate Long Format Datasets*/

/*Generate Long Format Dataset For Var Standing*/ 
	/*Step 1: Merge Imputed Datasets by ID*/ 
	Proc sort data=M_UniImp.SampleData_mi_UMB_c1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMB_c2_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMB_d1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMB_d2_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMB_t1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMB_t2_b; by Participant_ID; run; Quit;
		/*Merge Control*/
	Data M_UniImp.SampleData_MI_UMB_C; 
	merge 
	M_UniImp.SampleData_mi_UMB_c1_b
	M_UniImp.SampleData_mi_UMB_c2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMB_C; by _Imputation_; run; quit;
		/*Merge Desk*/ 
	Data M_UniImp.SampleData_MI_UMB_D; 
	merge 
	M_UniImp.SampleData_mi_UMB_D1_b
	M_UniImp.SampleData_mi_UMB_D2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMB_D; by _Imputation_; run; quit;

		/*Merge Treadmill*/ 
	Data M_UniImp.SampleData_MI_UMB_T; 
	merge 
	M_UniImp.SampleData_mi_UMB_T1_b
	M_UniImp.SampleData_mi_UMB_T2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMB_T; by _Imputation_; run; quit;

	Proc Delete data=M_UniImp.SampleData_mi_UMB_c1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMB_c2_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMB_d1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMB_d2_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMB_t1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMB_t2_b; run; Quit;
	/*Step 2: Convert from wide to long format*/ 
		/*Control*/ 
	Data M_UniImp.SampleData_MI_UMB_C_Long;
	set M_UniImp.SampleData_MI_UMB_C;
	Standing= _1_Standing; Timepoint=1; Compgroup=1; Output; 
	Standing= _2_Standing; Timepoint=2; Compgroup=4; Output;
	Drop _1_Standing _2_Standing; 
	run; quit; 
		/*Desk*/ 
	Data M_UniImp.SampleData_MI_UMB_D_Long;
	set M_UniImp.SampleData_MI_UMB_D;
	Standing= _1_Standing; Timepoint=1; Compgroup=2; Output; 
	Standing= _2_Standing; Timepoint=2; Compgroup=5; Output;
	Drop _1_Standing _2_Standing; 
	run; quit; 
		/*Treadmill*/ 
	Data M_UniImp.SampleData_MI_UMB_T_Long;
	set M_UniImp.SampleData_MI_UMB_T;
	Standing= _1_Standing; Timepoint=1; Compgroup=3; Output; 
	Standing= _2_Standing; Timepoint=2; Compgroup=6; Output;
	Drop _1_Standing _2_Standing; 
	run; quit; 

	Proc delete data=M_UniImp.SampleData_MI_UMB_C; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMB_D; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMB_T; run; quit;
	/*Step 3: Merge Long Format Datasets by ID*/ 
	Proc Sort data= M_UniImp.SampleData_MI_UMB_C_Long; by Participant_ID; run; quit; 
	Proc Sort data= M_UniImp.SampleData_MI_UMB_D_Long; by Participant_ID; run; quit; 
	Proc Sort data= M_UniImp.SampleData_MI_UMB_T_Long; by Participant_ID; run; quit; 

	Data M_UniImp.SampleData_MI_UMB_Long;
	Merge 
	M_UniImp.SampleData_MI_UMB_C_Long
	M_UniImp.SampleData_MI_UMB_D_Long
	M_UniImp.SampleData_MI_UMB_T_Long
	;
	by Participant_ID; 
	run; quit; 

	Proc sort data=M_UniImp.SampleData_MI_UMB_Long; by _Imputation_; run; quit; 

	Proc delete data=M_UniImp.SampleData_MI_UMB_C_Long; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMB_D_Long; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMB_T_Long; run; quit;


/*End Uniform Ideal M Imputations for Var Standing*/

/*Uniform Ideal M Imputations for Variable C=Stepping*/ 
	/*Stepping Control Baseline = C1*/ 
Proc MI data=  SampleI.SampleData_control_1 minimum=0 seed=15 nimpute=71 noprint out= M_UniImp.SampleData_MI_UMC_C1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_Body_Weight_kg 
  /*Add imputation variables of interest*/_1_Stepping; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMC_C1 noprint; 
Var _1_Stepping; 
output out=M_UniImp.SampleData_MI_UMC_UNI_C1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMC_C1_B;
set M_UniImp.SampleData_MI_UMC_C1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Stepping;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMC_C1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMC_UNI_C1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMC_MA_C1; 
run; 

Data M_UniImp.SampleData_UMC_Imp_SStats_C1; 
set M_UniImp.SampleData_MI_UMC_MA_C1; 
CompGroup=1; 
VARID="UMC";
RAND="Seated Control___";
Timepoint=1;
DatasetID=1; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMC_UNI_C1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMC_MA_C1; run; 

	/*Stepping Control Month-12 = C2*/ 
Proc MI data=  SampleI.SampleData_control_2 minimum=0 seed=15 nimpute=71 noprint out= M_UniImp.SampleData_MI_UMC_C2;
  mcmc;
  Var /* Add Auxilliary Variables*/ _2_Waist_Circ__cm
  /*Add imputation variables of interest*/_2_Stepping; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMC_C2 noprint; 
Var _2_Stepping; 
output out=M_UniImp.SampleData_MI_UMC_UNI_C2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMC_C2_B;
set M_UniImp.SampleData_MI_UMC_C2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Stepping;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMC_C2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMC_UNI_C2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMC_MA_C2; 
run; 

Data M_UniImp.SampleData_UMC_Imp_SStats_C2; 
set M_UniImp.SampleData_MI_UMC_MA_C2; 
CompGroup=4; 
VARID="UMC";
RAND="Seated Control___";
Timepoint=2;
DatasetID=2; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMC_UNI_C2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMC_MA_C2; run;


	/*Stepping Desk Baseline = D1*/ 
Proc MI data=  SampleI.SampleData_desk_1 minimum=0 seed=15 nimpute=71 noprint out= M_UniImp.SampleData_MI_UMC_D1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_Waist_Hip_Ratio
  /*Add imputation variables of interest*/_1_Stepping; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMC_D1 noprint; 
Var _1_Stepping; 
output out=M_UniImp.SampleData_MI_UMC_UNI_D1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMC_D1_B;
set M_UniImp.SampleData_MI_UMC_D1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Stepping;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMC_D1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMC_UNI_D1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMC_MA_D1; 
run; 

Data M_UniImp.SampleData_UMC_Imp_SStats_D1; 
set M_UniImp.SampleData_MI_UMC_MA_D1; 
CompGroup=2; 
VARID="UMC";
RAND="Sit-to-Stand Desk";
Timepoint=1;
DatasetID=3; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMC_UNI_D1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMC_MA_D1; run; 

	/*Stepping Desk Month-12 = D2*/ 
Proc MI data=  SampleI.SampleData_desk_2 minimum=0 seed=15 nimpute=71 noprint out= M_UniImp.SampleData_MI_UMC_D2;
  mcmc;
  Var /* Add Auxilliary Variables*/ _2_Hip_Circ__cm
  /*Add imputation variables of interest*/_2_Stepping; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMC_D2 noprint; 
Var _2_Stepping; 
output out=M_UniImp.SampleData_MI_UMC_UNI_D2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMC_D2_B;
set M_UniImp.SampleData_MI_UMC_D2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Stepping;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMC_D2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMC_UNI_D2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMC_MA_D2; 
run; 

Data M_UniImp.SampleData_UMC_Imp_SStats_D2; 
set M_UniImp.SampleData_MI_UMC_MA_D2; 
CompGroup=5; 
VARID="UMC";
RAND="Sit-to-Stand Desk";
Timepoint=2;
DatasetID=4; 
N=13; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMC_UNI_D2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMC_MA_D2; run;


	/*Stepping Treadmill Baseline = T1*/ 
Proc MI data=  SampleI.SampleData_treadmill_1 minimum=0 seed=15 nimpute=71 noprint out= M_UniImp.SampleData_MI_UMC_T1;
  mcmc;
  Var /* Add Auxilliary Variables*/ _1_Waist_Circ__cm
  /*Add imputation variables of interest*/_1_Stepping; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMC_T1 noprint; 
Var _1_Stepping; 
output out=M_UniImp.SampleData_MI_UMC_UNI_T1 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMC_T1_B;
set M_UniImp.SampleData_MI_UMC_T1;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_1_Stepping;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMC_T1; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMC_UNI_T1; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMC_MA_T1; 
run; 

Data M_UniImp.SampleData_UMC_Imp_SStats_T1; 
set M_UniImp.SampleData_MI_UMC_MA_T1; 
CompGroup=3; 
VARID="UMC";
RAND="Treadmill Desk___";
Timepoint=1;
DatasetID=5; 
N=16; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMC_UNI_T1; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMC_MA_T1; run; 

	/*Stepping Treadmill Month-12 = T2*/ 
Proc MI data=  SampleI.SampleData_treadmill_2 minimum=0 seed=15 nimpute=71 noprint out= M_UniImp.SampleData_MI_UMC_T2;
  mcmc;
  Var /* Add Auxilliary Variables*/ _2_Body_Weight_kg
  /*Add imputation variables of interest*/_2_Stepping; 
run;

Proc univariate data=M_UniImp.SampleData_MI_UMC_T2 noprint; 
Var _2_Stepping; 
output out=M_UniImp.SampleData_MI_UMC_UNI_T2 mean=Mean stderr= stderr; 
by _Imputation_; 
run; 

Data M_UniImp.SampleData_MI_UMC_T2_B;
set M_UniImp.SampleData_MI_UMC_T2;
keep 
/*Identifiers*/ 
_Imputation_ CompGroup Participant_ID Age__Years_ Gender Ethnicity Race Rand Cluster Timepoint
/*Imputed Variable*/ 
_2_Stepping;
run;

Proc Delete data=M_UniImp.SampleData_MI_UMC_T2; run; 

proc mianalyze data=M_UniImp.SampleData_MI_UMC_UNI_T2; 
modeleffects mean;
stderr stderr;
ods output ParameterEstimates=M_UniImp.SampleData_MI_UMC_MA_T2; 
run; 

Data M_UniImp.SampleData_UMC_Imp_SStats_T2; 
set M_UniImp.SampleData_MI_UMC_MA_T2; 
CompGroup=6; 
VARID="UMC";
RAND="Treadmill Desk___";
Timepoint=2;
DatasetID=6; 
N=16; 
Stdev= Stderr*(SQRT(N)); 
Keep 
DatasetID VARID Compgroup Rand Timepoint NImpute N Estimate StdErr Stdev LCLMean UCLMean;
run; 

Proc Delete data=M_UniImp.SampleData_MI_UMC_UNI_T2; run; 
Proc Delete data=M_UniImp.SampleData_MI_UMC_MA_T2; run;

/*Merge Summary Stats*/ 
Data M_UniImp.SampleData_UMC_imp_sstats; 
merge 
M_UniImp.SampleData_UMC_imp_sstats_c1
M_UniImp.SampleData_UMC_imp_sstats_c2
M_UniImp.SampleData_UMC_imp_sstats_d1
M_UniImp.SampleData_UMC_imp_sstats_d2
M_UniImp.SampleData_UMC_imp_sstats_t1
M_UniImp.SampleData_UMC_imp_sstats_t2
;
By DatasetID;
Outcome="Daily Stepping Time (Hours)"; 
run; 

Proc Delete data=M_UniImp.SampleData_UMC_imp_sstats_c1; run;
Proc Delete data=M_UniImp.SampleData_UMC_imp_sstats_c2; run;
Proc Delete data=M_UniImp.SampleData_UMC_imp_sstats_d1; run;
Proc Delete data=M_UniImp.SampleData_UMC_imp_sstats_d2; run;
Proc Delete data=M_UniImp.SampleData_UMC_imp_sstats_t1; run;
Proc Delete data=M_UniImp.SampleData_UMC_imp_sstats_t2; run;


/*Step 3: Generate Long Format Datasets*/

/*Generate Long Format Dataset For Var Stepping*/ 
	/*Step 1: Merge Imputed Datasets by ID*/ 
	Proc sort data=M_UniImp.SampleData_mi_UMC_c1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMC_c2_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMC_d1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMC_d2_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMC_t1_b; by Participant_ID; run; Quit;
	Proc sort data=M_UniImp.SampleData_mi_UMC_t2_b; by Participant_ID; run; Quit;
		/*Merge Control*/
	Data M_UniImp.SampleData_MI_UMC_C; 
	merge 
	M_UniImp.SampleData_mi_UMC_c1_b
	M_UniImp.SampleData_mi_UMC_c2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMC_C; by _Imputation_; run; quit;
		/*Merge Desk*/ 
	Data M_UniImp.SampleData_MI_UMC_D; 
	merge 
	M_UniImp.SampleData_mi_UMC_D1_b
	M_UniImp.SampleData_mi_UMC_D2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMC_D; by _Imputation_; run; quit;

		/*Merge Treadmill*/ 
	Data M_UniImp.SampleData_MI_UMC_T; 
	merge 
	M_UniImp.SampleData_mi_UMC_T1_b
	M_UniImp.SampleData_mi_UMC_T2_b
	;
	Drop CompGroup Timepoint;
	by Participant_ID; run; Quit;

	Proc sort data=M_UniImp.SampleData_MI_UMC_T; by _Imputation_; run; quit;

	Proc Delete data=M_UniImp.SampleData_mi_UMC_c1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMC_c2_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMC_d1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMC_d2_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMC_t1_b; run; Quit;
	Proc Delete data=M_UniImp.SampleData_mi_UMC_t2_b; run; Quit;
	/*Step 2: Convert from wide to long format*/ 
		/*Control*/ 
	Data M_UniImp.SampleData_MI_UMC_C_Long;
	set M_UniImp.SampleData_MI_UMC_C;
	Stepping= _1_Stepping; Timepoint=1; Compgroup=1; Output; 
	Stepping= _2_Stepping; Timepoint=2; Compgroup=4; Output;
	Drop _1_Stepping _2_Stepping; 
	run; quit; 
		/*Desk*/ 
	Data M_UniImp.SampleData_MI_UMC_D_Long;
	set M_UniImp.SampleData_MI_UMC_D;
	Stepping= _1_Stepping; Timepoint=1; Compgroup=2; Output; 
	Stepping= _2_Stepping; Timepoint=2; Compgroup=5; Output;
	Drop _1_Stepping _2_Stepping; 
	run; quit; 
		/*Treadmill*/ 
	Data M_UniImp.SampleData_MI_UMC_T_Long;
	set M_UniImp.SampleData_MI_UMC_T;
	Stepping= _1_Stepping; Timepoint=1; Compgroup=3; Output; 
	Stepping= _2_Stepping; Timepoint=2; Compgroup=6; Output;
	Drop _1_Stepping _2_Stepping; 
	run; quit; 

	Proc delete data=M_UniImp.SampleData_MI_UMC_C; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMC_D; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMC_T; run; quit;
	/*Step 3: Merge Long Format Datasets by ID*/ 
	Proc Sort data= M_UniImp.SampleData_MI_UMC_C_Long; by Participant_ID; run; quit; 
	Proc Sort data= M_UniImp.SampleData_MI_UMC_D_Long; by Participant_ID; run; quit; 
	Proc Sort data= M_UniImp.SampleData_MI_UMC_T_Long; by Participant_ID; run; quit; 

	Data M_UniImp.SampleData_MI_UMC_Long;
	Merge 
	M_UniImp.SampleData_MI_UMC_C_Long
	M_UniImp.SampleData_MI_UMC_D_Long
	M_UniImp.SampleData_MI_UMC_T_Long
	;
	by Participant_ID; 
	run; quit; 

	Proc sort data=M_UniImp.SampleData_MI_UMC_Long; by _Imputation_; run; quit; 

	Proc delete data=M_UniImp.SampleData_MI_UMC_C_Long; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMC_D_Long; run; quit;
	Proc delete data=M_UniImp.SampleData_MI_UMC_T_Long; run; quit;

/*End Uniform Ideal M Imputations for Var Stepping*/

%mend;


/*Run Code*/
%M_Impute; 

ODS exclude none; 

/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/


/* Step 5: Statistical Analyses of Imputed Datasets and Pooling of Results. 

Here were demonstrate a statistical analyses of imputed datasets from step 4C using linear mixed models to quantify within- and 
between-group post-hoc effects from baseline to month-12 follow-up. A linear mixed model is run at each imputation level, and 
estimates from each of these analyses are then pooled together using the SAS MI Analyze function to account for both within- 
and between-imputation variance in paramater estimates. In our example, we output 9 post-hoc comparisons of interest 
(i.e., 3 head-to-head comparisons among the three randomization groups at each of baseline and month-12 follow-up, and 3 within-group 
differences from baseline to month-12 follow-up. */ 

	/*Step 5a. First we load directories to save out outputs*/ 
Libname MM_LSM "C:\Users\diego\Documents\SampleImputation\MixedModels\MM_LSM";
Libname MM_E "C:\Users\diego\Documents\SampleImputation\MixedModels\MM_E";
Libname Trans "C:\Users\diego\Documents\SampleImputation\MixedModels\Trans";


	/*Step 5b. Next we load our macro "%MM" which will run a linear mixed model for each of the three physical activity variables of 
interests at each of their respective imputation levels, and then pools the results of post-hoc analyses to produce the nine post-hoc
comparisons mentioned above. These steps use the SAS "Proc Mixed" and "Proc MI Analyze" functions. In our linear mixed model, we specify
the following options: 

1) We specify maximum likelihood estimates with the "method=ml" parameter. 

2) We specify the Kenward-Roger degrees of freedom method (ddfm=Kr) as this offers a more precise small-sample estimator for the
variance-covariance of fixed effects paramaters and the approximate denominator degrees of freedom in F-tests. 

3) We specify repeated measures by "timepoint" and the subject unit of analysis as the "participant_ID". We note that the unit of
analyses here can be specified to be the "cluster" if this were of interest, but since our clustering had no significant effect
on outcomes, we chose to analyze at the "participant" level. To account for the random effects of the cluster randomization study 
design we specify a random intercept in our models with the random intercept/subject="Cluster" parameter. 

4) In our model statement the physical activity outcome is our dependent variable and CompGroup is our independent variable
representing the timepoint*randomization group interaction term. 

5) The LSmeans statement outputs maximimum likelihood estimates of means for all timepoint and group combinations. Unlike our
pooled summary statistics output in our "%M_Impute" macro above, the fixed effects of repeated measures and random effects of
cluster randomization are accounted for in these estimates. In addition, if any covariates were added to the model statement
[e.g., controlling for baseline differences (if deemed significant/necessary despite randomization), demographics or activity monitor 
wear time] these estimates would be controlled for those variables. We do not add any covariates in our model statement below. 

6) For simplicity and to avoid making assumptions about the covariance correlation structure among repated measures within subject,
we specify unstructured correlation covariances in the mixed models below. 

/*7) For each posthoc comparison we print confidence limits and Bonferroni adjusted alpha value (i.e., 0.05/ 9 comparisons = 0.0056). This value
can be adjusted if less posthoc comparisons are selected. We use the estimate statement to specify the comparisons of interest. Group A vs. group B 
indicates the group B-A difference. */ 
 

%Macro MM; 
ODS exclude all; 

Proc format; 
value CompGroup  1="A) Seated Control Baseline"
				 2="B) Sit-to-Stand Desk Baseline"
			     3="C) Treadmill Desk Baseline"
				 4="D) Seated Control Month-12"
				 5="E) Sit-to-Stand Desk Month-12"
				 6="F) Treadmill Desk Month-12";


/* Part 1: Run Mixed Model for UMA=Sedentary*/ 

proc mixed data=M_UniIMP.sampledata_mi_uma_long method=ml; 
format CompGroup CompGroup.;
class Participant_ID Cluster timepoint CompGroup Rand; 
by _Imputation_;
model Sedentary= CompGroup/ddfm=Kr; 
repeated timepoint/subject=Participant_ID type=UN; 
random intercept/subject=cluster;
LSmeans CompGroup / CL; 
/*Posthoc Comparisons*/ 
/* Within-Group Comparisons*/ 
Estimate "Seated Control: Change Baseline to Month 12" CompGroup -1 0 0 1 0 0/alpha= 0.0056; 
Estimate "Sit-to-Stand Desk: Change Baseline to Month 12" CompGroup 0 -1 0 0 1 0/alpha= 0.0056; 
Estimate "Treadmill Desk: Change Baseline to Month 12" CompGroup 0 0 -1 0 0 1/alpha= 0.0056;  
/*Between-Group Comparisons*/ 
	/*Baseline*/
Estimate "Baseline: Seated Control vs. Sit-to-Stand Desk" CompGroup -1 1 0 0 0 0/alpha= 0.0056;  
Estimate "Baseline: Seated Control vs. Treadmill Desk" CompGroup -1 0 1 0 0 0/alpha= 0.0056; 
Estimate "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" CompGroup 0 -1 1 0 0 0/alpha= 0.0056; 
	/*Month-12*/ 
Estimate "Month-12: Seated Control vs. Sit-to-Stand Desk" CompGroup 0 0 0 -1 1 0/alpha= 0.0056;  
Estimate "Month-12: Seated Control vs. Treadmill Desk" CompGroup 0 0 0 -1 0 1/alpha= 0.0056; 
Estimate "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" CompGroup 0 0 0 0 -1 1/alpha= 0.0056;  
/*Outputting Results*/  
/*ods select modelinfo LSMeans Estimates ;*/ 
ods output LSMeans= MM_LSM.SAMPLEDATA_MM_LSM_UMA  
		   Estimates= MM_E.SAMPLEDATA_MM_E_UMA ; 
run;
quit;  

/* Generate MI Analyzed LSMeans*/ 
proc sort data=MM_LSM.SAMPLEDATA_MM_LSM_UMA ; by CompGroup; run; 

Proc Mianalyze data=MM_LSM.SAMPLEDATA_MM_LSM_UMA ;  
Modeleffects estimate;
stderr StdErr; 
ods output ParameterEstimates= MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMA ; 
by CompGroup; 
run; 
quit;

Data MM_LSM.SAMPLEDATA_MM_LSM_MIAB_UMA ; 
set MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMA ; 
N=.; if CompGroup=1 then N=13; 
if CompGroup=2 then N=13; 
if CompGroup=3 then N=16; 
if CompGroup=4 then N=13; 
if CompGroup=5 then N=13; 
if CompGroup=6 then N=16; 
STDEV= StdErr*(sqrt(N)); 
VAR= "UMA";
VARNAME="Mean_Daily_Sedentary_Hours";
Drop Parm DF Min Max Theta0 tValue Probt; 
run; 
quit; 

proc delete data= MM_LSM.SAMPLEDATA_MM_LSM_UMA ; run; quit; 
proc delete data= MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMA ; run; quit; 

/*Generate MI Analyzed Estimates*/ 
proc sort data=MM_E.SAMPLEDATA_MM_E_UMA ; by Label; run;

Proc Mianalyze data=MM_E.SAMPLEDATA_MM_E_UMA ; 
Modeleffects estimate;
stderr StdErr; 
ods output ParameterEstimates= MM_E.SAMPLEDATA_MM_E_MIA_UMA ;
by Label; 
run; 
Quit; 

Data MM_E.SAMPLEDATA_MM_E_MIAB_UMA ; 
set MM_E.SAMPLEDATA_MM_E_MIA_UMA ; 
N1=.; N2=.; 
LabelID=.; 
/*Intragroup Baseline - Month12*/ 
if Label= "Seated Control: Change Baseline to Month 12" then N1=13; if Label= "Seated Control: Change Baseline to Month 12" then N2=13; if Label= "Seated Control: Change Baseline to Month 12"   then LabelID=1;
if Label= "Sit-to-Stand Desk: Change Baseline to Month 12" then N1=13; if Label= "Sit-to-Stand Desk: Change Baseline to Month 12" then N2=13; if Label= "Sit-to-Stand Desk: Change Baseline to Month 12"  then LabelID=2;
if Label= "Treadmill Desk: Change Baseline to Month 12" then N1=16; if Label= "Treadmill Desk: Change Baseline to Month 12" then N2=16; if Label= "Treadmill Desk: Change Baseline to Month 12"  then LabelID=3;
/*Intergroup Baseline*/ 
if Label= "Baseline: Seated Control vs. Sit-to-Stand Desk" then N1=13; if Label= "Baseline: Seated Control vs. Sit-to-Stand Desk"  then N2=13; If Label= "Baseline: Seated Control vs. Sit-to-Stand Desk" then LabelID=4; 
if Label= "Baseline: Seated Control vs. Treadmill Desk" then N1=13; if Label= "Baseline: Seated Control vs. Treadmill Desk" then N2=16; If Label= "Baseline: Seated Control vs. Treadmill Desk" then LabelID=5; 
if Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then N1=13; if Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then N2=16; If Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then LabelID=6; 

/*Intergroup Month 12*/ 
if Label= "Month-12: Seated Control vs. Sit-to-Stand Desk" then N1=13; if Label= "Month-12: Seated Control vs. Sit-to-Stand Desk"  then N2=13; If Label= "Month-12: Seated Control vs. Sit-to-Stand Desk" then LabelID=7; 
if Label= "Month-12: Seated Control vs. Treadmill Desk" then N1=13; if Label= "Month-12: Seated Control vs. Treadmill Desk" then N2=16; If Label= "Month-12: Seated Control vs. Treadmill Desk" then LabelID=8; 
if Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then N1=13; if Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then N2=16; If Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then LabelID=9; 
VAR= "UMA";
VARNAME="Mean_Daily_Sedentary_Hours"; 
Drop Parm Df Min Max Theta0 tValue; 
run; 
Quit; 

Proc sort data=MM_E.SAMPLEDATA_MM_E_MIAB_UMA ; by labelid; run; quit; 

Proc delete data=MM_E.SAMPLEDATA_MM_E_UMA ; run; quit;
Proc delete data=MM_E.SAMPLEDATA_MM_E_MIA_UMA ; run; quit; 


	/* Generate Pooled SD & Cohen's D Effect Sizes*/ 

/*Transpose SD From LSMeans File - Long to Wide Conversion*/ 
proc transpose data=MM_LSM.SAMPLEDATA_mm_lsm_miab_UMA  out=Trans.SampleData_lsm_UMA_Wide  prefix=CompGroup;
    id CompGroup;
    var STDEV;
run;
quit; 

/*proc contents data= Trans.SampleData_lsm_UMA_Wide  varnum; run; */ 

/*Generate SD1, SD2, PooledSD, and Cohen's D EE for Intra and InterGroup Comparisons*/ 
Data Trans.SampleData_lsm_UMA_Wide_WG ; 
Set Trans.SampleData_lsm_UMA_Wide ; 
do i=1 to 3; 
LabelID=i; 
drop i; 
output; 
End; 
run; 
quit; 

Data Trans.SampleData_lsm_UMA_Wide_WG2 ; 
Set Trans.SampleData_lsm_UMA_Wide_WG ; 
SD1=.; SD2=.;
/*"Control: Change Baseline to Month 12"*/
IF LabelID=1 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=1 then do;  SD2= CompGroupD__Seated_Control_Month;end; 
/*"Desk: Change Baseline to Month 12"*/
IF LabelID=2 then do; SD1= CompGroupB__Sit_to_Stand_Desk_Ba; end; 
	IF LabelID=2 then do;  SD2= CompGroupE__Sit_to_Stand_Desk_Mo;end; 
/*"Treadmill: Change Baseline to Month 12"*/
IF LabelID=3 then do; SD1= CompGroupC__Treadmill_Desk_Basel; end; 
	IF LabelID=3 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 

run;
quit; 

Data Trans.SampleData_lsm_UMA_Wide_WG3 ; 
Set Trans.SampleData_lsm_UMA_Wide_WG2 ; 
PooledSD = sqrt(((SD1**2)+(SD2**2))/2); 
VAR= "UMA";
Drop 
_NAME_
CompGroupA__Seated_Control_Basel
CompGroupB__Sit_to_Stand_Desk_Ba
CompGroupC__Treadmill_Desk_Basel
CompGroupD__Seated_Control_Month
CompGroupE__Sit_to_Stand_Desk_Mo
CompGroupF__Treadmill_Desk_Month
; 
run;
quit; 

Proc sort data =Trans.SampleData_lsm_UMA_Wide_WG3 ; by LabelID; run; quit; 


Data Trans.SampleData_lsm_UMA_Wide_BG ; 
Set Trans.SampleData_lsm_UMA_Wide ; 
do i=4 to 9; 
LabelID=i; 
drop i; 
output; 
End; 
run; 
quit; 

Data Trans.SampleData_lsm_UMA_Wide_BG2 ; 
Set Trans.SampleData_lsm_UMA_Wide_BG ; 
SD1=.; SD2=.; 
/*Baseline*/
/*"Baseline: Control vs. Desk"*/ 
IF LabelID=4 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=4 then do;  SD2= CompGroupB__Sit_to_Stand_Desk_Ba;end; 
/*"Baseline: Control vs. Treadmill"*/ 
IF LabelID=5 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=5 then do;  SD2= CompGroupC__Treadmill_Desk_Basel;end; 
/*"Baseline: Desk vs. Treadmill"*/ 
IF LabelID=6 then do; SD1= CompGroupB__Sit_to_Stand_Desk_Ba; end; 
	IF LabelID=6 then do;  SD2= CompGroupC__Treadmill_Desk_Basel;end; 

/*Month12*/ 
/*"Month 12: Control vs. Desk"*/ 
IF LabelID=7 then do; SD1= CompGroupD__Seated_Control_Month; end; 
	IF LabelID=7 then do;  SD2= CompGroupE__Sit_to_Stand_Desk_Mo;end; 
/*"Month 12: Control vs. Treadmill"*/ 
IF LabelID=8 then do; SD1= CompGroupD__Seated_Control_Month; end; 
	IF LabelID=8 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 
/*"Month 12: Desk vs. Treadmill"*/ 
IF LabelID=9 then do; SD1= CompGroupE__Sit_to_Stand_Desk_Mo; end; 
	IF LabelID=9 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 
run;
quit; 


Data Trans.SampleData_lsm_UMA_Wide_BG3 ; 
Set Trans.SampleData_lsm_UMA_Wide_BG2 ;
PooledSD = sqrt(((SD1**2)+(SD2**2))/2); 
VAR= "UMA";
Drop 
_NAME_
CompGroupA__Seated_Control_Basel
CompGroupB__Sit_to_Stand_Desk_Ba
CompGroupC__Treadmill_Desk_Basel
CompGroupD__Seated_Control_Month
CompGroupE__Sit_to_Stand_Desk_Mo
CompGroupF__Treadmill_Desk_Month
; 
run;
quit; 

Proc sort data = Trans.SampleData_lsm_UMA_Wide_BG3 ; by LabelID; run; 

Data MM_E.SAMPLEDATA_mm_e_mia_ES_UMA ; 
Merge 
MM_E.SAMPLEDATA_mm_e_miab_UMA  
Trans.SampleData_lsm_UMA_wide_wg3 
Trans.SampleData_lsm_UMA_wide_bg3 ;
; 
by LabelID;
CohensD_ES= abs(Estimate/PooledSD); 
; 
run; 
quit; 

Proc delete data=Trans.SampleData_lsm_UMA_wide ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMA_wide_bg ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMA_wide_bg2 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMA_wide_bg3 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMA_wide_wg ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMA_wide_wg2 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMA_wide_wg3 ; run; quit;
Proc delete data=MM_E.SAMPLEDATA_mm_e_miab_UMA ; run; quit; 


/* END Effect Size and Pooled SD Code **********************/ 

/* Part 2: Run Mixed Model for UMB=Standing*/ 

proc mixed data=M_UniIMP.sampledata_mi_UMB_long method=ml; 
format CompGroup CompGroup.;
class Participant_ID Cluster timepoint CompGroup Rand; 
by _Imputation_;
model Standing= CompGroup/ddfm=Kr; 
repeated timepoint/subject=Participant_ID type=UN; 
random intercept/subject=cluster;
LSmeans CompGroup / CL; 
/*Posthoc Comparisons*/ 
/* Within-Group Comparisons*/ 
Estimate "Seated Control: Change Baseline to Month 12" CompGroup -1 0 0 1 0 0/alpha= 0.0056; 
Estimate "Sit-to-Stand Desk: Change Baseline to Month 12" CompGroup 0 -1 0 0 1 0/alpha= 0.0056; 
Estimate "Treadmill Desk: Change Baseline to Month 12" CompGroup 0 0 -1 0 0 1/alpha= 0.0056;  
/*Between-Group Comparisons*/ 
	/*Baseline*/
Estimate "Baseline: Seated Control vs. Sit-to-Stand Desk" CompGroup -1 1 0 0 0 0/alpha= 0.0056;  
Estimate "Baseline: Seated Control vs. Treadmill Desk" CompGroup -1 0 1 0 0 0/alpha= 0.0056; 
Estimate "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" CompGroup 0 -1 1 0 0 0/alpha= 0.0056; 
	/*Month-12*/ 
Estimate "Month-12: Seated Control vs. Sit-to-Stand Desk" CompGroup 0 0 0 -1 1 0/alpha= 0.0056;  
Estimate "Month-12: Seated Control vs. Treadmill Desk" CompGroup 0 0 0 -1 0 1/alpha= 0.0056; 
Estimate "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" CompGroup 0 0 0 0 -1 1/alpha= 0.0056;  
/*Outputting Results*/  
/*ods select modelinfo LSMeans Estimates ;*/ 
ods output LSMeans= MM_LSM.SAMPLEDATA_MM_LSM_UMB  
		   Estimates= MM_E.SAMPLEDATA_MM_E_UMB ; 
run;
quit;  

/* Generate MI Analyzed LSMeans*/ 
proc sort data=MM_LSM.SAMPLEDATA_MM_LSM_UMB ; by CompGroup; run; 

Proc Mianalyze data=MM_LSM.SAMPLEDATA_MM_LSM_UMB ;  
Modeleffects estimate;
stderr StdErr; 
ods output ParameterEstimates= MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMB ; 
by CompGroup; 
run; 
quit;

Data MM_LSM.SAMPLEDATA_MM_LSM_MIAB_UMB ; 
set MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMB ; 
N=.; if CompGroup=1 then N=13; 
if CompGroup=2 then N=13; 
if CompGroup=3 then N=16; 
if CompGroup=4 then N=13; 
if CompGroup=5 then N=13; 
if CompGroup=6 then N=16; 
STDEV= StdErr*(sqrt(N)); 
VAR= "UMB";
VARNAME="Mean_Daily_Standing_Hours";
Drop Parm DF Min Max Theta0 tValue Probt; 
run; 
quit; 

proc delete data= MM_LSM.SAMPLEDATA_MM_LSM_UMB ; run; quit; 
proc delete data= MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMB ; run; quit; 

/*Generate MI Analyzed Estimates*/ 
proc sort data=MM_E.SAMPLEDATA_MM_E_UMB ; by Label; run;

Proc Mianalyze data=MM_E.SAMPLEDATA_MM_E_UMB ; 
Modeleffects estimate;
stderr StdErr; 
ods output ParameterEstimates= MM_E.SAMPLEDATA_MM_E_MIA_UMB ;
by Label; 
run; 
Quit; 

Data MM_E.SAMPLEDATA_MM_E_MIAB_UMB ; 
set MM_E.SAMPLEDATA_MM_E_MIA_UMB ; 
N1=.; N2=.; 
LabelID=.; 
/*Intragroup Baseline - Month12*/ 
if Label= "Seated Control: Change Baseline to Month 12" then N1=13; if Label= "Seated Control: Change Baseline to Month 12" then N2=13; if Label= "Seated Control: Change Baseline to Month 12"   then LabelID=1;
if Label= "Sit-to-Stand Desk: Change Baseline to Month 12" then N1=13; if Label= "Sit-to-Stand Desk: Change Baseline to Month 12" then N2=13; if Label= "Sit-to-Stand Desk: Change Baseline to Month 12"  then LabelID=2;
if Label= "Treadmill Desk: Change Baseline to Month 12" then N1=16; if Label= "Treadmill Desk: Change Baseline to Month 12" then N2=16; if Label= "Treadmill Desk: Change Baseline to Month 12"  then LabelID=3;
/*Intergroup Baseline*/ 
if Label= "Baseline: Seated Control vs. Sit-to-Stand Desk" then N1=13; if Label= "Baseline: Seated Control vs. Sit-to-Stand Desk"  then N2=13; If Label= "Baseline: Seated Control vs. Sit-to-Stand Desk" then LabelID=4; 
if Label= "Baseline: Seated Control vs. Treadmill Desk" then N1=13; if Label= "Baseline: Seated Control vs. Treadmill Desk" then N2=16; If Label= "Baseline: Seated Control vs. Treadmill Desk" then LabelID=5; 
if Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then N1=13; if Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then N2=16; If Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then LabelID=6; 

/*Intergroup Month 12*/ 
if Label= "Month-12: Seated Control vs. Sit-to-Stand Desk" then N1=13; if Label= "Month-12: Seated Control vs. Sit-to-Stand Desk"  then N2=13; If Label= "Month-12: Seated Control vs. Sit-to-Stand Desk" then LabelID=7; 
if Label= "Month-12: Seated Control vs. Treadmill Desk" then N1=13; if Label= "Month-12: Seated Control vs. Treadmill Desk" then N2=16; If Label= "Month-12: Seated Control vs. Treadmill Desk" then LabelID=8; 
if Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then N1=13; if Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then N2=16; If Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then LabelID=9; 
VAR= "UMB";
VARNAME="Mean_Daily_Standing_Hours"; 
Drop Parm Df Min Max Theta0 tValue; 
run; 
Quit; 

Proc sort data=MM_E.SAMPLEDATA_MM_E_MIAB_UMB ; by labelid; run; quit; 

Proc delete data=MM_E.SAMPLEDATA_MM_E_UMB ; run; quit;
Proc delete data=MM_E.SAMPLEDATA_MM_E_MIA_UMB ; run; quit; 


	/* Generate Pooled SD & Cohen's D Effect Sizes*/ 

/*Transpose SD From LSMeans File - Long to Wide Conversion*/ 
proc transpose data=MM_LSM.SAMPLEDATA_mm_lsm_miab_UMB  out=Trans.SampleData_lsm_UMB_Wide  prefix=CompGroup;
    id CompGroup;
    var STDEV;
run;
quit; 

/*proc contents data= Trans.SampleData_lsm_UMB_Wide  varnum; run; */ 

/*Generate SD1, SD2, PooledSD, and Cohen's D EE for Intra and InterGroup Comparisons*/ 
Data Trans.SampleData_lsm_UMB_Wide_WG ; 
Set Trans.SampleData_lsm_UMB_Wide ; 
do i=1 to 3; 
LabelID=i; 
drop i; 
output; 
End; 
run; 
quit; 

Data Trans.SampleData_lsm_UMB_Wide_WG2 ; 
Set Trans.SampleData_lsm_UMB_Wide_WG ; 
SD1=.; SD2=.;
/*"Control: Change Baseline to Month 12"*/
IF LabelID=1 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=1 then do;  SD2= CompGroupD__Seated_Control_Month;end; 
/*"Desk: Change Baseline to Month 12"*/
IF LabelID=2 then do; SD1= CompGroupB__Sit_to_Stand_Desk_Ba; end; 
	IF LabelID=2 then do;  SD2= CompGroupE__Sit_to_Stand_Desk_Mo;end; 
/*"Treadmill: Change Baseline to Month 12"*/
IF LabelID=3 then do; SD1= CompGroupC__Treadmill_Desk_Basel; end; 
	IF LabelID=3 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 

run;
quit; 

Data Trans.SampleData_lsm_UMB_Wide_WG3 ; 
Set Trans.SampleData_lsm_UMB_Wide_WG2 ; 
PooledSD = sqrt(((SD1**2)+(SD2**2))/2); 
VAR= "UMB";
Drop 
_NAME_
CompGroupA__Seated_Control_Basel
CompGroupB__Sit_to_Stand_Desk_Ba
CompGroupC__Treadmill_Desk_Basel
CompGroupD__Seated_Control_Month
CompGroupE__Sit_to_Stand_Desk_Mo
CompGroupF__Treadmill_Desk_Month
; 
run;
quit; 

Proc sort data =Trans.SampleData_lsm_UMB_Wide_WG3 ; by LabelID; run; quit; 


Data Trans.SampleData_lsm_UMB_Wide_BG ; 
Set Trans.SampleData_lsm_UMB_Wide ; 
do i=4 to 9; 
LabelID=i; 
drop i; 
output; 
End; 
run; 
quit; 

Data Trans.SampleData_lsm_UMB_Wide_BG2 ; 
Set Trans.SampleData_lsm_UMB_Wide_BG ; 
SD1=.; SD2=.; 
/*Baseline*/
/*"Baseline: Control vs. Desk"*/ 
IF LabelID=4 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=4 then do;  SD2= CompGroupB__Sit_to_Stand_Desk_Ba;end; 
/*"Baseline: Control vs. Treadmill"*/ 
IF LabelID=5 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=5 then do;  SD2= CompGroupC__Treadmill_Desk_Basel;end; 
/*"Baseline: Desk vs. Treadmill"*/ 
IF LabelID=6 then do; SD1= CompGroupB__Sit_to_Stand_Desk_Ba; end; 
	IF LabelID=6 then do;  SD2= CompGroupC__Treadmill_Desk_Basel;end; 

/*Month12*/ 
/*"Month 12: Control vs. Desk"*/ 
IF LabelID=7 then do; SD1= CompGroupD__Seated_Control_Month; end; 
	IF LabelID=7 then do;  SD2= CompGroupE__Sit_to_Stand_Desk_Mo;end; 
/*"Month 12: Control vs. Treadmill"*/ 
IF LabelID=8 then do; SD1= CompGroupD__Seated_Control_Month; end; 
	IF LabelID=8 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 
/*"Month 12: Desk vs. Treadmill"*/ 
IF LabelID=9 then do; SD1= CompGroupE__Sit_to_Stand_Desk_Mo; end; 
	IF LabelID=9 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 
run;
quit; 


Data Trans.SampleData_lsm_UMB_Wide_BG3 ; 
Set Trans.SampleData_lsm_UMB_Wide_BG2 ;
PooledSD = sqrt(((SD1**2)+(SD2**2))/2); 
VAR= "UMB";
Drop 
_NAME_
CompGroupA__Seated_Control_Basel
CompGroupB__Sit_to_Stand_Desk_Ba
CompGroupC__Treadmill_Desk_Basel
CompGroupD__Seated_Control_Month
CompGroupE__Sit_to_Stand_Desk_Mo
CompGroupF__Treadmill_Desk_Month
; 
run;
quit; 

Proc sort data = Trans.SampleData_lsm_UMB_Wide_BG3 ; by LabelID; run; 

Data MM_E.SAMPLEDATA_mm_e_mia_ES_UMB ; 
Merge 
MM_E.SAMPLEDATA_mm_e_miab_UMB  
Trans.SampleData_lsm_UMB_wide_wg3 
Trans.SampleData_lsm_UMB_wide_bg3 ;
; 
by LabelID;
CohensD_ES= abs(Estimate/PooledSD); 
; 
run; 
quit; 

Proc delete data=Trans.SampleData_lsm_UMB_wide ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMB_wide_bg ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMB_wide_bg2 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMB_wide_bg3 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMB_wide_wg ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMB_wide_wg2 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMB_wide_wg3 ; run; quit;
Proc delete data=MM_E.SAMPLEDATA_mm_e_miab_UMB ; run; quit; 


/* END Effect Size and Pooled SD Code **********************/

/* Part 3: Run Mixed Model for UMC=Stepping*/ 

proc mixed data=M_UniIMP.sampledata_mi_UMC_long method=ml; 
format CompGroup CompGroup.;
class Participant_ID Cluster timepoint CompGroup Rand; 
by _Imputation_;
model Stepping= CompGroup/ddfm=Kr; 
repeated timepoint/subject=Participant_ID type=UN; 
random intercept/subject=cluster;
LSmeans CompGroup / CL; 
/*Posthoc Comparisons*/ 
/* Within-Group Comparisons*/ 
Estimate "Seated Control: Change Baseline to Month 12" CompGroup -1 0 0 1 0 0/alpha= 0.0056; 
Estimate "Sit-to-Stand Desk: Change Baseline to Month 12" CompGroup 0 -1 0 0 1 0/alpha= 0.0056; 
Estimate "Treadmill Desk: Change Baseline to Month 12" CompGroup 0 0 -1 0 0 1/alpha= 0.0056;  
/*Between-Group Comparisons*/ 
	/*Baseline*/
Estimate "Baseline: Seated Control vs. Sit-to-Stand Desk" CompGroup -1 1 0 0 0 0/alpha= 0.0056;  
Estimate "Baseline: Seated Control vs. Treadmill Desk" CompGroup -1 0 1 0 0 0/alpha= 0.0056; 
Estimate "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" CompGroup 0 -1 1 0 0 0/alpha= 0.0056; 
	/*Month-12*/ 
Estimate "Month-12: Seated Control vs. Sit-to-Stand Desk" CompGroup 0 0 0 -1 1 0/alpha= 0.0056;  
Estimate "Month-12: Seated Control vs. Treadmill Desk" CompGroup 0 0 0 -1 0 1/alpha= 0.0056; 
Estimate "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" CompGroup 0 0 0 0 -1 1/alpha= 0.0056;  
/*Outputting Results*/  
/*ods select modelinfo LSMeans Estimates ;*/ 
ods output LSMeans= MM_LSM.SAMPLEDATA_MM_LSM_UMC  
		   Estimates= MM_E.SAMPLEDATA_MM_E_UMC ; 
run;
quit;  

/* Generate MI Analyzed LSMeans*/ 
proc sort data=MM_LSM.SAMPLEDATA_MM_LSM_UMC ; by CompGroup; run; 

Proc Mianalyze data=MM_LSM.SAMPLEDATA_MM_LSM_UMC ;  
Modeleffects estimate;
stderr StdErr; 
ods output ParameterEstimates= MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMC ; 
by CompGroup; 
run; 
quit;

Data MM_LSM.SAMPLEDATA_MM_LSM_MIAB_UMC ; 
set MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMC ; 
N=.; if CompGroup=1 then N=13; 
if CompGroup=2 then N=13; 
if CompGroup=3 then N=16; 
if CompGroup=4 then N=13; 
if CompGroup=5 then N=13; 
if CompGroup=6 then N=16; 
STDEV= StdErr*(sqrt(N)); 
VAR= "UMC";
VARNAME="Mean_Daily_Stepping_Hours";
Drop Parm DF Min Max Theta0 tValue Probt; 
run; 
quit; 

proc delete data= MM_LSM.SAMPLEDATA_MM_LSM_UMC ; run; quit; 
proc delete data= MM_LSM.SAMPLEDATA_MM_LSM_MIA_UMC ; run; quit; 

/*Generate MI Analyzed Estimates*/ 
proc sort data=MM_E.SAMPLEDATA_MM_E_UMC ; by Label; run;

Proc Mianalyze data=MM_E.SAMPLEDATA_MM_E_UMC ; 
Modeleffects estimate;
stderr StdErr; 
ods output ParameterEstimates= MM_E.SAMPLEDATA_MM_E_MIA_UMC ;
by Label; 
run; 
Quit; 

Data MM_E.SAMPLEDATA_MM_E_MIAB_UMC ; 
set MM_E.SAMPLEDATA_MM_E_MIA_UMC ; 
N1=.; N2=.; 
LabelID=.; 
/*Intragroup Baseline - Month12*/ 
if Label= "Seated Control: Change Baseline to Month 12" then N1=13; if Label= "Seated Control: Change Baseline to Month 12" then N2=13; if Label= "Seated Control: Change Baseline to Month 12"   then LabelID=1;
if Label= "Sit-to-Stand Desk: Change Baseline to Month 12" then N1=13; if Label= "Sit-to-Stand Desk: Change Baseline to Month 12" then N2=13; if Label= "Sit-to-Stand Desk: Change Baseline to Month 12"  then LabelID=2;
if Label= "Treadmill Desk: Change Baseline to Month 12" then N1=16; if Label= "Treadmill Desk: Change Baseline to Month 12" then N2=16; if Label= "Treadmill Desk: Change Baseline to Month 12"  then LabelID=3;
/*Intergroup Baseline*/ 
if Label= "Baseline: Seated Control vs. Sit-to-Stand Desk" then N1=13; if Label= "Baseline: Seated Control vs. Sit-to-Stand Desk"  then N2=13; If Label= "Baseline: Seated Control vs. Sit-to-Stand Desk" then LabelID=4; 
if Label= "Baseline: Seated Control vs. Treadmill Desk" then N1=13; if Label= "Baseline: Seated Control vs. Treadmill Desk" then N2=16; If Label= "Baseline: Seated Control vs. Treadmill Desk" then LabelID=5; 
if Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then N1=13; if Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then N2=16; If Label= "Baseline: Sit-to-Stand Desk vs. Treadmill Desk" then LabelID=6; 

/*Intergroup Month 12*/ 
if Label= "Month-12: Seated Control vs. Sit-to-Stand Desk" then N1=13; if Label= "Month-12: Seated Control vs. Sit-to-Stand Desk"  then N2=13; If Label= "Month-12: Seated Control vs. Sit-to-Stand Desk" then LabelID=7; 
if Label= "Month-12: Seated Control vs. Treadmill Desk" then N1=13; if Label= "Month-12: Seated Control vs. Treadmill Desk" then N2=16; If Label= "Month-12: Seated Control vs. Treadmill Desk" then LabelID=8; 
if Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then N1=13; if Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then N2=16; If Label= "Month-12: Sit-to-Stand Desk vs. Treadmill Desk" then LabelID=9; 
VAR= "UMC";
VARNAME="Mean_Daily_Stepping_Hours"; 
Drop Parm Df Min Max Theta0 tValue; 
run; 
Quit; 

Proc sort data=MM_E.SAMPLEDATA_MM_E_MIAB_UMC ; by labelid; run; quit; 

Proc delete data=MM_E.SAMPLEDATA_MM_E_UMC ; run; quit;
Proc delete data=MM_E.SAMPLEDATA_MM_E_MIA_UMC ; run; quit; 


	/* Generate Pooled SD & Cohen's D Effect Sizes*/ 

/*Transpose SD From LSMeans File - Long to Wide Conversion*/ 
proc transpose data=MM_LSM.SAMPLEDATA_mm_lsm_miab_UMC  out=Trans.SampleData_lsm_UMC_Wide  prefix=CompGroup;
    id CompGroup;
    var STDEV;
run;
quit; 

/*proc contents data= Trans.SampleData_lsm_UMC_Wide  varnum; run; */ 

/*Generate SD1, SD2, PooledSD, and Cohen's D EE for Intra and InterGroup Comparisons*/ 
Data Trans.SampleData_lsm_UMC_Wide_WG ; 
Set Trans.SampleData_lsm_UMC_Wide ; 
do i=1 to 3; 
LabelID=i; 
drop i; 
output; 
End; 
run; 
quit; 

Data Trans.SampleData_lsm_UMC_Wide_WG2 ; 
Set Trans.SampleData_lsm_UMC_Wide_WG ; 
SD1=.; SD2=.;
/*"Control: Change Baseline to Month 12"*/
IF LabelID=1 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=1 then do;  SD2= CompGroupD__Seated_Control_Month;end; 
/*"Desk: Change Baseline to Month 12"*/
IF LabelID=2 then do; SD1= CompGroupB__Sit_to_Stand_Desk_Ba; end; 
	IF LabelID=2 then do;  SD2= CompGroupE__Sit_to_Stand_Desk_Mo;end; 
/*"Treadmill: Change Baseline to Month 12"*/
IF LabelID=3 then do; SD1= CompGroupC__Treadmill_Desk_Basel; end; 
	IF LabelID=3 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 

run;
quit; 

Data Trans.SampleData_lsm_UMC_Wide_WG3 ; 
Set Trans.SampleData_lsm_UMC_Wide_WG2 ; 
PooledSD = sqrt(((SD1**2)+(SD2**2))/2); 
VAR= "UMC";
Drop 
_NAME_
CompGroupA__Seated_Control_Basel
CompGroupB__Sit_to_Stand_Desk_Ba
CompGroupC__Treadmill_Desk_Basel
CompGroupD__Seated_Control_Month
CompGroupE__Sit_to_Stand_Desk_Mo
CompGroupF__Treadmill_Desk_Month
; 
run;
quit; 

Proc sort data =Trans.SampleData_lsm_UMC_Wide_WG3 ; by LabelID; run; quit; 


Data Trans.SampleData_lsm_UMC_Wide_BG ; 
Set Trans.SampleData_lsm_UMC_Wide ; 
do i=4 to 9; 
LabelID=i; 
drop i; 
output; 
End; 
run; 
quit; 

Data Trans.SampleData_lsm_UMC_Wide_BG2 ; 
Set Trans.SampleData_lsm_UMC_Wide_BG ; 
SD1=.; SD2=.; 
/*Baseline*/
/*"Baseline: Control vs. Desk"*/ 
IF LabelID=4 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=4 then do;  SD2= CompGroupB__Sit_to_Stand_Desk_Ba;end; 
/*"Baseline: Control vs. Treadmill"*/ 
IF LabelID=5 then do; SD1= CompGroupA__Seated_Control_Basel; end; 
	IF LabelID=5 then do;  SD2= CompGroupC__Treadmill_Desk_Basel;end; 
/*"Baseline: Desk vs. Treadmill"*/ 
IF LabelID=6 then do; SD1= CompGroupB__Sit_to_Stand_Desk_Ba; end; 
	IF LabelID=6 then do;  SD2= CompGroupC__Treadmill_Desk_Basel;end; 

/*Month12*/ 
/*"Month 12: Control vs. Desk"*/ 
IF LabelID=7 then do; SD1= CompGroupD__Seated_Control_Month; end; 
	IF LabelID=7 then do;  SD2= CompGroupE__Sit_to_Stand_Desk_Mo;end; 
/*"Month 12: Control vs. Treadmill"*/ 
IF LabelID=8 then do; SD1= CompGroupD__Seated_Control_Month; end; 
	IF LabelID=8 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 
/*"Month 12: Desk vs. Treadmill"*/ 
IF LabelID=9 then do; SD1= CompGroupE__Sit_to_Stand_Desk_Mo; end; 
	IF LabelID=9 then do;  SD2= CompGroupF__Treadmill_Desk_Month;end; 
run;
quit; 


Data Trans.SampleData_lsm_UMC_Wide_BG3 ; 
Set Trans.SampleData_lsm_UMC_Wide_BG2 ;
PooledSD = sqrt(((SD1**2)+(SD2**2))/2); 
VAR= "UMC";
Drop 
_NAME_
CompGroupA__Seated_Control_Basel
CompGroupB__Sit_to_Stand_Desk_Ba
CompGroupC__Treadmill_Desk_Basel
CompGroupD__Seated_Control_Month
CompGroupE__Sit_to_Stand_Desk_Mo
CompGroupF__Treadmill_Desk_Month
; 
run;
quit; 

Proc sort data = Trans.SampleData_lsm_UMC_Wide_BG3 ; by LabelID; run; 

Data MM_E.SAMPLEDATA_mm_e_mia_ES_UMC ; 
Merge 
MM_E.SAMPLEDATA_mm_e_miab_UMC  
Trans.SampleData_lsm_UMC_wide_wg3 
Trans.SampleData_lsm_UMC_wide_bg3 ;
; 
by LabelID;
CohensD_ES= abs(Estimate/PooledSD); 
; 
run; 
quit; 

Proc delete data=Trans.SampleData_lsm_UMC_wide ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMC_wide_bg ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMC_wide_bg2 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMC_wide_bg3 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMC_wide_wg ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMC_wide_wg2 ; run; quit;
Proc delete data=Trans.SampleData_lsm_UMC_wide_wg3 ; run; quit;
Proc delete data=MM_E.SAMPLEDATA_mm_e_miab_UMC ; run; quit; 


/* END Effect Size and Pooled SD Code **********************/

%mend;


/*Run Code*/
%MM; 
ODS exclude none;


/*Export Results to Excel*/ 
Libname MM_EE "C:\Users\diego\Documents\SampleImputation\MixedModels\ExcelExports"; 


/*Export Mixed Model Maximum Likelihood Estimates by Comparison Groups*/ 
proc export data=MM_LSM.SAMPLEDATA_MM_LSM_MIAB_UMA dbms=xlsx
outfile="C:\Users\diego\Documents\SampleImputation\MixedModels\ExcelExports\sampledata_mm_lsm_miab_uma.xlsx"
replace;
run;

proc export data=MM_LSM.SAMPLEDATA_MM_LSM_MIAB_UMB dbms=xlsx
outfile="C:\Users\diego\Documents\SampleImputation\MixedModels\ExcelExports\sampledata_mm_lsm_miab_umb.xlsx"
replace;
run;

proc export data=MM_LSM.SAMPLEDATA_MM_LSM_MIAB_UMC dbms=xlsx
outfile="C:\Users\diego\Documents\SampleImputation\MixedModels\ExcelExports\sampledata_mm_lsm_miab_umc.xlsx"
replace;
run;

/*Export Mixed Model Post Hoc Effects*/
proc export data=MM_E.SAMPLEDATA_mm_e_mia_ES_UMA dbms=xlsx
outfile="C:\Users\diego\Documents\SampleImputation\MixedModels\ExcelExports\SAMPLEDATA_mm_e_mia_ES_UMA.xlsx"
replace;
run;

proc export data=MM_E.SAMPLEDATA_mm_e_mia_ES_UMB dbms=xlsx
outfile="C:\Users\diego\Documents\SampleImputation\MixedModels\ExcelExports\SAMPLEDATA_mm_e_mia_ES_UMB.xlsx"
replace;
run;

proc export data=MM_E.SAMPLEDATA_mm_e_mia_ES_UMC dbms=xlsx
outfile="C:\Users\diego\Documents\SampleImputation\MixedModels\ExcelExports\SAMPLEDATA_mm_e_mia_ES_UMC.xlsx"
replace;
run;
