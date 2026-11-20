* ------------------------------------------------------------------------------
* Build base firm-year panel from DGM FICUS-FARE dataset (no EAP).
* Output: `${workingdata}/01_ficusfare_base_1999_2015.dta`
* ------------------------------------------------------------------------------

clear

* ---- Inputs (support both spellings seen in notes / DGM code) ----
local ficusfare_file "./data/interim/firm_outcomes/ficusfare_profil_wof_19992015_v0222_light.dta"
capture confirm file "`ficusfare_file'"

* ---- Load and basic checks ----
use "`ficusfare_file'", clear

capture confirm variable siren
if _rc!=0 {
	di as error "Expected firm identifier `siren' not found in raw dataset."
	error 111
}
capture confirm variable year
if _rc!=0 {
	di as error "Expected time variable `year' not found in raw dataset."
	error 111
}

* Core variables required for JDP outcomes + markup/TFP (fail fast with clear messages)
foreach v in catotal va emp sal immocor acha4 autacha {
	capture confirm variable `v'
	if _rc!=0 {
		di as error "Missing required variable `v' in raw dataset (needed for firm outcomes / markup / TFP)."
		error 111
	}
}

* ---- Keep years needed for deliverables (moving averages for 2002 need 1999-2001) ----
keep if inrange(year, 1999, 2015)

* ---- Harmonize industry variables (minimal, based on DGM code) ----
capture confirm variable naf2003_single
if _rc==0 {
	gen naf2d = substr(naf2003_single, 1, 2)
	gen naf_single = naf2003_single
}
else {
	capture confirm variable naf_single
	if _rc==0 {
		gen naf2d = substr(naf_single, 1, 2)
	}
	else {
		di as error "Missing `naf2003_single' (or fallback `naf_single') needed to build `naf2d'."
		error 111
	}
}

capture drop naf2d_num
destring naf2d, gen(naf2d_num) force

* Manufacturing indicator (JDP controls / summaries often use this)
gen byte mfg = inrange(naf2d_num, 10, 33) if !mi(naf2d_num)
bysort siren: egen byte maxmfg = max(mfg)
label var mfg "Manufacturing (NAF 2d in [10,33])"
label var maxmfg "Ever manufacturing in 1999-2015"

* ---- Deflators (DGM replication package) ----
capture confirm variable code
if _rc!=0 {
	di as error "Missing `code' used to merge sector deflators (key: code year)."
	error 111
}

merge m:1 code year using "./data/external/gdp_deflator_euklems_nov21.dta"
drop if _merge==2
drop _merge

* Deflated variables (names follow DGM conventions)
gen double catotalR = catotal/sectordeflator_GO_P if sectordeflator_GO_P>0
label var catotalR "Deflated turnover (DGM: sectordeflator_GO_P)"

gen double salR = sal/deflator if deflator>0
label var salR "Deflated labor cost (DGM: deflator)"

gen double immocorR = immocor/deflator if deflator>0
label var immocorR "Deflated tangible capital (DGM: deflator)"

gen double autachaR = autacha/sectordeflator_II_P if sectordeflator_II_P>0
label var autachaR "Deflated services input (DGM: sectordeflator_II_P)"
foreach a of numlist 1/6 {
	capture confirm variable acha`a'
	if _rc==0 {
		gen double acha`a'R = acha`a'/sectordeflator_II_P if sectordeflator_II_P>0
		label var acha`a'R "Deflated purchases acha`a' (DGM: sectordeflator_II_P)"
	}
}

* ---- Core JDP firm outcomes from balance sheet / income statement ----
gen double apl = va/emp if va!=. & emp>0
label var apl "Value added per worker (va/emp)"

gen double lshare = sal/va if sal!=. & va>0
label var lshare "Labor share (sal/va)"

* Logs used throughout the JDP codebase (prefix `ln_*`)
gen double ln_va 		= ln(va) 		if va>0
gen double ln_emp 		= ln(emp) 		if emp>0
gen double ln_sal 		= ln(sal) 		if sal>0
gen double ln_catotal 	= ln(catotal) 	if catotal>0
gen double ln_apl 		= ln(apl) 		if apl>0
gen double ln_lshare 	= ln(lshare) 	if lshare>0
*gen double ln_immoinc 	= ln(immoinc) 	if immoinc >0 //added 18/03/2026

capture confirm variable immocor
if _rc==0 gen double ln_immocor = ln(immocor) if immocor>0
capture confirm variable inpcs
if _rc==0 gen double ln_inpcs = ln(inpcs) if inpcs>0
capture confirm variable acha4
if _rc==0 gen double ln_acha4 = ln(acha4) if acha4>0
capture confirm variable autacha
if _rc==0 gen double ln_autacha = ln(autacha) if autacha>0

* ---- Firm age (best-effort; DGM notes `datcr' is less reliable pre-2009) ----
capture confirm variable year_cre
if _rc!=0 {
	capture confirm variable datcr
	if _rc==0 {
		gen str4 __yearcr = substr(datcr, 1, 4)
		replace __yearcr = "." if __yearcr=="1111"
		destring __yearcr, gen(year_cre) force
		drop __yearcr
		label var year_cre "Year of creation (from datcr when available)"
	}
}

capture confirm variable year_cre
if _rc==0 {
	gen int age = year - year_cre + 1 if year_cre<. & year<.
	label var age "Firm age (years since creation)"
	gen byte age10 = (age>10) if !mi(age)
	label var age10 "Age > 10 years"
}

* ---- Market share within 5-digit industry (DGM variable `ms5d`) ----
capture confirm variable catotal
local rc_catotal = _rc
capture confirm variable naf_single
local rc_naf = _rc
if `rc_catotal'==0 & `rc_naf'==0 {
	bysort year naf_single: egen double __catotal_tot = total(catotal)
	gen double ms5d = catotal/__catotal_tot if __catotal_tot>0
	drop __catotal_tot
	label var ms5d "Market share within (year x naf_single), based on turnover"
}

* ---- Numeric firm id for panel ops (used downstream) ----
capture confirm variable firmsId
if _rc!=0 {
	capture confirm numeric variable siren
	if _rc==0 {
		gen long firmsId = siren
	}
	else {
		egen long firmsId = group(siren)
	}
	label var firmsId "Numeric firm id (grouped from siren if needed)"
}

* ---- Save base panel ----
local keepvars "siren year firmsId code naf2d naf2d_num naf_single mfg maxmfg"
local keepvars "`keepvars' catotal va emp sal immocor acha4 autacha"
local keepvars "`keepvars' catotalR salR immocorR acha4R autachaR"
local keepvars "`keepvars' apl lshare ln_va ln_emp ln_sal ln_catotal ln_apl ln_lshare ln_immocor ln_acha4 ln_autacha ms5d"

capture confirm variable inpcs
if _rc==0 local keepvars "`keepvars' inpcs ln_inpcs"
capture confirm variable year_cre
if _rc==0 local keepvars "`keepvars' year_cre age age10"
capture confirm variable ape
if _rc==0 local keepvars "`keepvars' ape"

keep `keepvars'
compress
save "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta", replace
cap erase "./data/interim/firm_outcomes/ficusfare_profil_wof_19992015_v0222_light.dta"

/*END OF DOFILE*/
