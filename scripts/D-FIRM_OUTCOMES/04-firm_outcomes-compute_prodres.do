/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

* ------------------------------------------------------------------------------
* Compute `prod_res` (JDP productivity measure):
*   residual from regression of ln(value added) on ln(employment) and capital terms,
*   with coefficients allowed to vary by 2-digit sector (run separate regressions by `naf2d_num`).
* ------------------------------------------------------------------------------

clear

use siren ln_va ln_emp ln_immocor naf2d_num year if year <2016 using "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta", clear

// keep if inrange(naf2d_num,20,30)

capture confirm variable ln_va
capture confirm variable ln_emp
capture confirm variable ln_immocor
if _rc!=0 {
	di as error "Missing required logs (`ln_va`, `ln_emp`, `ln_immocor`) in base dataset."
	error 111
}
capture confirm variable naf2d_num
if _rc!=0 {
	di as error "Missing required sector id `naf2d_num` in base dataset."
	error 111
}

global rhs "ln_emp ln_immocor"
global missfun "missing(ln_va, ln_emp, ln_immocor)"

capture drop prod_res
gen double prod_res = .
label var prod_res "Productivity residual (sector-specific OLS on ln(VA))"

gen byte touse = !missing(ln_va, ln_emp, ln_immocor, naf2d_num, year)
keep if touse
drop touse 

foreach v in ln_va ln_emp ln_immocor {
	bysort year: egen `v'_mean = mean(`v')
	replace `v' = `v' - `v'_mean
	drop `v'_mean
}

capture drop __res
capture quietly regress ln_va ${rhs} if !${missfun}
predict double __res if e(sample), resid
replace prod_res = __res if e(sample)
drop __res

count if mi(prod_res)

compress
save "./data/interim/firm_outcomes/02_ficusfare_with_prodres_1999_2015_nosectors.dta", replace

/*END OF DOFILE*/
