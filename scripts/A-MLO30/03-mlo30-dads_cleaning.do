*SETUP*
clear

/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
/*****
* /!\ Commentaire de Paul au début de ce do file : "I plan to clean the process from DADS to closure panel"
******/
  
  Description: 
	1. Import all Siret, merge with full time equivalent, do some cleaning (geography, sector)
	2. Prepare data to work at Siren x ZE level
	3. Define closure events: loss of 90% employment + loss must persist 2 years

	
  INPUT:
	${workingdata}/temp_AllSiret_$sample.dta [created in 21_Import_DADS.do]
	${workingdata}/temp_ETP.dta [created in 22_ImportDADS_ETP.do]
	
  OUTPUT: 
	${workingdata}/02_sirenze_events.dta [Closure events]
	 
	${workingdata}/01_sirenze_panel.dta [Panel of all Siren x ZE units]
	=> This file is used in 3_LE\3_LEallyears.do
	* Alternatively (commented out below): ${workingdata}/01_siret_panel.dta [Panel of all siret units]
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/


tempfile work ok

global sample 100

global period_0 1993
global period_0b =$period_0 +1
global period_a 2002
global period_b 2003
global period_c 2015

*		1. IMPORT ALL SIRET, AND CLEAN
use "./data/interim/mlo30/temp_AllSiret_$sample.dta" , clear

*	DROP useless variable
capture drop merge*
capture drop pb


*	DROP empty firm
egen test = rowtotal(emp*)
gen todrop = (test==0)
drop if todrop==1
drop todrop test

*	MERGE WITH ETP INFORMATION
merge 1:1 siren nic using "./data/interim/mlo30/temp_ETP.dta", keep(matched) nogen
	
*	CLEAN GEOGRAPHY: commune, dep, and ZE
gen dep = "", after(nic)
gen com = "", after(nic)
forvalues i=$period_0 / $period_c {
	replace com = com`i' if deb<=`i' & length(com`i')==5
	replace dep = dep`i' if deb==`i'
	}
gen miscom = (com=="")
	gen misdep = (dep=="")	
	tab miscom misdep
	drop if length(dep)==3
	drop if regexm(com,"[aA-zZ]")==1

replace com=dep if com==""

drop dep1* dep2* com1* com2* miscom misdep

destring com, gen(insee)
merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(master matched) nogen keepusing(ze10 libze10)
	order *ze*, after(dep)
	bysort ze10: egen temp = mode(libze)
	replace libze=temp if libze==""
	drop temp

*When the commune code is wrong:
drop if ze==.

*
*	CLEAN SECTOR: apet
gen apetfin = "", after(dep)
forvalues i=$period_0 / $period_c {
	replace apetfin = apet`i' if fin==`i'+1 & apet`i'!=""
	}
	replace apetfin = apet2015 if apet2015!=""
		
	drop apet1* apet2*

	
*	DROP INTERIM
drop if apetfin=="745B" & fin<2008
drop if apetfin=="7820Z" & fin>=2008
	
	
/*	DROP Public sector
gen naffin= substr(apet, 1,2)	
gen todrop = 0
	replace todrop=1 if naffin>="75" & naffin<="86" & fin<2008
	replace todrop=1 if naffin>="84" & naffin<="89" & fin>=2008
	tab todrop
	drop if todrop==1
	drop todrop naf*
*/	
	

	
	
*		2. WORK AT SIREN*ZE	
sort siren ze10
by siren ze10: gen temp=(apetfin!=apetfin[_n-1]) if siren==siren[_n-1]
by siren ze10: gen nb_etab= _N
by siren ze10: egen Napet = total(temp)
	replace Napet=Napet+1
	drop temp 
gen apet = apetfin if Napet==1

sort siren ze10 apetfin
	replace fin=2016 if emp2015!=. & fin==.
	egen temp = rowtotal(emp*) if Napet>1
	by siren ze10: egen temp2 = total(temp)  if Napet>1
	by siren ze10 apetfin: egen temp3 = total(temp)  if Napet>1
	by siren ze10: egen temp4 = rank(temp3/temp2), field
	gen temp5 = apetfin if temp4==1
	by siren ze10: egen temp6 = mode(temp5)
	sort siren ze10 fin
	by siren ze10: replace temp6 = apetfin[nb_etab] if temp6 ==""
	replace apet=temp6 if Napet!=1
	drop temp* 
	
gen apetyear = fin-1 if apet==apetfin
	replace apetyear=fin-1 if Napet==1
	order apet apetyear, after(ze10)
	drop apetfin Napet
		
replace fin=2016 if fin==. & emp2015!=.	

collapse (first) libze10 apet (min) deb (max) fin apetyear (sum) emp* etp* hour*, by(siren ze10)


gen naf=0 if apetyear<2003
		replace naf=1 if apetyear>=2003 & apetyear<2008
		replace naf=2 if apetyear>=2008


*		3. DEFINE CLOSURE EVENT


*	 DEFINE Employment = 0 when missing
*this loop if needed when working at siret level
*not much less so with siren.ze
forvalues i = $period_0 / $period_c {
	gen e`i' = emp`i'
	replace e`i'=0 if emp`i'==.
	}

	
*	IDENTIFY loss of 90% employment
*	loss must persist 2 years!


gen close1 = .
gen close_count = 0
forvalues i=$period_0b / 2013 {
	local j = `i'-1
	local k = `i'+1
	local k2 = `i'+2
	replace close1 = `i'-1 if e`i'<=0.7*e`j' & close1==. & e`j'>=1
	replace close1 = . if close1==`i'-1 & e`k'>0.7*e`j' & e`k'!=.
	replace close1 = . if close1==`i'-1 & e`k2'>0.7*e`j' & e`k2'!=.
	replace close_count = close_count+1 if close1== `i'-1
	}

summ close_count

forvalues k = 2/`r(max)' {
	local l = `k'-1
	gen close`k' = .
	forvalues i=$period_0b / $period_c {
	local j = `i'-1
	replace close`k' = `j' if e`i'<=0.7*e`j' & close`k'==. & e`j'>=1 & `j'>close`l'
	}
	}
order close_count, before(close1)

tab close_count

drop e1* e2*
	
*		CONTROL FOR ETP
*I compute the number of job for each full-time worker
*If this is too high: probably measurment error.
*(Case for 0 hours: if well paid, filt=1; représentant de commerce 463e)


*Required: yearly total nb of hours has decrease by
*at least 50% between t-1 and t+2
*t is last year with full employement
*t+1 is when people are laid-off. If this happens
*at the end; then etp_t+1 will be close to full
gen etp_n_1=.
gen etp_n=.
gen etp_n1=.

forvalues i = $period_0 / $period_c {
	replace etp`i'=0 if etp`i'==.
	}

forvalues i=$period_0b / 2013 {
	local h = `i'-1
	local j = `i'+1
	local k = `i'+2
	replace etp_n_1= etp`h' if close1==`i'
	replace etp_n= etp`i' if close1==`i'
	replace etp_n1= etp`k' if close1==`i'
	}
gen ratio_etp = etp_n1/etp_n_1
	

/*
*ETP could be an alternative measure of firm size
*But there it is not as sharp because ETP depends on the
*moment of layoff (if in decembre, people will have worked
*almost full time).

*eff3112 was another alternative, but its subject
*to encoding errors. Also, it does not correct for
*payment adjusting schemes.

*For these 2 reasons, I concluded to the superiority
*of counting people where FILT==1 & finremu>330

*ETP is yet useful to check for strange numbers. The
reason why I use it here.
*/ 


*		4. SAVE
*SIREN.ZE
order siren libze ze deb fin
tostring ze10, gen(sirenze)
	replace sirenze = siren+"-"+sirenze


preserve 

drop close*
save "./data/interim/sirenze_panel.dta", replace

restore

*OR
/**	SIRET
gen siret = siren+"-"+nic	
	order siret com dep libze ze deb fin
drop siren nic insee


*	SAVE all firms cleaned
preserve 

drop close*
save "${workingdata}/01_siret_panel.dta", replace

restore*/



*	KEEP closures
drop if close_count==0

*	DROP too small (at least 50 employees once)
egen temp = rowmax(emp*)
gen todrop = (temp<50)
tab todrop
drop if todrop==1
	drop todrop temp
	

*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

save  "./data/interim/mlo30/sirenze_events_mlo30.dta", replace

/*END OF DOFILE*/
