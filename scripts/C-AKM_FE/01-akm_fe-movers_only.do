/* Create a dataset containing movers only to compute AKM firm effects */
global year 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 

foreach y in $year {
	use "./data/external/godechot_dads/dads_out/dads`y'.dta", clear
	rename *, lower
	drop if mi(s_brut)|mi(nbheur)|nbheur==0|s_brut==0
	bys ident_all year (s_brut): keep if _n==_N
	gen hw = s_brut / nbheur
	winsor2 hw, cut(1 99) replace
	*drop regt nic
	compress 
	save "./data/_tmp/dads`y'_temp.dta", replace
}

foreach y in $year {
use "./data/_tmp/dads`y'_temp.dta", clear
local k = `y'+1
	if `k' != 2019 {
	append using "./data/_tmp/dads`k'_temp.dta"
	bys ident_all siren: gen siren_by_id = _n == 1
	bys ident_all: egen nb_siren_by_id = total(siren_by_id)
	keep if nb_siren_by_id > 1
	drop siren_by_id nb_siren_by_id
	save "./data/_tmp/temp_`y'_`k'.dta"	
	}
}

foreach y in $year {
	local k = `y'+1
	if `k'<2019 {
		use ident_all using "./data/_tmp/temp_`y'_`k'.dta"	, clear
		gduplicates drop
		save "./data/_tmp/temp_idmovers_`y'_`k'.dta", replace
	}
}

clear
foreach y in $year {
	local k = `y'+1
	if `k'<2019 {
		append using "./data/_tmp/temp_idmovers_`y'_`k'.dta"
	}
	*cap erase "temp_idmovers_`y'_`=y+1'.dta"
	*cap erase "temp_idmovers_`y'_`=y+1'.dta"
}
gduplicates drop
save "./data/_tmp/temp_idmovers_2002_2018.dta", replace


foreach y in $year {
	local k = `y'+1
	if `k'<2019 {
		cap erase "./data/_tmp/temp_`y'_`k'.dta"	
		cap erase "./data/_tmp/temp_idmovers_`y'_`k'.dta"
	}
}

foreach y in $year {
	use "./data/_tmp/dads`y'_temp.dta", clear
		merge m:1 ident_all using "./data/_tmp/temp_idmovers_2002_2018.dta", keep(3)
		drop _merge
		cap erase "./data/_tmp/dads`y'_temp.dta"
	save "./data/_tmp/moversspells_`y'.dta"
}
		
*global year 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020
clear
foreach y in $year {
	append using "./data/_tmp/moversspells_`y'.dta"
}

*save "all_movers_2002_2018.dta", replace
export delimited "./data/interim/akm_fe/all_movers_2002_2018.csv", replace delimiter(",")  

foreach y in $year {
	cap erase "./data/_tmp/moversspells_`y'.dta"
}
	
/*
global year2 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019
use "temp_2002_2003.dta", clear
foreach y in $year2 {
	local k = `y'+1
	append using "temp_`y'_`k'.dta"
	gduplicates drop
}
save "movers_2002_2020.dta"
*/

/*END OF DOFILE*/
