* ------------------------------------------------------------------------------
* Final deliverables:
* 1) siren x year panel 2002-2015 with firm outcomes + markups + TFP and 3-year lagged moving averages
* 2) siren-level dataset with averages over 2002-2015
* ------------------------------------------------------------------------------

clear

global vlist0 ln_lshare ln_va ln_emp ln_apl year_cre
des ${vlist0}  using "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta"

des using "./data/interim/firm_outcomes/04_ficusfare_with_markup_tfp_1999_2015.dta"

use "./data/interim/firm_outcomes/04_ficusfare_with_markup_tfp_1999_2015.dta", clear

keep siren year maxmfg naf2d_num tfp_cd tfp_tl

//keep if runiform()<0.1

merge 1:1 siren year using "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta", keepusing(${vlist0}) gen(_m_0) keep(1 3)
keep if _m_0==3
drop _m_0

merge 1:1 siren year using "./data/interim/firm_outcomes/02_ficusfare_with_prodres_1999_2015_nosectors.dta", keepusing(prod_res) keep(1 3) gen(_m_0) 
*keep if _m_0==3
drop _m_0

* Ensure panel settings for lags
capture confirm variable firmsId
if _rc!=0 {
	egen long firmsId = group(siren)
}
xtset firmsId year

* Build list of variables to compute lagged 3-year moving averages (t-3..t-1)
local ma_vars ""
foreach v in ln_lshare ln_va ln_emp ln_apl prod_res tfp_cd tfp_tl {
	
	capture confirm variable `v'
	if _rc==0 local ma_vars "`ma_vars' `v'"
}

global ma_vars "`ma_vars'"

foreach v of local ma_vars {
	
	gen double L1_`v' = L1.`v'
	gen double F1_`v' = F1.`v'
	
	*gen double L4_`v' = L4.`v'
	*gen double L6_`v' = L6.`v'
	*gen double L7_`v' = L7.`v'
	
	gen double `v'_ma3 = (L1_`v' + `v' + F1_`v')/3
	label var `v'_ma3 "3-year moving average of `v' (centered on t)"
	
	*egen double `v'_ma5 = rowmean(L7_`v' L6_`v' L5_`v' L4_`v' L3_`v')
	*label var `v'_ma5 "5-year moving average of `v' (centered, on l5)"
	
	*replace `v'_ma5 = . if missing(`v'_ma3)
	*replace `v'_ma5 = . if missing(`v'_ma3)
	
	drop L* F*
}

gen naf2d_ma3 = .
replace naf2d_ma3 = F1.naf2d_num if F1.naf2d_num == naf2d_num | F1.naf2d_num == L1.naf2d_num
replace naf2d_ma3 = naf2d_num if missing(naf2d_ma3)


* Keep requested window for the output panel

preserve

keep siren year *_ma3
keep if (!missing(ln_va_ma3) | !missing(ln_emp_ma3)) 

global ma_outcomes ln_lshare_ma3 ln_apl_ma3 prod_res_ma3 tfp_cd_ma3 tfp_tl_ma3

foreach var of varlist $ma_outcomes {
	global depvar `var'
	reghdfe $depvar if inrange(year, 2000, 2011), abs(naf2d_ma3 , savefe) resid 
	rename __hdfe1__ ${depvar}_d2FE
	rename _reghdfe_resid ${depvar}_d2res
}

compress

save "./data/interim/firm_outcomes/firm_siren_avg_moving.dta", replace

restore

drop *_ma3 
keep if inrange(year, 2001, 2015)

compress

save "./data/_tmp/firm_panel_siren_year_2002_2015.dta.tmp", replace


* Firm-level averages over the full panel window ---------
* for 01-04 (pre-treatment) or full sample (02-15)

use siren year_cre using "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta", clear 
bys siren (year_cre) : keep if _n==1
save "./data/_tmp/year_cre.dta.tmp", replace
	
foreach spec in "0215" "0104" {
	
	use "./data/_tmp/firm_panel_siren_year_2002_2015.dta.tmp", clear
	
	if "`spec'" == "0215" {
		keep if year > 2001
	} 
	else if "`spec'" == "0104" {
		keep if year < 2005
	}
	
	bys siren naf2d: gen N=_N
	bys siren (N): gen naf2d_num_main = naf2d_num[_N]
	
	local mean_vars "$ma_vars"
	
	collapse (mean) `mean_vars' (first) N (max) max_year = year (min) min_year = year maxmfg , by(siren naf2d_num_main)	
	
	foreach v of local mean_vars {
	rename `v' `v'_mean_`spec'
	}
	
	if "`spec'" == "0104" {
		drop N max_year min_year maxmfg naf2d_num_main
	} 
	
	save "./data/_tmp/firm_siren_avg_`spec'.dta", replace
	
}

erase "./data/_tmp/firm_panel_siren_year_2002_2015.dta.tmp"

use "./data/_tmp/firm_siren_avg_0215.dta", clear
merge 1:1 siren using "./data/_tmp/firm_siren_avg_0104.dta", nogen
merge 1:1 siren using "./data/_tmp/year_cre.dta.tmp", nogen
erase "./data/_tmp/year_cre.dta.tmp"

save "./data/_tmp/firm_siren_avg_0215.dta", replace

import delimited "./data/interim/akm_fe/ffe_firm_0215_godechot.csv", clear
drop if siren==.
save "./data/_tmp/godechot.dta", replace

use "./data/_tmp/firm_siren_avg_0215.dta", clear
merge 1:1 siren using "./data/_tmp/godechot.dta", nogen
erase "./data/_tmp/godechot.dta"


ds *_mean_* fe*
local vars `r(varlist)'
egen nmiss = rowmiss(`vars')
drop if nmiss == `:word count `vars''
drop nmiss


ds ln_lshare_* ln_apl_* tfp_* prod_res_* fe*
foreach var of varlist `r(varlist)' {
	global depvar `var'
	reghdfe $depvar, abs(naf2d_num_main , savefe) resid 
	rename __hdfe1__ ${depvar}_d2FE
	rename _reghdfe_resid ${depvar}_d2res
}	

save "./data/interim/firm_outcomes/firm_siren_avg_fixed.dta", replace
erase "./data/_tmp/firm_siren_avg_0215.dta"
erase "./data/_tmp/firm_siren_avg_0104.dta"



*cap erase "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta"
*cap erase "./data/interim/firm_outcomes/02_ficusfare_with_prodres_1999_2015.dta"
*cap erase "./data/interim/firm_outcomes/04_ficusfare_with_markup_tfp_1999_2015.dta"



/*END OF DOFILE*/
