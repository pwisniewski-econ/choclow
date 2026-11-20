/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  Description : 
	The goal here is to identify what JOB (from DADS) was lost in LE
	There is no identifier linking a specific DADS position to a specific FH demand. 

	I am interested by the FIRST PROPER LAYOFF
		-"FIRST" means (potential) following layoff will be considered as normal outcomes
		-"FIRST" is actually "first observed" (as we don't know before 2002)
		-"PROPER" means a LE affecting a full-time tenured job. Not interested in small contracts, etc.
		-"LAYOFF" means I need a rule to link DADS with DE

	Here is how I procced:	
		1) For each individual, find jobs that could suit the layoff selection rules
			(rules are : 2 years >1800hours in the job ; age >25/60 etc.)
			[NB CH 24/03/2025: One of the referees at EJ is asking to include workers aged 20 and above]
		2) for each layoff, find jobs that is suspected to be the previous one
		3) keep the first LE with an eligible job and identify that specific job (for further do-files)
  
	INPUT: 
		${workingdata}\le1_dedi.dta [created in 1_LE_DI_DE.do]
		merged with raw DADS: ${choclowdata}/FHDADS/fhdads_`i'
  
  Output : ${workingdata}\le2_lastjob.dta [Jobs (from DADS) that were lost in LE]
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

clear
set more off
set matsize 11000


*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
*			1. DADS FOR LE ONLY

		**-- Aggregate DADS if LE
tempfile temp temp1 temp2
use "./data/interim/lic_eco/le1_dedi.dta"
keep idfhda
duplicates drop

forvalues i = 2002/2012 {
	preserve
		merge 1:m idfhda using ./data/external/fhdads/fhdads_`i', keep(match)
		keep idfhda sir an nic4 entsir comt dept debremu finremu nbheur sbr age
		cap append using `temp'
		save `temp', replace
	restore
}
use `temp', clear


*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

*			1. STEP 1, keep only "proper" jobs

		**-- 1st rule, individual was working in june t-1 and is not in june t+1
sort idfhda sir an debremu
gen junt_1 =  (debremu[_n-1]<180 & finremu[_n-1]>180 & idfhda==idfhda[_n-1] & sir==sir[_n-1] & an==an[_n-1]+1)
gen junt1 = (debremu[_n+1]<180 & finremu[_n+1]>180 & idfhda==idfhda[_n+1] & sir==sir[_n+1] & an==an[_n+1]-1)

save `temp1'


*			2. STEP 2, find LE-DADS link!
		
		**-- Cover t and t-1 (other years are irrelevant)
use "./data/interim/lic_eco/le1_dedi.dta", clear
	keep idfhda ndem datins datan and semd cdtdtdeb cdtdtfin date*
	expand 2
	bysort idfhda: gen an = _n -2
	replace an = and+an

*Match the two data (FH & DADS) 
joinby idfhda an using `temp1', unmatched(master)

*then I keep only DADS job that have: full time, tenure, was there on june 30 t-1 won't be on june 30 t+1
keep if junt_1==1 & junt1==0

*for 1 same demand, I keep the closest ending of contract (in year)
gen dist = and-an
	bysort idfhda ndem: egen ok = rank(dist)
	drop if ok!=1

*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

save "./data/interim/lic_eco/le2_alljobs.dta", replace

drop _merge

merge m:1 idfhda an sir using "./data/interim/lic_eco/00_fhdads_tenure.dta", keep(master match) nogen

gen tenure = and-int(min_an_sir)+1 

keep if tenure >= 3 & age > 19 & age < 51


*			3. STEP 3, Keep only the 1st observed & match LE

*there are few guys who have close enough successive layoff. I only keep the first one ever recorded
*and consider following layoff as potential outcomes
bysort idfhda: egen prems = rank(and)
	drop if prems!=1
	
	
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
		
save "./data/interim/lic_eco/le2_lastjob.dta", replace

/*END OF DOFILE*/
