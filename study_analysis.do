```stata
/**************************************************************************
* Participant characteristics and descriptive analyses
*
* ANONYMISED VERSION FOR EXTERNAL SHARING
*
* This do-file requires access to the study datasets and any user-written
* Stata commands specified below. Local file paths should be set by the
* user before running.
*
* Author: Jeevitha Mariapun
*
* NOTE: Dataset files themselves are not included with this code.
**************************************************************************/

version 17.0
clear all
set more off


/**************************************************************************
* 1. USER-DEFINED FILE PATHS
*
* Update these paths locally. Do not include institutional usernames,
* network locations, or other identifying information in a shared version.
**************************************************************************/

* Root directory containing the required datasets
local datadir "[DATA_DIRECTORY]"

* Optional directory containing user-written Stata programs/packages
local codedir "[CODE_DIRECTORY]"


/**************************************************************************
* 2. MERGE DATASETS
*
* The analysis dataset was constructed from the relevant study datasets.
* Update filenames/path structure as appropriate for the shared environment.
**************************************************************************/

* Example:
* use "`datadir'/[MAIN_DATASET].dta", clear

* Merge parent information
* merge [MERGE_TYPE] [ID_VARIABLE] using "`datadir'/[PARENT_DATASET].dta"
* rename _merge _mergeparents

* Merge blood results
* merge [MERGE_TYPE] [ID_VARIABLE] using "`datadir'/[BLOOD_DATASET].dta"

* Review merge status
* tab _mergeparents
* bysort _mergeparents: tab _merge

* Review availability of parent identifiers
* tab motherid if _mergeparents == 3
* tab motherid if _mergeparents == 3 & _merge == 3
* tab fatherid if _mergeparents == 3
* tab fatherid if _mergeparents == 3 & _merge == 3


/**************************************************************************
* 3. PARENT/SIBLING IDENTIFIER CHECKS
**************************************************************************/

capture drop mfboth

tab motherid
tab fatherid

duplicates report motherid
duplicates report fatherid
duplicates report barcode

* Check the number of observations with identifiers for both parents.
gen byte mfboth = !missing(motherid) & !missing(fatherid)

tab mfboth
tab mfboth if _mergeparents == 3
tab mfboth if _mergeparents == 3 & _merge == 3


/**************************************************************************
* 4. MISSING DATA
**************************************************************************/

capture noisily mdesc
misstable summarize


/**************************************************************************
* 5. BLOOD PRESSURE AND HEART RATE CLEANING
*
* Implausible measurements are set to missing according to the
* prespecified lower thresholds used in the original analysis.
**************************************************************************/

* Systolic blood pressure
forvalues i = 1/3 {
    gen sbp`i' = bp_5_`i'
}

replace sbp1 = . if sbp1 < 77
replace sbp2 = . if sbp2 < 69
replace sbp3 = . if sbp3 < 67

* Diastolic blood pressure
forvalues i = 1/3 {
    gen dbp`i' = bp_6_`i'
}

replace dbp1 = . if dbp1 < 46
replace dbp2 = . if dbp2 < 38
replace dbp3 = . if dbp3 < 40

* Heart rate
forvalues i = 1/3 {
    gen hr`i' = bp_7_`i'
}

replace hr1 = . if hr1 < 40
replace hr2 = . if hr2 < 51
replace hr3 = . if hr3 < 51

* Mean of second and third measurements
capture drop sbpavg dbpavg
egen sbpavg = rowmean(sbp2 sbp3)
egen dbpavg = rowmean(dbp2 dbp3)

summarize sbpavg dbpavg, detail


/**************************************************************************
* 6. READ ANALYSIS DATASET
**************************************************************************/

use "`datadir'/[ANALYSIS_DATASET].dta", clear

count
describe


/**************************************************************************
* 7. RESPONDENT STATUS
**************************************************************************/

capture label drop respondentstatus_lab
label define respondentstatus_lab ///
    1 "agree" ///
    2 "reject" ///
    3 "uncontactable" ///
    4 "empty/moved" ///
    5 "passed away" ///
    6 "exclude"

label values respondent_status respondentstatus_lab

tab respondent_status

* Retain participants who agreed to participate.
keep if respondent_status == 1


/**************************************************************************
* 8. VARIABLE LABELS
**************************************************************************/

label variable age_2018        "Child age in 2018"
label variable bmi_2018        "Child BMI in 2018"
label variable zbmi_2018       "Child BMI z-score in 2018"
label variable bmicat_2018     "Child BMI category in 2018"
label variable hoh_educ_2018   "Education of head of household (2018)"
label variable hoh_employ_2018 "Employment status of head of household (2018)"
label variable hh_educ_2018    "Highest education in household (2018)"

label variable respondent_sex "Sex"

capture label drop sex_lab
label define sex_lab ///
    -9 "Refused to answer" ///
    1 "Male" ///
    2 "Female"

label values respondent_sex sex_lab


/**************************************************************************
* 9. AGE GROUP
**************************************************************************/

summarize age_dob, detail
tabulate age_dob

capture drop agegroup
recode age_dob ///
    (min/12 = 1) ///
    (13/max = 2), ///
    generate(agegroup)

label variable agegroup "Age group"

capture label drop age_lab
label define age_lab ///
    1 "Under 13 years" ///
    2 "13 years or older"

label values agegroup age_lab

tabulate agegroup
bysort respondent_sex: tabulate agegroup


/**************************************************************************
* 10. HOUSEHOLD EDUCATION
**************************************************************************/

tabulate hh_educ_2018

capture drop hh_educ_2018_twogroups
recode hh_educ_2018 ///
    (1 2 = 1) ///
    (3 = 2), ///
    generate(hh_educ_2018_twogroups)

label variable hh_educ_2018_twogroups ///
    "Highest education in household (2018) - two groups"

capture label drop hh_lab
label define hh_lab ///
    1 "Up to secondary" ///
    2 "Tertiary"

label values hh_educ_2018_twogroups hh_lab

tabulate hh_educ_2018_twogroups


/**************************************************************************
* 11. HOUSEHOLD INCOME
**************************************************************************/

tabulate income_6

capture drop income_6_continuous
recode income_6 ///
    (-9 -8 = .) ///
    (1 = 500) ///
    (2 = 1500) ///
    (3 = 2500) ///
    (4 = 3500) ///
    (5 = 4500) ///
    (6 = 5500) ///
    (7 = 7000), ///
    generate(income_6_continuous)

label variable income_6_continuous ///
    "Household monthly income - continuous"

tabulate income_6_continuous, missing
summarize income_6_continuous

capture drop income_6_twogroups
recode income_6_continuous ///
    (min/1999 = 1) ///
    (2000/max = 2), ///
    generate(income_6_twogroups)

label variable income_6_twogroups ///
    "Household monthly income - two groups"

capture label drop income_lab
label define income_lab ///
    1 "<2000" ///
    2 ">=2000"

label values income_6_twogroups income_lab

tabulate income_6_twogroups


/**************************************************************************
* 12. ETHNICITY
**************************************************************************/

label variable respondent_ethnicity "Ethnicity group"

capture label drop ethnicity_lab
label define ethnicity_lab ///
    1 "Group 1" ///
    2 "Group 2" ///
    3 "Group 3" ///
    5 "Other" ///
    8 "Group 4" ///
    -8 "Don't know" ///
    -9 "Refused to answer"

label values respondent_ethnicity ethnicity_lab

tabulate respondent_ethnicity


/**************************************************************************
* 13. ANTHROPOMETRIC MEASURES
**************************************************************************/

label variable hw_4  "Height (cm)"
label variable hw_6  "Weight (kg)"
label variable hw_9  "Waist circumference (cm)"
label variable bmical "BMI"

summarize hw_4 hw_6


/**************************************************************************
* 14. BMI Z-SCORE AND BMI CATEGORIES
*
* Requires the user-written zanthro command.
* Install separately if required:
*
*     ssc install zanthro
*
* The analysis-specific reference data/package should be obtained from
* the appropriate source rather than relying on an institutional path.
**************************************************************************/

capture which zanthro
if _rc {
    di as error "The user-written command 'zanthro' is required."
    di as error "Install it before running this section."
    exit 199
}

capture drop zbmi
egen zbmi = zanthro( ///
    bmical, ///
    ba, ///
    WHO ///
), xvar(age_dob) ///
  gender(respondent_sex) ///
  gencode(male=1, female=2)

capture drop bmicat
egen bmicat = cut(zbmi), at(-10,-2,1,2,10) icodes

capture label drop bmilab
label define bmilab ///
    0 "Underweight" ///
    1 "Healthy weight" ///
    2 "Overweight" ///
    3 "Obese"

label values bmicat bmilab

label variable bmicat "BMI category"
label variable zbmi "BMI z-score"

tabulate bmicat
summarize zbmi


/**************************************************************************
* 15. CHANGE IN BMI Z-SCORE
**************************************************************************/

capture drop zbmi_change
generate zbmi_change = zbmi - zbmi_2018

label variable zbmi_change "Change in BMI z-score"

summarize zbmi_change


/**************************************************************************
* 16. INCIDENT OBESITY
**************************************************************************/

* Review BMI category at follow-up among participants who were not obese
* at baseline.

tabulate bmicat if bmicat_2018 != 3


/**************************************************************************
* 17. SIBLING DATA
**************************************************************************/

capture matrix drop siblings

tabulate barcodehouse, matcell(siblings)
matrix list siblings

capture drop siblings1
svmat siblings

tabulate siblings1


/**************************************************************************
* 18. REGRESSION ANALYSES
**************************************************************************/

/*
Model 2:
Physical activity/sleep variables entered as continuous measures.

Outcomes:
    - BMI z-score
    - Waist circumference
    - Systolic blood pressure
    - Diastolic blood pressure
    - Total cholesterol
    - HDL
    - LDL
    - Triglycerides
    - Glucose
*/

local outcomes ///
    zbmi2 ///
    hw_9 ///
    sbpavg ///
    dbpavg ///
    TotalCholesterol ///
    HDL ///
    LDL ///
    Triglycerides ///
    Glucose

local covariates ///
    age_dob ///
    respondent_sex ///
    height ///
    i.tanner ///
    ib1.ethnicity ///
    ib3.hh_educ_2018

local activity_cont ///
    adjavg_light_mins_all ///
    adjavg_mvpa_mins_all ///
    adjavg_sleep_mins_all

foreach outcome of local outcomes {

    di as text "--------------------------------------------------"
    di as text "Outcome: `outcome'"
    di as text "--------------------------------------------------"

    regress `outcome' ///
        `activity_cont' ///
        `covariates', ///
        vce(cluster barcode_numeric)

    vif
    estat ic
    linktest
}


/**************************************************************************
* 19. DESCRIPTIVE STATISTICS FOR ACTIVITY AND SLEEP
**************************************************************************/

local activity_vars ///
    adjavg_inact_mins_all ///
    adjavg_light_mins_all ///
    adjavg_vig_mins_all ///
    adjavg_mvpa_mins_all ///
    adjavg_sleep_mins_all

foreach var of local activity_vars {
    summarize `var', detail
}

foreach var of local activity_vars {
    bysort respondent_sex: summarize `var', detail
}


/**************************************************************************
* 20. MODEL 3: MEETING MVPA RECOMMENDATION (removed)
*
* MVPA entered as a categorical variable.
**************************************************************************/

local outcomes ///
    zbmi2 ///
    hw_9 ///
    sbpavg ///
    dbpavg ///
    TotalCholesterol ///
    HDL ///
    LDL ///
    Triglycerides ///
    Glucose

foreach outcome of local outcomes {

    di as text "--------------------------------------------------"
    di as text "Outcome: `outcome'"
    di as text "MVPA categorical model"
    di as text "--------------------------------------------------"

    regress `outcome' ///
        i.adjmvpa ///
        adjavg_light_mins_all ///
        adjavg_sleep_mins_all ///
        `covariates', ///
        vce(cluster barcode_numeric)

    vif
    estat ic
    linktest
}


/**************************************************************************
* 21. STANDARDISED COEFFICIENTS
**************************************************************************/

foreach outcome of local outcomes {

    di as text "--------------------------------------------------"
    di as text "Outcome: `outcome'"
    di as text "Standardised coefficient model"
    di as text "--------------------------------------------------"

    regress `outcome' ///
        i.adjmvpa ///
        adjavg_light_mins_all ///
        adjavg_sleep_mins_all ///
        `covariates', ///
        vce(robust) beta
}


/**************************************************************************
* 22. CONTINUOUS ACTIVITY MODEL WITH STANDARDISED COEFFICIENTS
**************************************************************************/

foreach outcome of local outcomes {

    di as text "--------------------------------------------------"
    di as text "Outcome: `outcome'"
    di as text "Continuous activity model - standardised coefficients"
    di as text "--------------------------------------------------"

    regress `outcome' ///
        adjavg_light_mins_all ///
        adjavg_mvpa_mins_all ///
        adjavg_sleep_mins_all ///
        `covariates', ///
        vce(robust) beta
}


/**************************************************************************
* END OF DO-FILE
**************************************************************************/
```
