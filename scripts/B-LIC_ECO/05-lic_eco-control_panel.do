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
use ./data/external/sas_fhdads/fhdads_inf2002.dta


keep if an==2000 | an==2001
append using ./data/external/sas_fhdads/fhdads_sup2002.dta
tempfile all2001
save `all2001'


*	2.		RECODE ENTRY CODE
*2.1.	I recover <2002 info
use ./data/external/sas_fhdads/fhdads_inf2002.dta

drop if an==2001 | an==2000

gen ent= entsir
replace ent = entpan if entpan==an & entsir==.

collapse (first) entpan entsir (min) an ent, by(idfhda sir)
	replace ent = an if ent==.
	
keep idfhda sir ent

*2.2.	I merge with >=2002 data
merge 1:m idfhda sir using `all2001', keep(matched using) nogen

*2.3.	I code entry
replace ent=entsir if ent==.

bysort idfhda sir: egen min = min(an)
replace ent = min if entsir==.
drop min


*	3.		KEEP ASIDE
destring sir, replace force
	drop if sir==.
	
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
		
save "./data/interim/lic_eco/03_tmp_fh.dta", replace

/*END OF DOFILE*/
