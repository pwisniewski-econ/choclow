/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  Description: To be checked : creates a "small" panel from Panel DADS 2000 (??? why?) to 2017, only for main jobs
	
  INPUT: 
	"${workingdata}/PAN17_`i'.dta", i in 19942001 20022007 20082012 20132017 [fichiers du Panel DADS 2017 qui sont créés par le code SAS "Export_panel.sas" dans "2_Displaced/SAS_PanelDADS".]
	"${miscdata}\01_AUZE_Commune.dta" [list of municipalities and employment zones, from INSEE]
  
  
  INTERMEDIATE FILE (not declared as a project file): 
	"${workingdata}/pansmall.dta" [panel DADS from 1994 to 2017, only for obs with filtre=="1" and positive nb of hours worked] % NB: I thought the variable was FILT, what is filtre ?? à vérifier).
  
  
  OUTPUT: 
	"${workingdata}/pansmall_main.dta" [Panel for main jobs only? ATTENTION : ici on est seulement à partir de 2000 ???]
	
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
  
*SETUP*
clear

cap erase ./data/interim/mlo30/pansmall.dta

foreach i in 19942001 20022007 20082012 20132019 {
	use nninouv SX an SIR SBR NBHEUR DEBREMU FINREMU CS2 dept COMT depr COMR APET apet2 entsir AGE NIC4 CATJUR NBSA_ET NBSA_ENT filtre if filtre=="1" & NBHEUR>0 & !missing(NBHEUR) using "./data/external/sas_paneldads/PAN19_`i'", clear
	rename *, lower
	drop filtre
	
	destring sir, replace force
*		drop if sir==.
			
	gen com = dept+comt
	destring com, gen(insee) force
	merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(master matched) nogen keepusing(ze10)

	drop com insee
	
	cap append using ./data/interim/mlo30/pansmall.dta
	save ./data/interim/mlo30/pansmall.dta, replace 
	}
	

		**-- 1 Info on main jobs only.
cap erase./data/interim/mlo30/pansmall_main.dta
global tokeep nninouv an comt sbr nbheur sir entsir sx ze10

forvalues i = 2000 /2019 {
use ./data/interim/mlo30/pansmall.dta if an==`i', clear

bysort nninouv: gen temp =_N
bysort nninouv: egen main = rank(-sbr)

drop if temp>1 & main!=1
duplicates report nninouv
drop temp main

keep $tokeep
cap append using ./data/interim/mlo30/pansmall_main.dta
save ./data/interim/mlo30/pansmall_main.dta, replace
} 

/*END OF DOFILE*/
