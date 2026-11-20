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

tempfile temp
use idfhda an sir if an > 1998 using "./data/external/fhdads/fhdads_19962001.dta", clear
save `temp', replace

forvalues i = 2002/2012 {
		use idfhda an sir if an > 1998 using ./data/external/fhdads/fhdads_`i', clear
		cap append using `temp'
		save `temp', replace
}

use `temp', clear

** NEW PW: 20260316

gsort idfhda sir an
by idfhda sir an: keep if _n == 1

by idfhda sir (an): gen is_same = ///
	an == an[_n-1] + 1 if _n>1

gen switch = 0
replace switch = 1 if !is_same

by idfhda sir: gen spell = sum(switch)

bysort idfhda sir spell: egen min_an_sir = min(an)
bysort idfhda sir spell: egen max_an_sir = max(an)

sort idfhda an

*	3.		KEEP ASIDE

keep idfhda an sir spell *_an_sir
	
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
		
save "./data/interim/lic_eco/00_fhdads_tenure.dta", replace

/*END OF DOFILE*/
