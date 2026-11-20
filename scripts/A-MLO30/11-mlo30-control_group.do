/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
	
	Description: defines the control group
 
	-- I. Import potential individual from PANEL
	
	-- II. Compute matching variables: tenure, past wages, ZE and employment in t-1, sector, occupation
	
	-- III. Exclude the treated from the pool
	
	
	INPUT: 
		${workingdata}/PAN17_`i'.dta, i in 19942001 20022007 20082012 20132017 [fichiers du Panel DADS 2017 qui sont créés par le code SAS "Export_panel.sas" dans "2_Displaced/SAS_PanelDADS".] - used in part I.
		${workingdata}/pan_min.dta [created in 2_Displaced\2b_Panelmin.do] - used in part II.
		${workingdata}/sirenze.dta [created in 1_Closures\40_CreateNewPanel.do] - used in part II.
		${miscdata}/naf2003_naf2008.dta [crosswalk between NAF 2003 and 2008] - used in part II.
		${miscdata}/01_AUZE_Commune.dta [list of municipalities and employment zones, from INSEE] - used in part II.
		
		${workingdata}/treatedpan.dta [panel of treated individuals (MLO 90), defined in 2_Displaced\2_DispSample.do] - used in part II.
		
	INTERMEDIATE FILES:
		 ${workingdata}/ctrpool_pan_`i'.dta - i in 19942001 20022007 20082012 20132017
		 ${workingdata}/ctrpoolpantemp.dta
	
	OUTPUT: ${workingdata}/ctrpoolpan.dta [pool of workers who are potential controls (panel)]
 

 
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

*SETUP*
clear

*__________________________________________________*
	** -- I. Import potential individual


foreach i in 19942001 20022007 20082012 20132019 {
	use nninouv an AGE SIR SX dept COMT APET apet2 CS2 NBHEUR NBSA_ENT NBSA_ET NIC4 SBR entsir DEBREMU FINREMU filtre CATJUR if filtre=="1" & NBHEUR>0 & !missing(NBHEUR) using "./data/external/sas_paneldads/PAN19_`i'", clear
	rename *, lower
	gen init_an = an //PW 12022026: We want to check if control and treatment years are the same

	*Keep firms in CATJUR = private firm
	cap destring catjur, replace
	recode catjur (3100/3199=0) (5000/5999=0) (6200/6299=0) (6900/6999=0) (min/max=1) , gen(todrop)
	drop if todrop==1
	drop todrop

	*Keep only 1 obs at main employer
	keep if nbheur!=. & nbheur>0
	bysort nninouv: egen rankhour = rank(-nbheur)
		drop if rankhour>1

	
	*Restriction at FIRM level
	*keep if nbsa_ent>=50 - PW 1202206: let's get rid of that!

	*Restriction at INDIV level
	keep if age>19 & age<51

	keep nninouv an init_an age sir sx dept comt apet apet2 cs2 nbheur nbsa_ent nbsa_et nic4 sbr entsir debremu finremu
	
	destring sir, force replace
		drop if sir==.
		
	save ./data/interim/mlo30/ctrpool_pan_`i'.dta, replace
	
}

*__________________________________________________*
	** -- II. Compute matching variables

	** --1. Tenure	
cap erase ./data/interim/mlo30/ctrpoolpantemp.dta
foreach i in 20022007 20082012 20132019 {
	use ./data/interim/mlo30/ctrpool_pan_`i'.dta, clear
	merge 1:1 nninouv sir an using ./data/interim/mlo30/pan_min, keep(master matched) nogen  keepusing(min_an_sir max_an_sir)
	
	gen tenure = an-min_an_sir+1
	keep if tenure>=3

	gen forward_tenure = max_an_sir - an
	
	cap append using ./data/interim/mlo30/ctrpoolpantemp.dta
	save ./data/interim/mlo30/ctrpoolpantemp.dta, replace
	}


** --2. Past wages	
use ./data/interim/mlo30/ctrpoolpantemp.dta, clear
format sir %12.0g
drop dept comt
rename (sbr nbheur debremu finremu nbsa_ent) (sbr0 nbheur0 debremu0 finremu0 nbsa_ent0)
replace an = an-3	
merge 1:1 nninouv an sir using ./data/interim/mlo30/pan_min.dta, keep(master match) nogen keepusing(nbheur debremu finremu contrat_travail sbr nbsa_ent)
gen double sir_3 = .
format sir sir_3 %12.0g
replace sir_3=sir
rename (sbr nbheur debremu finremu nbsa_ent) (sbr_3 nbheur_3 debremu_3 finremu_3 nbsa_ent_3)
replace an = an+1
merge 1:1 nninouv an sir using ./data/interim/mlo30/pan_min.dta, keep(master match) nogen keepusing(nbheur debremu finremu contrat_travail sbr nbsa_ent)
gen double sir_2 = .
format sir sir_2 %12.0g
replace sir_2=sir
rename (sbr nbheur debremu finremu nbsa_ent) (sbr_2 nbheur_2 debremu_2 finremu_2 nbsa_ent_2)
replace an = an+1
merge 1:1 nninouv an sir using ./data/interim/mlo30/pan_min.dta, keep(master match) nogen keepusing(nbheur debremu finremu contrat_travail sbr dept comt nbsa_ent)
gen double sir_1 = sir
format sir sir_2 sir_1 %12.0g
rename (sbr nbheur debremu finremu nbsa_ent sbr0 nbheur0 debremu0 finremu0 nbsa_ent0) (sbr_1 nbheur_1 debremu_1 finremu_1 nbsa_ent_1 sbr nbheur debremu finremu nbsa_ent)
replace an = an+1	


** --3. ZE	and Employment at t-1
gen com = dept+comt
destring com, gen(insee) force
merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(matched) nogen keepusing(ze10)

tostring ze10, gen(sirenze)
tostring sir_1, gen(siren)
replace siren = "0"+siren if length(siren)==9
	replace nic = "0"+nic if length(nic)==5
	replace nic = "00"+nic if length(nic)==4
	replace sirenze = siren+"-"+sirenze

replace an = an-1
merge m:1 sirenze an using ./data/interim/mlo30/sirenze_full.dta, keep(master match) nogen keepusing(emp)
rename emp empclos_cl
replace an = an+1


*Occup
destring cs2, replace 

*Sector
rename apet naf2003
	merge m:1 naf2003 using ./data/external/naf2003_naf2008.dta, keep(master match) nogen
	replace apet2=substr(apet2,1,4) if length(apet2)==5
	replace naf2008=apet2 if naf2008=="" & apet2!=""
	destring naf2008, replace force
	drop apet* naf2003

rename (age an tenure cs2 naf2008) (age_cl year_cl tenure_cl occup_cl naf2008_cl)
destring sx, replace
	
gen T=0 
	
*__________________________________________________*
	** -- III. Exclude the treated from the pool

keep if tenure>=3
	
merge m:m nninouv using ./data/interim/mlo30/treatedpan, keepusing(nninouv)
	tab _m
	drop if _m!=1
	drop _m


save ./data/interim/mlo30/ctrpoolpan.dta, replace
cap erase ./data/interim/mlo30/ctrpoolpantemp.dta

/*END OF DOFILE*/
