/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  NB : all do-files starting with "3" correct closures using flows of workers between establishments or Siren x ZE. For instance, we check that they are not massively displaced toward the same firm (all corrections suggsted by Picart).
  
  Description: Do the corrections to be sure we keep actual closures (and not, e.g. restructurations) + merge with FHDADS
	
  INPUT: 
	${workingdata}/02_sirenze_events.dta [Closure events; created in 23_Sharpning.do]
	${workingdata}/sirenzepic2_`x'.dta [panel of movers across siren x ZE, 2002 to 2015; created in 31_Picart_ZE_v2.do]

  OUTPUT: 
	${workingdata}\03_events_corr.dta.dta [Corrected closure events]
	${workingdata}\04_events_fh.dta.dta [Corrected closure events matched with FHDADS]
		
  __________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
  
*SETUP*
clear

global perpic0 2001
global perpic0b = $perpic0 +1
global perpic1 2014
global perpic1b = $perpic1 +1

*	0. Tempfiles
forvalues y = $perpic0 / $perpic1b {
local tempf `tempf' temp_`y' pic_`y'
}
tempfile `tempf' data


*	1. IMPORT AND EXPAND
clear
use ./data/interim/mlo30/sirenze_events_MLO30.dta
capture rename sirenze siret

*	EXPAND each close = 1 obs
summ close_count
forvalues i = 2/`r(max)' {
	expand `i' if close_count==`i'
	}
bysort siret: gen expid = _n
gen klose = .
forvalues i = 1/`r(max)' {
	replace klose=close`i' if expid==`i'
	}
order expid, after(fin)


	*KEEP if nb employee at closure>=10
gen empclos = .
gen emppos = .
forvalues i = $perpic0 / $perpic1b {
	replace empclos = emp`i' if klose==`i'
	replace emppos = emp`i' if klose==`i'-1
	}
	replace emppos = 0 if emppos==.
	
gen todrop = (empclos<10)
		tab todrop
		drop if todrop==1
		drop todrop close*
		rename klose close

capture rename siret sirenze		
		
save `data'
		

		
		
*	2.	MERGE WITH PICART

forvalues y = $perpic0 / $perpic1 {

*	*	*	*	*	*	*	*	*	*


local x = `y'+1
*use 3_Stata_CorrectionFlux/00_Data/sirenzepic_`x'.dta
*use 3_Stata_CorrectionFlux/00_Data/sirenzepic2_`x'.dta
*save `pic_`x'', replace


*	*	*	*	*	*	*	*	*	*


*Call in loss info
use `data', clear
	keep if close==`y'
	*merge 1:m sirenze using `pic_`x'', keep(master matched)
	merge 1:m sirenze using ./data/interim/mlo30/sirenzepic2/sirenzepic2_`x', keep(master matched)



*	2.a. à la Picart : no more than 50% having the same move
gen emploss=empclos-emppos
gen ratio = abs(move_c/emploss)
gen schon1 = (ratio>=0.3) if _merge==3
gen ratio2 = abs(move_sh/emploss), after(ratio)
gen schon2 = (ratio2>=0.7) if _merge==3
gen schonberg = (schon1==1 | schon2==1)
drop schon1 schon2

*capture drop siret2 move* datdeb* ratio*
capture drop sirenze2 move* datdeb* ratio*
	

save `temp_`y'', replace
}



use `temp_${perpic0}', clear
forvalues y = $perpic0b / $perpic1 {
	append using `temp_`y''
	}


keep sirenze expid emploss schonberg close etp_n etp_n_1
duplicates drop

merge 1:1 sirenze expid using `data', nogen keep(matched)



*	4. 	SAVE all events, 1993-2015
rename close year
	order year deb fin, after(expid)
	order empclos emppos emploss, after(year)
	order ze libze apet, after(sirenze)
sort sirenze year
	
save ./data/interim/mlo30/events_corr.dta, replace

*
*	5. DROP if strange things:
drop if schonberg==1
drop if year==deb
drop if etp_n==0 & etp_n_1==0	

*	5. MERGE TO FHDADS
drop if year<=2001
keep sirenze year empclos emppos emploss
sort sirenze year
by sirenze: gen temp = _N
by sirenze: gen temp2 = _n
summ temp2
forvalues i = 1/`r(max)' {
	gen year`i' = year if temp2==`i'
	gen emploss`i' = emploss if temp2==`i'
	gen emppos`i' = emppos if temp2==`i'
	gen empclos`i' = empclos if temp2==`i'
	}
	drop year emploss emppos empclos temp*
	collapse (max) year* empclos* emploss* emppos*, by(sirenze)
	rename *1 *
	
	label var year "Last obs. year"
	
save ./data/interim/mlo30/events_fh.dta, replace

/*END OF DOFILE*/
