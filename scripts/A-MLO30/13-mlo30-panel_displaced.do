/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
	
	/!\ Gros morceau de code commented out (vers ligne 100) - à vérifier ?
	Partie : RECOVER OTHER YEARS **-- 1. Import all DADS for matched IDs (was commented out)
	
	Description: Construct a panel for the analysis
		Start from IDs of matched Controls and Treated
		Add all DADS information to construct a panel for analysis
		Since the panel for the Treated is mostly ready, most work is on controls:
			1- take their ID
			2- add all DADS info
			3- panelize:
				a) distinguish main job from others
				b) fill in empty years
 
	
	INPUT:
		${workingdata}/disppan_matchSIZE`s'.dta [panel of displaced workers and their associated controls, created in 2_Displaced\4_matching]
		${miscdata}/01_AUZE_Commune.dta [list of municipalities and employment zones, from INSEE]
		${miscdata}/naf2003_naf2008.dta [crosswalk between NAF 2003 and 2008]
	
	OUTPUT: ${workingdata}/panelpanSIZE`s'.dta [Panel of treated and displaced workers, with all their information over time from DADS]
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

*SETUP*
clear


foreach s in 1 2 {

	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*			PREPARE SAMPLE

		** --1: Keep the treated aside
	use ./data/interim/mlo30/disppan_matchSIZE`s', clear
	gen matchsbr1 = sbr1
	gen matchsbr2 = sbr2
	global matvar matchsbr1 matchsbr2
	cap rename year_cl an_cl

	*I duplicate control for number of matches
	qui summ pairsize
	forvalues i=1/`r(max)' {
		expand `i' if T==0 & pairsize==`i'
		}
	*I create a unique id for each pair
	bysort pairid T: gen temp = _n	
	egen idpair = group(pairid temp)
	*I verify there are 2 individuals per pair
	bysort idpair: egen test = nvals(T)
	cap noisily assert test==2
	drop if test!=2
	drop temp test pairid pairsize

	*I identify the treated id for each pair
	gen temp = nninouv if T==1
		bysort idpair: egen nninouv2=mode(temp)
		drop temp

	*I create a new unique identifier
	egen id2 = group(nninouv nninouv2)
	duplicates report id2


		** --2: Keep the treated aside
	tempfile T temp
		preserve
		keep if T==1
		keep id2 nninouv nninouv2 idpair T controldist pdif
		rename (id2 nninouv2 idpair) (Tid2 Tnninouv2 Tidpair)
		duplicates drop
		save `T'
		restore

	*keep if T==0
		

	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	* 			RECOVER OTHER YEARS

			**-- 1. Import all DADS for matched IDs		
	local varLEc *cl idpair nninouv2
		keep id2 nninouv T `varLEc' $matvar


		preserve
		joinby nninouv using ./data/interim/mlo30/pansmall
		local varJOB debremu finremu nbheur sbr cs2
		local varID age sx
		local varENT sir nic4 entsir comt dept apet apet2 catjur nbsa_et nbsa_ent depr comr
		keep id2 nninouv T an `varLEc' `varJOB' `varID' `varENT' $matvar
		recast double sir sir_cl
		format sir sir_cl %12.0g
		cap append using `temp'
		save ./data/interim/mlo30/panmatch_panSIZE`s', replace
		restore
		
	use ./data/interim/mlo30/panmatch_panSIZE`s', clear
		local varLEc *cl idpair nninouv2
		local varJOB debremu finremu nbheur sbr cs2
		local varID age sx
		local varENT sir nic4 entsir comt dept apet apet2 catjur nbsa_et nbsa_ent depr comr


			**-- 2. Center around event (i.e. matched-treated year of LE)
	gen dist = an-an_cl
	*tostring sir_cl, replace
	format sir sir_cl %12.0g
	gen lastjob = (sir==sir_cl & dist<=0)


			**-- 3. Main job info:
	*Identify main job at year level
	bysort id2 an: egen temp = rank(-nbheur) 
	bysort id2 an: egen temp2 = rank(-sbr) 
	gen temp0 = finremu-abs(debremu)
	bysort id2 an: egen temp3 = rank(-temp0) 
	gen main = temp
	replace main = temp2 if main==1.5
	replace main = temp3 if main==1.5
	replace main = (main==1)

	*When LAST job competes with another MAIN, I prefer LAST
	bysort id2 an: egen temp4 = max(lastjob)
	replace main = 0 if main==1 & temp4==1
	replace main = 1 if main==0 & lastjob==1

	*Replace hours, wages, etc. in main vs. all
	gen sbr_all = sbr
	gen nbheur_all = nbheur
	foreach v of varlist lastjob sir sbr nbheur nbsa_et nbsa_ent {
	replace `v'=. if main==0
	}
	replace comt=dept+comt
	foreach v of varlist cs2 comt  nic4 apet apet2 catjur {
	replace `v'="" if main==0
	}


	*______________________________________________________________________________*

	*			CONTROL GROUP AS PANEL

			**-- 4. One line per year
	gen nbsir_all = 1
	collapse (firstnm) nninouv T dist sbr nbheur cs2 `varLEc' `varID' `varENT' $matvar lastjob (sum) sbr_all nbheur_all nbsir_all, by(id2 an)

	tab lastjob T if dist==-1



			**-- 5. Harmonize job info
	*Recover Zone d'Emploi
	replace comr = depr + comr
	drop dept depr
	rename comt com
	destring com, gen(insee) force
	merge m:1 insee using  ./data/external/01_AUZE_Commune.dta, keep(master matched) nogen keepusing(ze10)


	*Identify SIREN*ZE
	tostring ze10, gen(sirenze)
	gen siren = sir
	format sir siren %12.0g
	tostring siren, replace
	replace siren = "0"+siren if length(siren)==9
		replace nic = "0"+nic if length(nic)==5
		replace nic = "00"+nic if length(nic)==4
		replace sirenze = siren+"-"+sirenze
		drop siren
		
	*Demographics in numeric (gender, occupation, degree)
	destring cs2, replace force
	destring sx , replace
		bysort id2: egen temp = mean(sx)
		replace sx= 1 if temp>0.5
		replace sx= 0 if temp<=0.5
		drop temp

		
	*Only one sectorial classification
	rename apet naf2003
		merge m:1 naf2003 using ./data/external/naf2003_naf2008.dta, keep(master match) nogen
		replace apet2=substr(apet2,1,4) if length(apet2)==5
		replace naf2008=apet2 if naf2008=="" & apet2!=""
		destring naf2008, replace force
		drop apet* naf2003
		
	*Create time invariant info
	destring cs2_cl, replace
	foreach v of varlist sx ze10 cs2 naf2008 {
		bysort id2: egen temp = max(`v'*[dist==-1 & lastjob==1])
		replace `v'_cl = temp if T==0
		drop temp
		}

		
		
			**-- 6. Balance Panel
	*Keep only between -5 
	drop if dist<-5 | dist >8


	*Add 1 line for each distance to treatment & extrapolate time-invariant vars (i.e. closure & demographics)
	preserve
		tempfile temp

		keep id2 nninouv idpair T dist sx *cl
		xtset id2 dist
		tsfill, full
		
		foreach v of varlist id2 nninouv idpair T an sx *cl {
			cap confirm string var `v'
			if _rc==0 {
				bysort id2: egen temp = mode(`v')
				replace `v' = temp
				drop temp
			}
			else {
				bysort id2: egen double temp = max(`v')
				format temp %12.0g
				replace `v' = temp
				drop temp
			}
		}	
		gen an = an_cl + dist
		save `temp'
	restore	
	 
	*When gap are filled: assume hours and wage are 0
	merge 1:1 id2 an using `temp'
		foreach v of varlist nbheur nbheur_all sbr sbr_all {
			replace `v'= 0 if _m==2
			replace `v'= 0 if `v'==.
		}
		drop _m
		

		
		
	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	gen Tid2=id2
	merge m:1 Tid2 using `T', keepusing(controldist) nogen
		drop Tid2
		
		drop if an<2002 | an>2019

		
	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

	sort idpair T id2 dist an
	order idpair id2 nninouv T dist an
	
	*_______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	* 		Outcomes

	*cluster
	egen idcluster = group(nninouv)

	*Winsorize
	*winsor2 nbheur sbr, cut(1 99) replace
	gen sbrhour = sbr/nbheur
	gen employed = (nbheur_all>1 & nbheur_all!=.)

	gen lnsbr = ln(sbr)
	gen lnnbheur = ln(nbheur)
	gen lnsbrhour = ln(sbrhour)


		
	*_______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*					CLEAN UP
	*age cat
	recode age_cl (16/24 = 1) (25/34 = 2) (35/49 = 3) ///
		(50/60 = 4) (60/. = 5), gen(agecat)
		label var agecat "At LE: age category"

	*occup
	gen cs1 = int(cs2_cl/10)
	label define cs1 1 "Agriculture" 2 "CEO, business owners" 3 "Professional (high wage)" 4 "Intermediate" 5 "Employees" 6 "Blue-collars" 7 "Pensioner"
	label value cs1 cs1
	replace cs1=. if cs1==0

	*sector
	gen sec1d = int(naf2008/100)
	recode sec1d (1/3 = 1) (5/39 = 2) (41/43 = 3) (45/56 = 4) (58/63 = 5) (64/66 = 6) (68 = 7) (69/82 = 8) (84/88 = 9) (90/99=10 ) , gen(sec_a10)
	label define A10 1 "Agriculture" 2 "Manufacturing & Extract." 3 "Construction" 4 "Retail" 5 "Info & Com" 6 "Finance" 7 "Real Estate" 8 "Services to Firms" 9 "Public" 10 "Other Services"
	label value sec_a10 A10

	gen sec1d_cl = int(naf2008_cl/100)
	recode sec1d_cl (1/3 = 1) (5/39 = 2) (41/43 = 3) (45/56 = 4) (58/63 = 5) (64/66 = 6) (68 = 7) (69/82 = 8) (84/88 = 9) (90/99=10 ) , gen(sec_a10_cl)
	label value sec_a10_cl A10


	*sex
	keep if sx==sx_cl //PW 16022026: Added it for 12 obs but ???
	assert sx==sx_cl


	*_______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	* 					SAME FIRM ?
	bysort idpair: egen samefirm= nvals(sir_cl)
	tab samefirm if T==1 & dist==-1

	tab controldist if samefirm>1 & samefirm!=.
	drop if samefirm==1
	drop samefirm


	*				SAME CONTROL?
	duplicates tag nninouv if T==0 & dist==0, gen(temp)
	duplicates tag nninouv an if T==0 & dist==0, gen(temp2)
	bysort idpair: egen dup_id = max(temp)
	bysort idpair: egen dup_idan = max(temp2)
	drop temp temp2

	save ./data/interim/mlo30/panelpanSIZE`s'.dta, replace
	cap remove ./data/interim/mlo30/panmatch_panSIZE`s'	
}

/*END OF DOFILE*/
