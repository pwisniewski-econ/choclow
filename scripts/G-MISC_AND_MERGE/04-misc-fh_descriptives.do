cap erase ./data/_tmp/descriptives_fh.dta

forvalues i = 2002/2012 {

	use an cs2 apet apet2 nbheur catjur dip_tot if nbheur>0 & !missing(nbheur)  using "./data/external/fhdads/fhdads_`i'", clear

	*Keep firms in CATJUR = private firm
	cap destring catjur, replace
	recode catjur (3100/3199=0) (5000/5999=0) (6200/6299=0) (6900/6999=0) (min/max=1) , gen(todrop)
	drop if todrop==1
	drop todrop

	gen cs1 = substr(cs2, 1, 1)
		
	rename apet naf2003 
	merge m:1 naf2003 using ./data/external/naf2003_naf2008.dta, keep(master match) nogen
	gen sec1d = substr(naf2008, 1,2)
	destring sec1d, replace force
	
	replace apet2 = substr(apet2, 1, 2) 
	destring apet2, replace force
	replace sec1d = apet2 if mi(sec1d)
	
	
	destring sec1d, replace
	recode sec1d (1/3 = 1) (5/39 = 2) (41/43 = 3) (45/56 = 4) (58/63 = 5) (64/66 = 6) (68 = 7) (69/82 = 8) (84/88 = 9) (90/99=10 ) , gen(sec_a10)
	replace sec_a10 = . if sec_a10<1 | sec_a10 >10
	label define A10 1 "Agriculture" 2 "Manufacturing & Extract." 3 "Construction" 4 "Retail" 5 "Info & Com" 6 "Finance" 7 "Real Estate" 8 "Services to Firms" 9 "Public" 10 "Other Services"
	label value sec_a10 A10

	gen one = 1
	collapse (sum) n=one nbheur, by(an cs1 sec_a10 dip_tot)
		
	cap append using ./data/_tmp/descriptives_fh.dta
	save ./data/_tmp/descriptives_fh, replace

}

use ./data/_tmp/descriptives_fh, clear
save ./data/interim/panel_outcomes/panel_fh0212.dta , replace
cap erase ./data/_tmp/descriptives_fh.dta

/*END OF DOFILE*/
