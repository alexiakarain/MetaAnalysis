* Import all data
import excel "path/raw_data/dataset.xlsx", first row clear

* Log-transform the effect size and confidence intervals
generate log_ES = ln(effect_size)
generate log_lower_CI = ln(lower_CI)
generate log_upper_CI = ln(upper_CI)

* Calculate the standard error (SE) from the log-transformed CIs
generate logSE = (log_upper_CI - log_lower_CI) / (2 * 1.96)

* Drop invalid rows
drop if log_ES == 0

* Label variables
label var study_id "Study ID"
label var log_ES "Log Effect Size (Log RR)"
label var logSE "Log Standard Error"

label define yesno 0 "no" 1 "yes"
label values polytherapy yesno

label var polytherapy "Polytherapy Status"
label var study_type "Study Design"
label var exposure "AED Type"

* Encode categorical variables
gen STUDY = .
replace STUDY = 1 if study_type == "case-control"
replace STUDY = 2 if study_type == "cohort"

label define study 1 "case-control" 2 "cohort"
label values STUDY study

gen AED_type=.
replace AED_type = 1 if exposure == "any AED(s)"
replace AED_type= 2 if exposure== "VPA"
replace AED_type= 3 if exposure == "CBZ"
replace AED_type= 4 if exposure == "PHB"
replace AED_type= 5 if exposure == "PH"
replace AED_type= 6 if exposure == "Other"

label define aedlabels 1 "any AED(s)" 2 "Sodium Valproate" 3 "Carbamazepine" 4 "Phenobarbital" 5 "Phenytoin" 6 "Other"
label values AED_type aedlabels

********************************************************************************
*** Meta-Analysis ***
********************************************************************************

* Declare the data for meta-analysis using log-transformed effect sizes
meta set log_ES logSE, studylabel(study_id)

* Summary
meta summarize, leaveoneout

* Forest Plot by AED Type
meta forestplot, random subgroup(AED_type) eform

meta funnelplot

* Forest Plot by Polytherapy Status
preserve
keep if AED_type == 1
meta forestplot, random subgroup(polytherapy) eform
restore

meta funnelplot

* Forest Plot by Study Design
preserve
drop if study_id == "Adab et al. 2004" & AED_type == 1 & polytherapy==0
keep if AED_type == 1
meta forestplot, random subgroup(STUDY) eform
restore

meta funnelplot

********************************************************************************
*** Meta-Regression ***
********************************************************************************

* Meta-regression with Polytherapy Status
meta regress polytherapy, random(dlaird)

* Meta-regression with Polytherapy Status, Study Design, and AED Type
meta regress polytherapy STUDY AED, random(dlaird)

********************************************************************************
*** Save Data ***
********************************************************************************

save "C:\Users\alexi\OneDrive\Υπολογιστής\Systematic Review\Meta-analysis\final_meta_data.dta", replace