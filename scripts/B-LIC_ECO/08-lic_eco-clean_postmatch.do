/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  /!\ Attention, bout de code commenté avec un merge with LE3_TreatedDADS.dta vers la ligne 247. A VERIFIER si nécessaire ou non.
  
  DESCRIPTION: Builds a panel for the analysis containing all DADS data for LE and matched control workers
			   -> starts from IDs of matched Controls and Treated adds all DADS information to construct a panel for analysis
			   
	Since the panel for the Treated is mostly ready, most work is on controls:
	1- take their ID
	2- add all DADS info
	3- panelize:
		a) distinguish main job from others
		b) fill in empty years
	
  INPUT: 
	${workingdata}/le4_matchsize.dta [Pool of LE and controls, created in 3_LE\4_Match_SIZE.do]
	${choclowdata}/FHDADS/fhdads_`i'.dta [DADS, i = 2002/2012]
	${miscdata}\01_AUZE_Commune.dta
	${miscdata}/naf2003_naf2008.dta
   	
  OUTPUT: 
	${workingdata}\le5_panelsize.dta [Panel of LE and controls, with DADS information]
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
*			PREPARE SAMPLE


foreach s in 0 10 {
		
	clear

		** --1: Identify controls and pairs (multiple match issue)
	use ./data/interim/lic_eco/le4_matchsize`s'.dta

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
	cap assert test==2
	tab test
	drop temp test pairid pairsize

	*I identify the treated id for each pair
	gen temp = idfhda if T==1
		bysort idpair: egen idfhda2=mode(temp)
		drop temp

	*I create a new unique identifier
	egen id2 = group(idfhda idfhda2)
	duplicates report id2
	duplicates report idpair

		** --2: Keep the treated aside
	tempfile T temp
		preserve
		keep if T==1
		keep id2 idfhda idfhda2 idpair T controldist year_cl
		rename (id2 idfhda2 idpair) (Tid2 Tidfhda2 Tidpair)
		duplicates drop
		save `T'
		restore

	*keep if T==0



	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	* 			RECOVER CONTROL GROUP VARIABLES

			**-- 1. Import all DADS for matched IDs		
	local varLEc *cl idpair idfhda2
		keep id2 idfhda T `varLEc'

	forvalues i = 2002/2012 {
		preserve
		joinby idfhda using ./data/external/fhdads/fhdads_`i'
		local varJOB debremu finremu nbheur sbr cs2
		local varID age dip_tot sx
		local varENT sir nic4 entsir comt dept apet apet2 catjur nbsa_et nbsa_ent
		keep id2 idfhda T an `varLEc' `varJOB' `varID' `varENT'
		cap append using `temp'
		save `temp', replace
		restore
	}

	use `temp', clear

			**-- 2. Center around event (i.e. matched-treated year of LE)
	gen dist = an-year_cl
	tostring sir_cl, replace
	gen lastjob = (sir==sir_cl & dist<=0)
	sort idpair id2 dist

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
	foreach v of varlist sbr nbheur nbsa_et nbsa_ent {
	replace `v'=. if main==0
	}
	replace comt=dept+comt
	foreach v of varlist cs2 comt sir nic4 apet apet2 catjur {
	replace `v'="" if main==0
	}


	*______________________________________________________________________________*

	*			CONTROL GROUP AS PANEL

			**-- 4. One line per year
	gen nbsir_all = 1
	collapse (firstnm) idfhda T dist lastjob sbr nbheur cs2 `varLEc' `varID' `varENT' (sum) sbr_all nbheur_all nbsir_all, by(id2 an)

			**-- 5. Harmonize job info
	*Recover Zone d'Emploi
	drop dept
	rename comt com
	destring com, gen(insee) force
	merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(matched) nogen keepusing(ze10)
	bysort id2: egen ze10_cl = max(ze10*[dist==-1])

	*Identify SIREN*ZE
	tostring ze10, gen(sirenze)
	rename sir siren
	destring siren, gen(sir) force
	format sir %12.0g
	replace siren = "0"+siren if length(siren)==9
		replace nic = "0"+nic if length(nic)==5
		replace nic = "00"+nic if length(nic)==4
		replace sirenze = siren+"-"+sirenze

	*Demographics in numeric (gender, occupation, degree)
	destring cs2, replace force
	destring sx dip_tot, replace
		bysort id2: egen temp = mean(sx)
		replace sx= 1 if temp>0.5
		replace sx= 0 if temp<=0.5
		drop temp
	bysort id2: egen cs2_cl = max(cs2*[dist==-1])

	*Only one sectorial classification
	rename apet naf2003
		merge m:1 naf2003 using "./data/external/naf2003_naf2008.dta", keep(master match) nogen
		replace apet2=substr(apet2,1,4) if length(apet2)==5
		replace naf2008=apet2 if naf2008=="" & apet2!=""
		destring naf2008, replace force
		drop apet* naf2003
		
		
		
			**-- 6. Balance Panel
	*Keep only between -5 and +6
	drop if dist<-5
	drop if dist>6

	*Add 1 line for each distance to treatment and extrapolate time-invariant vars (i.e. closure & demographics)
	preserve
		tempfile temp

		keep id2 idfhda idpair T year_cl dist sx *cl
		xtset id2 dist
		tsfill, full

		foreach v of varlist id2 idfhda idpair T year_cl sx *cl {
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
			
		gen an = year_cl + dist
		drop if an>2012 | an<2002
		save `temp'
	restore

	*When gap are filled: assume hours and wage are 0
	merge 1:1 id2 an using `temp'
		foreach v of varlist nbheur nbheur_all sbr sbr_all {
			replace `v'= 0 if _m==2
		}
		drop _m
		
		replace T=0 if T==.
		tostring sir_cl, replace

		duplicates report id2 dist

	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

	*			ADD BACK THE TREATED
			**-- 1. Recover info and panel shape
	*All DADS for the Treated:
	*append using ${workingdata}\LE3_TreatedDADS.dta
	*	drop _m
	*	replace T=1 if T==.
	*	replace an_cl=year_cl if T==0
	*	replace year_cl=an_cl if T==1
		

	*Keep panel years only:
	merge m:1 idfhda using `T'
		drop if T==1 & _m!=3
		drop _merge
		replace idfhda2=Tidfhda2 if T==1

		gen an_cl = year_cl 
		
		tab T, m
		duplicates report id2 dist
			
	egen idcluster = group(idfhda)

	*_______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*					ADD UNEMPLOYMENT INS. INFO


			**-- RES WAGE
	*Find NDEM (identifer of the demand)
	merge m:1 idfhda using "./data/interim/lic_eco/le2_lastjob.dta", keepusing(ndem) keep(master match) nogen
	*Recover demand info: reswage!
	merge m:1 idfhda ndem using "./data/interim/lic_eco/le1_dedi.dta", keepusing(motins motann mobdist mobunit salmt salunit temps txrb)  keep(master match)

	*1.2. Reservation wage: I use month, the most common unit 
	replace salmt=. if salmt<8

	tabstat salmt, by(salunit) s(me p10 p25 p50 p75 p90 p99)

	replace salunit="H" if salmt>=8 & salmt<500 & salunit=="A"
	replace salunit="H" if salmt>=8 & salmt<500 & salunit=="M"
	replace salunit="M" if salmt>=1000 & salmt<12000 & salunit=="A"
	replace salunit="M" if salmt>=1000 & salmt<12000 & salunit=="H"
	replace salunit="A" if salmt>=12000 & salmt!=. & salunit=="H"
	replace salunit="A" if salmt>=12000 & salmt!=. & salunit=="M"

	gen res_wage=salmt if salunit=="M"
		replace res_wage=(salmt/12) if salunit=="A"
		replace res_wage=(salmt*1600/12) if salunit=="H"	
		drop sal*
	bysort id2: egen temp = max(res_wage)
	replace res_wage=temp if res_wage==.	
	drop temp
	gen lnreswage = ln(res_wage)
		
		
	*1.3. Mobility
	gen res_mob= mobdist if mobunit=="KM"
		replace res_mob= mobdist if mobunit=="MN"
		replace res_mob= (mobdist*60) if mobunit=="H"
		gen res_mobunt = mobunit if res_mob!=.
		replace res_mobunt="MN" if res_mobunt=="H"
		drop mob*
		
	*1.4. Hours
	destring temps, gen(res_hours)
		label define hours 1 "Full time" 2 "Part time"
		label value res_hours hours
		drop temps
		
	*Var categories are in DADS_FH-DADS_2012\Documentation\FHS\201706_FHS_Dico	
		
		
	*2.1 Replacement rate	
	gen lntxrb = ln(txrb)

	*_______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	* 		Outcomes

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


	/*
	*diploma
	replace dip_tot = dip_tot_cl if dip_tot==.
	drop dip_tot_cl
	bysort id2: egen temp = max(dip_tot)
	*replace dip_tot = temp if dip_tot!=. /*was just to check everyone has only 1 dip level*/
	replace dip_tot = temp if dip_tot==.
	drop temp
	replace dip_tot=0 if dip_tot==.
	label define dip 0 "Missing" 1 "No diploma" 2 "Elementary school" 3 "Junior High School" 4 "Vocational basic" 5 "Vocational advanced" 6 "High School Graduate" 7 "Undergraduate University" 8 "University Graduate"
	label value dip dip
	*/

	*sex
	bysort id2: egen temp = max(sx)
	replace sx= temp if sx==.
	drop temp

	*sample
	drop if dist<-5 | dist >6


	*_______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	* 					SAME FIRM ?
	bysort idpair: egen samefirm= nvals(sir_cl)
	tab samefirm if T==1 & dist==-1

	tab controldist if samefirm>1 & samefirm!=.

	drop if samefirm==1
	drop samefirm

	*				SAME CONTROL?
	duplicates tag idfhda if T==0 & dist==0, gen(temp)
	duplicates tag idfhda an if T==0 & dist==0, gen(temp2)
	bysort idpair: egen dup_id = max(temp)
	bysort idpair: egen dup_idan = max(temp2)
	drop temp*

	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

			**-- 2. SAVE
	save ./data/interim/lic_eco/le5_panelsize`s'.dta, replace

} 

/*END OF DOFILE*/
