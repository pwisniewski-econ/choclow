/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  DESCRIPTION: Creates a pool of potential control workers
	I. Import potential individual
	II. Compute matching variables
	III. Exclude the treated from the pool
	
  INPUT: 
	${choclowdata}/FHDADS/fhdads_`i' [i = 2002/2012]
	
	${workingdata}/03_tmp_fh [created in 3_LE\3a_ControlPanelFH]
	${miscdata}\01_AUZE_Commune.dta
	${workingdata}/sirenze.dta [created in 1_Closures\40_CreateNewPanel.do]
	${miscdata}/naf2003_naf2008.dta
	
	ATTENTION:
	${workingdata}\le3_treated_dads.dta [full panel for LE workers, created in 3_LE\3_LEallyears.do] (plutôt que ${workingdata}/treated.dta A VERIFIER)
	=> NB CH 12/01/26: le dofile suivant (3_LE\4_Match_SIZE.do) utilise le3_treated_dads.dta, ce qui suggère que c'est effectivement le bon .dta  
		  
		 
  Intermediate data, used here, not declared as project data:
	${workingdata}/ctrpool_`i'.dta
	${workingdata}/ctrpooltemp.dta
	
	
  OUTPUT: ${workingdata}\ctrpool.dta [Pool of potential controls for LE workers]
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
clear

*__________________________________________________*
	** -- I. Import potential individual
	

forvalues i = 2002/2012 {
use "./data/external/fhdads/fhdads_`i'", clear

*Keep firms in CATJUR = private firm
cap destring catjur, replace
recode catjur (3100/3199=0) (5000/5999=0) (6200/6299=0) (6900/6999=0) (min/max=1) , gen(todrop)
drop if todrop==1
drop todrop

*Keep only 1 obs at main employer
keep if nbheur!=. & nbheur>0
bysort idfhda: egen rankhour = rank(-nbheur)
	drop if rankhour>1

	
*Restriction at FIRM level
keep if nbsa_ent>=1

*Restriction at INDIV level
keep if age>19 & age<51

keep idfhda an age sir sx dip_tot dept comt apet apet2 cs2 nbheur nbsa_ent nbsa_et nic4 sbr entsir debremu finremu

save ./data/interim/lic_eco/ctrpool_`i'.dta, replace
	}

*/	
*__________________________________________________*
	** -- II. Compute matching variables
	
	** --1. Tenure	
cap erase ./data/interim/lic_eco/ctrpooltemp.dta
forvalues i = 2002/2012 {
	use ./data/interim/lic_eco/ctrpool_`i'.dta, clear
	merge 1:1 idfhda sir an using "./data/interim/lic_eco/00_fhdads_tenure.dta", keep(master matched) nogen keepusing(min_an_sir)
	
	gen tenure = an-int(min_an_sir)+1 
	keep if tenure>=3

	cap append using ./data/interim/lic_eco/ctrpooltemp.dta
	save ./data/interim/lic_eco/ctrpooltemp.dta, replace
	}
	*/

** --2. Past wages	
use ./data/interim/lic_eco/ctrpooltemp.dta, clear

destring sir, force replace
	drop if sir==.
	
format sir %12.0g
drop dept comt
rename (sbr nbheur debremu finremu nbsa_ent) (sbr0 nbheur0 debremu0 finremu0 nbsa_ent0)
replace an = an-3	
merge 1:1 idfhda an sir using ./data/interim/lic_eco/03_tmp_fh.dta, keep(master match) nogen keepusing(nbheur debremu finremu contrat_travail sbr nbsa_ent)
gen double sir_3 = .
format sir sir_3 %12.0g
replace sir_3=sir
rename (sbr nbheur debremu finremu nbsa_ent) (sbr_3 nbheur_3 debremu_3 finremu_3 nbsa_ent_3)
replace an = an+1
merge 1:1 idfhda an sir using ./data/interim/lic_eco/03_tmp_fh.dta, keep(master match) nogen keepusing(nbheur debremu finremu contrat_travail sbr dept comt nbsa_ent)
gen double sir_2 = sir
format sir sir_3 sir_2 %12.0g
rename (sbr nbheur debremu finremu nbsa_ent) (sbr_2 nbheur_2 debremu_2 finremu_2 nbsa_ent_2)
replace an = an+1	
merge 1:1 idfhda an sir using ./data/interim/lic_eco/03_tmp_fh.dta, keep(master match) nogen keepusing(nbheur debremu finremu contrat_travail sbr dept comt nbsa_ent)
gen double sir_1 = sir
format sir sir_3 sir_2 sir_1 %12.0g
rename (sbr nbheur debremu finremu nbsa_ent sbr0 nbheur0 debremu0 finremu0 nbsa_ent0) (sbr_1 nbheur_1 debremu_1 finremu_1 nbsa_ent_1 sbr nbheur debremu finremu nbsa_ent)
replace an = an+1	


** --3. ZE	
gen com = dept+comt
destring com, gen(insee) force
merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(matched) nogen keepusing(ze10)

tostring ze10, gen(sirenze)
tostring sir, gen(siren)
replace siren = "0"+siren if length(siren)==9
	replace nic = "0"+nic if length(nic)==5
	replace nic = "00"+nic if length(nic)==4
	replace sirenze = siren+"-"+sirenze

replace an = an-1
merge m:1 sirenze an using ./data/interim/sirenze_full, keep(master match) nogen keepusing(emp*)
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
destring sx dip_tot, replace
	
gen T=0 
	
*__________________________________________________*
	** -- III. Exclude the treated from the pool
	
** /!\ CH - 08/01/2026: where does come from ???
** Bad news: Notepad++ says:
** C:\Users\Public\Documents\Layoffs\archive\old_Displaced_FHandPanel\2_DispSample.do (1 hit)
** Line 189: save ${workingdata}/treated, replace	

** Exploration avec Clément :
** a priori il faut utiliser ${workingdata}\le3_treated_dads.dta qui est généré dans 3_LEallyears.do
** c'est ce dta qui donne les individus LE (avec leurs infos DADS)

** ATTENTION merge m:m ??? A vérifier

* Code original:
* merge m:m idfhda using ${workingdata}/treated, keepusing(idfhda)
* Code modifié (14/01/2026)
merge m:m idfhda using ./data/interim/lic_eco/le3_treated_dads, keepusing(idfhda)

	tab _m
	drop if _m!=1
	drop _m

	
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
		
save "./data/interim/lic_eco/ctrpool.dta", replace
cap erase "./data/interim/lic_eco/ctrpooltemp.dta"

/*END OF DOFILE*/
