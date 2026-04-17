///////// PS1 Macro ////////

** housekeeping
clear all                   // remove anything old stored
set more off, permanently   // tell Stata not to pause
set linesize 255            // set line length for the log file
version                     // check the version of the command interpreter

* Set working directory to the current repo folder
cd "C:\Users\42610\OneDrive - Handelshögskolan i Stockholm\Documents\Macro_II_PS1"
global wd "`c(pwd)'"

* Create folders if they do not exist
cap mkdir figures
cap mkdir output
cap mkdir logs

** Initialize got ** 
! echo "# Macro_II_PS1" >> README.md
! git init
! git add README.md
! git commit -m "first commit"
! git branch -M main
! git remote add origin https://github.com/HannaPee/Macro_II_PS1.git
! git push -u origin main


** capture
cap log close // close a log-file, if one is open
log using "macro_ii_ps1.log", replace


** Import and transport dataset*

local files fredgraph PCECC96 

foreach f of local files {
    import delimited "`f'.csv", clear
    
    // Convert date
    gen date = date(observation_date, "YMD")
    format date %td
    drop observation_date
    
    // Save as Stata file
    save "`f'.dta", replace
}

** Import last dataset* 
import delimited "series-160426.csv", clear

* Clean data * 
drop in 1/106

* chage format of dates* 
gen qdate = quarterly(trim(v1), "YQ")
format qdate %tq

gen date = dofq(qdate)
format date %td

drop v1 qdate


* save dataset* 

save uk_cons_exp.dta, replace

* merge data* 

use fredgraph.dta, clear

local others PCECC96 uk_cons_exp 

foreach f of local others {
    merge 1:1 date using "`f'.dta"
    drop _merge
}

* clean data* 
destring v2, replace

rename v2 con_exp_uk
rename gdpc1 gdp_us
rename ngdprsaxdcgbq gdp_uk
rename pcecc96 con_exp_us 

gen qdate = qofd(date)
format qdate %tq

* Set the time series on the quarterly date
tsset qdate


* take logs and apply hp filters* 
tsset qdate

local vars gdp_us gdp_uk con_exp_us con_exp_uk

foreach v of local vars {
    gen l`v' = log(`v')
    tsfilter hp `v'_trend = l`v', smooth(1600)
    gen `v'_cycle = l`v' - `v'_trend
}


* plot the series* 

*us*

tsline gdp_us_cycle con_exp_us_cycle, ///
    legend(label(1 "GDP (US)") label(2 "Consumption (US)"))

graph export "figures/us_1.pdf"

*uk*

tsline gdp_uk_cycle con_exp_uk_cycle, ///
    legend(label(1 "GDP (US)") label(2 "Consumption (US)"))

graph export "figures/uk_1.pdf"


* calculate variancews and correlations * 

sum gdp_us_cycle
display r(Var)

sum con_exp_us_cycle
display r(Var)

sum gdp_uk_cycle
display r(Var)

sum con_exp_uk_cycle
display r(Var)


corr gdp_us_cycle con_exp_us_cycle
corr gdp_uk_cycle con_exp_uk_cycle
corr gdp_uk_cycle gdp_us_cycle
















