/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  Description: Creates a panel of displaced workers (treatedpan.dta)
  
	-- I. Find individuals employed in firm at time of closure
	
	-- II. Individuals criteria: gets back the prior and future characteristics of individuals in firm at closure
	
	-- III. Basic selection: select workers with the following characteristics:
		- worked full time over [t-2;t-1] (not [t-1;t] because of shaow of death)
		- long-tenure: were there 3 years ago 
		- age: age>24 & age<61
		- Not present in future
		- Keep only the first layoff
		- there is 1 individual with 2 layoffs same year... Keep main emp

	-- IV. Save: panel of displaced workers
	
	
	INPUT:
		${workingdata}\04_events_fh.dta [created in 1_Closures\32_Picart.do] - used in part I.
		${workingdata}\pansmall_main.dta [created in 2_Displaced\1_SmallPanel.do] - used in part I.
		${workingdata}\pan_min.dta [created in 2_Displaced\2b_Panelmin.do] - used in part II.
		${miscdata}\naf2003_naf2008.dta [crosswalk between NAF 2003 and 2008] - used in part IV.
			
	INTERMEDIATE DATA (not declared in the project): 
		${workingdata}\disppandads_mlo30.dta [displaced panel merged with DADS = individuals in firm at closure] - created in part I. and used in part II.
	
	OUTPUT:
		${workingdata}\treatedpan.dta [panel of treated individuals (MLO 90)]
  
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
*SETUP*
clear

		**-- I. Individuals in firm at closure 

		
*1. I prepare the list of events for matching with DADS
use ./data/interim/mlo30/events_fh.dta

gen an = year
split sirenze, p("-")
	rename (sirenze1 sirenze2) (sir ze10)
	destring sir ze10, replace

tempfile temp
	save `temp'

*2. I keep from DADS individuals in the place at time of closure

*do 1_SmallFH

cap erase ./data/interim/mlo30/disppandads.dta
forvalues i = 2002/2012 {
	use ./data/interim/mlo30/pansmall_main.dta if an==`i'
	gen init_an = an //PW 12022026: We want to check if control and treatment years are the same
	merge m:1 an sir ze10 using `temp', keep(matched) nogen

	cap append using ./data/interim/mlo30/disppandads.dta
	save ./data/interim/mlo30/disppandads.dta, replace
	}



*________________________________________________
		
		**-- II. Individuals criteria 

*1. Get many data 		
*(old but gold do file for tenure)
*do 2b_Panelmin.do


***IMPORTANT
*We are interested by all workers that worked in firm f during t-1 if firm closes in year t
*In the data "an" is year t-1; empclos is the number of workers at the end of t-1; emppos at the end of year t

*So I start at t-1



use ./data/interim/mlo30/disppandads.dta, replace
	label var empclos "Workforce end of year t-1"
	label var emploss "Delta Workford (t-1, t)"
	label var emppos "Workforce end of year t"
keep nninouv an init_an sir ze10 sx empclos emploss emppos
*t-1
*replace an = an -1
merge 1:m nninouv an sir using  "./data/interim/mlo30/pan_min.dta", keep(master match) nogen keepusing(nbheur finremu contrat_travail sbr annai nbsa_ent)
rename (nbheur finremu contrat_travail sbr annai nbsa_ent) (nbheur_1 finremu_1 contrat_travail_1 sbr_1 annai_1 nbsa_ent_1)
replace nbheur_1 = 0 if nbheur_1==.
*t-2
replace an = an -1
merge 1:m nninouv an sir using  "./data/interim/mlo30/pan_min.dta", keep(master match) nogen keepusing(nbheur finremu contrat_travail sbr nbsa_ent)
rename (nbheur finremu contrat_travail sbr nbsa_ent) (nbheur_2 finremu_2 contrat_travail_2 sbr_2 nbsa_ent_2)
replace nbheur_2 = 0 if nbheur_2==.
*t-3
replace an = an -1
merge 1:m nninouv an sir using  "./data/interim/mlo30/pan_min.dta", keep(master match) nogen keepusing(nbheur finremu contrat_travail sbr nbsa_ent)
rename (nbheur finremu contrat_travail sbr nbsa_ent) (nbheur_3 finremu_3 contrat_travail_3 sbr_3 nbsa_ent_3)
replace nbheur_3 = 0 if nbheur_3==.
*t+1
*replace an = an +3
*merge 1:1 nninouv an sir using ./data/interim/mlo30/pan_min.dta, keep(master match) nogen keepusing(nbheur debremu finremu sbr)
*rename (nbheur debremu finremu sbr) (nbheur_p1 debremu_p1 finremu_p1 sbr_p1)
*t
replace an = an +3
merge 1:1 nninouv an sir using  "./data/interim/mlo30/pan_min.dta", keep(master match) nogen
replace annai=annai_1+1
drop annai_1

/*gen event = finremu 
hist event
replace event = finremu_p1 if finremu_p1!=.
hist event
summ sbr sbr_p1 nbheur nbheur_p1 
*/


*2. Keep conditions
*Tenure
*Careful because info <2002 is only for subsample
*so I recommend apply a rule from 2004 on...
gen tenure = an-min_an_sir+1 
	
*Age
gen age = an-annai-1

*Fulltime
gen cont_full_1 = (nbheur_1>=1820)
gen cont_full = (nbheur>=1820)
label var cont_full_1 "Caution before 2003"
label var cont_full "Caution before 2003"

*Contract
*Contrat is first observed in 2005.
gen cont_cdi_1=(contrat_travail_1=="01") if an>=2006
gen cont_cdi=(contrat_travail=="01") if an>=2006
label var cont_cdi_1 "Caution before 2006"
label var cont_cdi "Caution before 2006"

*Expost presence: (needed to make sure people are not employed in closing plant at t+1 or t+2)
rename (nbheur finremu) (nbheur0 finremu0)
*t+1
replace an = an +1
merge 1:1 nninouv an sir ze10 using  "./data/interim/mlo30/pan_min.dta", keep(master match) nogen keepusing(nbheur finremu)
replace nbheur=0 if nbheur==.
rename (nbheur finremu) (nbheur1 finremu1)
*t+2
replace an = an +1
merge 1:1 nninouv an sir ze10 using  "./data/interim/mlo30/pan_min.dta", keep(master match) nogen keepusing(nbheur)
replace nbheur=0 if nbheur==.
rename (nbheur nbheur0) (nbheur2 nbheur)
gen presen1 = (nbheur1>0 & nbheur1!=.)
gen presen2 = (nbheur2>0 & nbheur2!=.)
replace an = an-2


*________________________________________________
		
		**-- III. Basic selection
*Full time: Worked full time [t-2;t-1]
*I don't take [t-1;t] because shadow of death
	tabstat nbheur_1 nbheur nbheur1 nbheur2
	tabstat nbheur_1 nbheur nbheur1 nbheur2 if nbheur_1>1800
	drop nbheur1 nbheur2


	
	
*Tenure= Was there 3 years ago
tab tenure 
keep if tenure>=3

	
*Age:
tab age
keep if age>19 & age<51	

*Not present in future
drop if finremu1>330 & finremu1!=.
drop if presen2==1

*Keep only the first layoff
bysort nninouv: egen first = min(an)
	drop if an>first
*there 1 individual with 2 layoffs same year... Keep main emp
bysort nninouv an: egen first2 = rank(-sbr_1)	
	drop if first2>1
	drop first*

		

*________________________________________________
		
		**-- IV. Save
keep nninouv an init_an sir ze10 age tenure cont_full* cont_cdi* sbr* nbheur* empclos sx nbsa_ent*

*add info on CS and NAF:
replace an = an-1
merge 1:m nninouv an sir using "./data/interim/mlo30/pansmall.dta", keep(master match) nogen keepusing(apet apet2 cs2)
	duplicates tag nninouv an sir, gen(t)
	assert t==0
	drop t

	replace an = an+1
	
	destring cs2, gen(occup)
	destring sx, replace

	rename apet naf2003
	merge m:1 naf2003 using ./data/external/naf2003_naf2008.dta, keep(master match) nogen
	replace apet2=substr(apet2,1,4) if length(apet2)==5
	replace naf2008=apet2 if naf2008=="" & apet2!=""
	destring naf2008, replace force
	
*clean up	
rename an year
rename * *_cl
rename (sbr*_cl nbheur*_cl nbsa_ent*_cl) (sbr* nbheur* nbsa_ent*)
rename nninouv nninouv
gen T = 1

save ./data/interim/mlo30/treatedpan.dta, replace	

/*END OF DOFILE*/
