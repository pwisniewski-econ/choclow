clear
// Run from the project root, as set by master.R.

/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  DESCRIPTION: This do file does the matching between LE and Controls
		1) Starting with LE panel 
		2) merge pool of potential Controls
		3) Match
		4) output : 
			- individual IDs for Control and LE
			- event common info: pair ID; layoff date, etc.
	
  INPUT: 
	${workingdata}\le3_treated_dads.dta [full panel for LE workers, created in 3_LE\3_LEallyears.do]
	${workingdata}\ctrpool.dta [Pool of potential controls for LE workers, created in 3_LE\3_ControlGroup]
  	
  OUTPUT: 
	${workingdata}/le4_matchsize.dta 
	
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/


*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
*			MERGE CONTROL AND TREATED

* CH 15/01/26: comment tempfile
*tempfile T match


foreach s in 0 10 {

			**-- Treated
	use "./data/interim/lic_eco/le3_treated_dads.dta", clear
	keep if inlist(dist,-1,-2,-3)
	keep idfhda an_cl dist sbr* nbheur* age_cl empclos_cl naf2008_cl sir_cl nbsa_ent*
	replace dist = dist*(-1)
	destring sir_cl, replace force
	reshape wide sbr sbr_all nbheur nbheur_all nbsa_ent, i(idfhda) j(dist)

	gen T = 1
	*save `T'
	save "temp_T.dta", replace
	tab T
	* 25 710 obs with T == 1

			**-- Controls
	use "./data/interim/lic_eco/ctrpool.dta", clear
	keep idfhda year_cl sbr* nbheur* age_cl empclos_cl naf2008_cl T sir nbsa_ent*
	rename sir sir_cl
	rename year_cl an_cl
	rename (nbheur_* sbr_* nbsa_ent_*) (nbheur* sbr* nbsa_ent*)
	* append using `T'
	append using  "temp_T.dta"
	format sir_cl %12.0g

			**-- Verify selection rules
	*I exclude treated from the pool of potential controls
	bysort idfhda: egen dup = max(T)

	/*
	ta dup T

			   |           T
		   dup |         0          1 |     Total
	-----------+----------------------+----------
			 0 | 7,056,822          0 | 7,056,822 
			 1 |         0     25,710 |    25,710 
	-----------+----------------------+----------
		 Total | 7,056,822     25,710 | 7,082,532 
	*/

	drop if dup==1 & T==0
	drop dup

	*I verify number of hours
	*drop if nbheur1<1800
	*drop if nbheur2<1800 


	keep if !mi(nbheur1) & !mi(nbheur2) & !mi(nbheur3) & !mi(nbsa_ent2)
	keep if nbheur1>0 & nbheur2>0 & nbheur3>0

	if `s'==10{
		keep if nbsa_ent2 >= 10
	}

	*I verify age
	drop if age_cl<20
	drop if age_cl>50


	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*			MATCHING VARIABLES 

	*Code for sectors:
	gen sec1d = int(naf2008/100)
	drop if sec1d==.
	recode sec1d (1/3 = 1) (5/39 = 2) (41/43 = 3) (45/56 = 4) (58/63 = 5) (64/66 = 6) (68 = 7) (69/82 = 8) (84/88 = 9) (90/99=10 ) , gen(sec_a10)
	label define A10 1 "Agriculture" 2 "Manufacturing & Extract." 3 "Construction" 4 "Retail" 5 "Info & Com" 6 "Finance" 7 "Real Estate" 8 "Services to Firms" 9 "Public" 10 "Other Services"
	label value sec_a10 A10

	*Variables for the match:
	rename (sbr_* nbheur_*) (sbr* nbheur*)
	gen sbrhour3 = sbr3/nbheur3
	gen sbrhour2 = sbr2/nbheur2
	* 281,488 missing values generated
	forvalues i = 2/3 {
	gen lnw_`i' = ln(sbr`i')
	gen lnh_`i' = ln(nbheur`i')
	gen lnhw_`i' = ln(sbrhour`i')
	}
		

	gen lnempclos = ln(empclos)
	gen lnnbsaent1 = ln(nbsa_ent1)
	gen lnnbsaent2 = ln(nbsa_ent2)
	gen lnempsize = ln(nbsa_ent1)

	*global Xmatch lnw_* lnh_* age_cl empclos_cl 
	*hours + hourly wage: 


	global Xmatch sbrhour2 sbrhour3 nbheur2 nbheur3 age_cl nbsa_ent1 
	 
	_pctile nbsa_ent2 if T==1, p(25 50 75)

	local q1 = r(r1)
	local q2 = r(r2)
	local q3 = r(r3)

	gen nbsaent2_q = .
	replace nbsaent2_q = 1 if nbsa_ent2 <= `q1' 
	replace nbsaent2_q = 2 if nbsa_ent2 > `q1' 
	replace nbsaent2_q = 3 if nbsa_ent2 > `q2' 
	replace nbsaent2_q = 4 if nbsa_ent2 > `q3'
		
	egen bin= group(sec_a10 nbsaent2_q)





	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*			MATCHING 

	*This is a loop over YEARS*SECTOR
	*That matches over the variable in $Xmatch
	*And produces a table of identifiers
	rename an_cl year_cl
	gen id = _n if T==0



	* CH 15/01/26: comment tempfile
	*tempfile match 

	*before 2004: tenure are not well observed. So I drop

	* CH 15/01/26: get 2004 out of the loop in order to save the firt temp_match file before doing the append in the 2005-2012 loop that comes next
	** 2004
		local i 2005
		disp `i'
		levelsof bin, local(L)
		foreach l in `L' {
			di "`i', `l'"
			qui count if T==1 & bin==`l' & year_cl==`i'
			*****preserve
			preserve
			if r(N)>0 & r(N)!=. {
			keep if bin==`l' & year_cl==`i'
			global matchnumber 8
			cap psmatch2 T $Xmatch if bin==`l' & year_cl==`i', n(${matchnumber})
			if _rc==0  {
				*identify pair control/treatd
				gen pair = _id if T==0
				replace pair = _n1 if T==1
				*for a pair: check C&T are in different firms
				bysort pair: egen double controlsir= max(sir_cl*[T==0])
				format controlsir %12.0g
				gen controldist = 1 if T==1
				*if they are not, use next potential control	
				forvalues X =2/${matchnumber} {			
				di "HERE IT IS : ANY REPLACE?"
					replace pair = _n`X' if T==1 & sir_cl==controlsir
					replace controldist = `X' if T==1 & sir_cl==controlsir
					drop controlsir
					bysort pair: egen double controlsir= max(sir_cl*[T==0])
					format controlsir %12.0g
					}
				gen samefirm = 0
				cap noisily assert sir_cl!=controlsir if T==1
					if _rc==1 replace samefirm = 1
				*keep only actual pairs
				bysort pair: gen nb = _N
				keep if nb>1
				*create an id that can be used after merging
				tostring pair, gen(pairid)
				replace pairid = pairid+"_`i'"+"_`l'"
				*measure distance in matching
				rename _pdif pdif 
				*keep it short, save aside, run again
				keep idfhda T year pairid controldist pdif samefirm _pscore
				*cap append using `match'
				*save `match', replace
				save "temp_match.dta", replace
				}
			}
			restore
		}

	*forvalues i = 2004/2012 {
	forvalues i = 2006/2012 {
		levelsof bin, local(L)
		foreach l in `L' {
			di "`i', `l'"
			qui count if T==1 & bin==`l' & year_cl==`i'
			*****preserve
			preserve
			if r(N)>0 & r(N)!=. {
			keep if bin==`l' & year_cl==`i'
			global matchnumber 8
			cap psmatch2 T $Xmatch if bin==`l' & year_cl==`i', n(${matchnumber})
			if _rc==0  {
				*identify pair control/treatd
				gen pair = _id if T==0
				replace pair = _n1 if T==1
				*for a pair: check C&T are in different firms
				bysort pair: egen double controlsir= max(sir_cl*[T==0])
				format controlsir %12.0g
				gen controldist = 1 if T==1
				*if they are not, use next potential control	
				forvalues X =2/${matchnumber} {			
				di "HERE IT IS : ANY REPLACE?"
					replace pair = _n`X' if T==1 & sir_cl==controlsir
					replace controldist = `X' if T==1 & sir_cl==controlsir
					drop controlsir
					bysort pair: egen double controlsir= max(sir_cl*[T==0])
					format controlsir %12.0g
					}
				gen samefirm = 0
				cap noisily assert sir_cl!=controlsir if T==1
					if _rc==1 replace samefirm = 1
				*keep only actual pairs
				bysort pair: gen nb = _N
				keep if nb>1
				*create an id that can be used after merging
				tostring pair, gen(pairid)
				replace pairid = pairid+"_`i'"+"_`l'"
				*measure distance in matching
				rename _pdif pdif 
				*keep it short, save aside, run again
				keep idfhda T year pairid controldist pdif samefirm _pscore
				/*
				cap append using `match'
				save `match', replace
				*/
				append using "temp_match.dta"
				save "temp_match.dta", replace
				
				}
			}
			restore

		}
	}

	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*			SAVE RELEVANT INFORMATION FOR MATCHES 

			**-- Recover matches
	*merge 1:1 idfhda T year_cl using `match', nogen keep(match)
	merge 1:1 idfhda T year_cl using "temp_match.dta", nogen keep(match)
	/*
		Result                      Number of obs
		-----------------------------------------
		Not matched                             0
		Matched                            29,495  
		-----------------------------------------
	*/
	*cap drop _*
		recast double sir sir_cl
		format sir sir_cl %12.0g

	tab samefirm T

	/*
			  |           T
	  samefirm |         0          1 |     Total
	-----------+----------------------+----------
			 0 |    14,661     14,834 |    29,495 
	-----------+----------------------+----------
		 Total |    14,661     14,834 |    29,495 

	*/
		
		
	bysort pairid: egen pairsize = nvals(idfhda)
		replace pairsize = pairsize-1
		label var pairid "Match: pair unique ID"
		label var pairsize "Match: pair nb of treated"
		label var controldist "Match: order of control (1/8)"


	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*			**THE END 

	save ./data/interim/lic_eco/le4_matchsize`s', replace

	* temp_match.dta : N = 29 495 obs.
	erase "temp_T.dta"
	erase "temp_match.dta"

}

/*END OF DOFILE*/
