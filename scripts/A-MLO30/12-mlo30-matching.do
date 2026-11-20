/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
	
	Description: Performs the matching between treated individuals and closest individuals in the panel of potential controls
 
	-- I. Import pool of controls + treatedpan
			Treated individuals are excluded from the pool of potential controls
			exclude workers who have irrelevant characteristics (e.g. nb hours in the past 2 years < 1800 ; age < 25 or > 60)
			Work at sector x year level
	
	-- II. Performs the matching
		Matching on observables is done within bins of sec_a10 (industry in 10 categories) and sizecat (firm size in 4 categories)
		Propensity score matching on the following set of variables: $Xmatch = sbrhour1 sbrhour2 nbheur1 nbheur2 age_cl nbsaent1 
		If treated and closest control worker are in the same firm, use the second best match
	
	-- III. Save relevant information for matches
	
	
	INPUT:
		${workingdata}/ctrpoolpan.dta [pool of workers who are potential controls (panel), defined in 2_Displaced\3_ControlGroup.do]
		${workingdata}/treatedpan.dta [panel of treated individuals (MLO 90), defined in 2_Displaced\2_DispSample.do]
	
	OUTPUT: ${workingdata}/disppan_matchSIZE2.dta [panel of displaced workers and their associated controls]
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

*SETUP*
clear

*__________________________________________________*
	** -- I. Import pool of controls + treatedpan

foreach s in 1 2 {
	
	use "./data/interim/mlo30/ctrpoolpan.dta" if !mi(nbheur_1) & !mi(nbheur_2) & !mi(nbheur_3) & !mi(nbsa_ent_2), clear //& nbheur_2>=1800 
	
	if `s'==1{
		keep if forward_tenure >=6
	}
	
	keep nninouv T year_cl init_an empclos_cl tenure_cl naf2008_cl age_cl year_cl occup_cl sir nbheur* sx sbr*  age debremu* finremu* nbsa_ent*
	rename sir sir_cl

	append using "./data/interim/mlo30/treatedpan.dta" 

	keep if !mi(nbheur_1) & !mi(nbheur_2) & !mi(nbheur_3) & !mi(nbsa_ent_2)
	keep if nbheur_1>0 & nbheur_2>0 & nbheur_3>0

	
	
			**-- Verify selection rules
	*I exclude treatedpan from the pool of potential controls
	bysort nninouv: egen dup = max(T)
	drop if dup==1 & T==0
	drop dup

	*I verify number of hours
	rename (sbr_* nbheur_* nbsa_ent_*) (sbr* nbheur* nbsaent*)
	*drop if nbheur1<1800
	*drop if nbheur2<1800


	*I verify age
	drop if age_cl<20
	drop if age_cl>50



	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

		** -- I. I work at sector * year level	

	gen sec1d = int(naf2008/100)
	drop if sec1d==.
	recode sec1d (1/3 = 1) (5/39 = 2) (41/43 = 3) (45/56 = 4) (58/63 = 5) (64/66 = 6) (68 = 7) (69/82 = 8) (84/88 = 9) (90/99=10 ) , gen(sec_a10)
	label define A10 1 "Agriculture" 2 "Manufacturing & Extract." 3 "Construction" 4 "Retail" 5 "Info & Com" 6 "Finance" 7 "Real Estate" 8 "Services to Firms" 9 "Public" 10 "Other Services"
	label value sec_a10 A10

	gen sbrhour2 = sbr2/nbheur2
	gen sbrhour3 = sbr3/nbheur3
	drop if sbrhour3==.
	forvalues i = 2/3 {
	gen lnw_`i' = ln(sbr`i')
	gen lnh_`i' = ln(nbheur`i')
	gen lnhw_`i' = ln(sbrhour`i')
	}

	gen lnempclos = ln(empclos)
	gen lnnbsaent1 = ln(nbsaent1)
	gen lnnbsaent2 = ln(nbsaent2)

	gen lnempsize = ln(nbsaent1)

	*global Xmatch lnw_* lnh_* age_cl empclos_cl 
	*hours + hourly wage: 
	global Xmatch  sbrhour2 sbrhour3 nbheur2 nbheur3 age_cl nbsaent2
		 
	_pctile nbsaent2 if T==1, p(25 50 75)
	
	local q1 = r(r1)
	local q2 = r(r2)
	local q3 = r(r3)
	
	gen nbsaent2_q = .
	replace nbsaent2_q = 1 if nbsaent2 <= `q1' 
	replace nbsaent2_q = 2 if nbsaent2 > `q1' 
	replace nbsaent2_q = 3 if nbsaent2 > `q2' 
	replace nbsaent2_q = 4 if nbsaent2 > `q3'
		
	egen bin= group(sec_a10 nbsaent2_q)

	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*MATCHING
	tempfile match 
	gen id = _n if T==0
	*before 2004: tenure are not well observed. So I drop
	summ year_cl
	forvalues i = 2004/`r(max)' { //`r(max)'
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
				keep nninouv T year pairid controldist pdif samefirm _pscore
				cap append using `match'
				save `match', replace
				}
			}
			restore
		}
	}



	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*			SAVE RELEVANT INFORMATION FOR MATCHES 

			**-- Recover matches
	merge 1:1 nninouv T year_cl using `match', nogen keep(match)
		//cap drop _*
		recast double sir sir_cl
		format sir sir_cl %12.0g

	tab samefirm T

	bysort pairid: egen pairsize = nvals(nninouv)
		replace pairsize = pairsize-1
		label var pairid "Match: pair unique ID"
		label var pairsize "Match: pair nb of treatedpan"
		label var controldist "Match: order of control (1/6)"
		
	*______________________________________________________________________________*
	*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	*			**THE END 
		

	save "./data/interim/mlo30/disppan_matchSIZE`s'.dta", replace
	
}
	


/*END OF DOFILE*/
