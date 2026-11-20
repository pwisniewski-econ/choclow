/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  DESCRIPTION: 
	- I have identified LE individuals (in 3_LE\1_LE_DI_DE.do)
	- And matched the FH with the affected DADS Job (in 3_LE\2_LEdads.do)
	=> This do file: I now construct the full panel for these workers
	
  
  INPUT: ${workingdata}\le2_lastjob.dta [created in 3_LE\2_LEdads.do]
	
	merged with :
	${choclowdata}/FHDADS/fhdads_`i' [DADS, i = 2002/2012]
	${miscdata}\01_AUZE_Commune.dta [info on ZE]
	${workingdata}/01_sirenze_panel.dta" [Panel of all Siren x ZE units, created in 1_Closures\23_Sharpning.do]
	${miscdata}/naf2003_naf2008.dta
		  
  OUTPUT: ${workingdata}\le3_treated_dads.dta [full panel for LE workers]
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
  
  
clear
set more off
set matsize 11000


*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*					DADS INFO
		**--1.  Aggregate DADS
use "./data/interim/lic_eco/le2_lastjob.dta"
rename (sir and semd) (sir_cl an_cl sem_cl)
local varLE ndem datins an_cl sem_cl sir_cl
keep idfhda `varLE'

duplicates report

tempfile temp
forvalues i = 2002/2012 {
	preserve
	merge 1:m idfhda using "./data/external/fhdads/fhdads_`i'", keep(match)
	local varJOB debremu finremu nbheur sbr cs2
	local varID age dip_tot sx
	local varENT sir nic4 entsir comt dept apet apet2 catjur nbsa_et nbsa_ent
	keep idfhda an `varLE' `varJOB' `varID' `varENT'
	cap append using `temp'
	save `temp', replace
	restore
}

*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

		**-- 2. Center around event (i.e. matched-treated year of LE)
use `temp', clear
*Identify position where LE occured later
gen dist = an-an_cl
gen lastjob = (sir==sir_cl & dist<=0)
bysort idfhda: egen observed = max(lastjob)
drop if observe!=1
drop observed


		**-- 3. Main job info:
*Identify main job at year level
bysort idfhda an: egen temp = rank(-nbheur) 
bysort idfhda an: egen temp2 = rank(-sbr) 
gen temp0 = finremu-abs(debremu)
bysort idfhda an: egen temp3 = rank(-temp0) 
gen main = temp
replace main = temp2 if main==1.5
replace main = temp3 if main==1.5
replace main = (main==1)

*When LAST job competes with another MAIN, I prefer LAST
bysort idfhda an: egen temp4 = max(lastjob)
replace main = 0 if main==1 & temp4==1
replace main = 1 if main==0 & lastjob==1

*Replace hours, wages, etc. in main vs. all
gen sbr_all = sbr
gen nbheur_all = nbheur
foreach v of varlist sbr nbheur nbsa_et nbsa_ent {
replace `v'=. if main==0
}
replace comt=dept+comt
foreach v of varlist cs2 comt sir nic4 apet apet2 catjur {
replace `v'="" if main==0
}


*______________________________________________________________________________*
*			PANELIZE

		**-- 4. One line per year
gen nbsir_all = 1
collapse (firstnm) dist lastjob `varLE' sbr nbheur cs2 `varID' `varENT'  (sum) sbr_all nbheur_all nbsir_all, by(idfhda an)
bysort idfhda : egen lastobs = max(an*[lastjob==1])


		**-- 5. Harmonize job info
*Recover Zone d'Emploi
drop dept
rename comt com
destring com, gen(insee) force
merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(matched) nogen keepusing(ze10)
bysort idfhda: egen ze10_cl = max(ze10*[lastjob==1])

*Identify SIREN*ZE
tostring ze10, gen(sirenze)
rename sir siren
destring siren, gen(sir) force
format sir %12.0g
replace siren = "0"+siren if length(siren)==9
	replace nic = "0"+nic if length(nic)==5
	replace nic = "00"+nic if length(nic)==4
	replace sirenze = siren+"-"+sirenze

*Number of employees at LE	
merge m:1 sirenze using "./data/interim/sirenze_panel.dta", keep(master match) nogen keepusing(emp*)

/*
	C:\Users\Public\Documents\Layoffs\4_Displaced30\1_Event_30pct.do (1 hit)
	Line 218: save ${workingdata}/01_sirenze_panel30.dta, replace
*/

gen temp=.
forvalues i = 2003/2012 {
	 replace temp = emp`i' if an==`i' & lastjob==1 & dist==-1
	 }
replace temp = nbsa_et if temp==.	 
bysort idfhda: egen empclos_cl = max(temp)
drop emp1* emp2* temp

*Demographics in numeric (gender, occupation, degree)	
destring cs2, replace force
destring sx dip_tot, replace

*Only one sectorial classification
rename apet naf2003
	merge m:1 naf2003 using "./data/external/naf2003_naf2008.dta", keep(master match) nogen
	replace apet2=substr(apet2,1,4) if length(apet2)==5
	replace naf2008=apet2 if naf2008=="" & apet2!=""
	destring naf2008, replace force
	drop apet* naf2003
	
*Labels (some)
label var dist "Distance to LE"
label var datins "USpell: date regist."
label var sir "Main job: SIREN"
label var nic4 "Main job: NIC4"
label var nbheur "Job(s): sum hours sem."
label var sbr "Job(s): sum gross w. sem."
label var nbsir_all "Job(s): nb. jobs. sem."



		**-- 6. Balance Panel
*Keep only between -5 and +6
drop if dist<-5
drop if dist>6


*Add 1 line for each distance to treatment and extrapolate time-invariant vars (i.e. closure & demographics)
preserve
tempfile temp

foreach v of varlist age cs2 dip_tot naf2008 {
gen `v'_cl = `v' if lastobs==an
}

keep idfhda an_cl dist *cl
egen id2= group(idfhda)
xtset id2 dist
tsfill, full

foreach v of varlist idfhda an *cl {
	cap confirm string var `v'
	if _rc==0 {
	by id2: egen temp = mode(`v')
	replace `v' = temp
	drop temp
	}
	else {
	by id2: egen temp = max(`v')
	replace `v' = temp
	drop temp
	}
	}
	
gen an = an_cl + dist
drop id2
save `temp'
restore


*When gap are filled: assume hours and wage are 0
merge 1:1 idfhda an using `temp'

foreach v of varlist sbr* nbheur* nbsir_all {
replace `v' = 0 if `v'==.
}

drop if an>2012 | an<2002

destring sir, force replace
	drop if sir==.
	
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

save "./data/interim/lic_eco/le3_treated_dads.dta", replace

/*END OF DOFILE*/
