/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  DESCRIPTION: Pas clair. Créé 03_tmp_fh.dta qui est ensuite utilisée dans 3_LE\3_ControlGroup
	
  INPUT: 
	${sasfhdads}/fhdads_inf2002.dta
	${sasfhdads}/fhdads_sup2002.dta
		  
  OUTPUT: 
	${workingdata}\03_tmp_fh.dta
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

clear

*	1.		KEEP PERIOD

foreach i in 19942001 20022007 20082012 20132019 {
	use nninouv an SIR if !missing(SIR) using "./data/external/sas_paneldads/PAN19_`i'", clear
	rename *, lower
		
	destring sir, replace force
	drop if sir==.
	
	cap append using ./data/_tmp/mlo30_tenure.dta
	save ./data/_tmp/mlo30_tenure.dta, replace 
}


** NEW PW: 20260316

gsort nninouv sir an
by nninouv sir an: keep if _n == 1

by nninouv sir (an): gen is_same = ///
	an == an[_n-1] + 1 if _n>1

gen switch = 0
replace switch = 1 if !is_same

by nninouv sir: gen spell = sum(switch)

bysort nninouv sir spell: egen min_an_sir = min(an)
bysort nninouv sir spell: egen max_an_sir = max(an)

sort nninouv an

*	3.		KEEP ASIDE

keep nninouv an sir spell *_an_sir
	
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
		
save "./data/interim/mlo30/mlo30_tenure.dta", replace
cap erase "./data/_tmp/mlo30_tenure.dta"

/*END OF DOFILE*/
