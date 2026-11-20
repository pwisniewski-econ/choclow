*SETUP*
clear
// Run from the project root, as set by master.R.

/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  Description = Paul's notes:
	- Since we now use matching, I have to create a new panel of sirenze that is measured
	irrelevant of potential closure;
	- I only need a number of employees per siren*ze*year
	
  Note de CH, 19/12/2025 : le fichier en Output (sirenze.dta) est utilisé dans la définition du groupe de contrôle dans "2_Displaced\3_ControlGroup.dta"
	
  INPUT: 
	 "${sasetab}\DADS`i'_exh.dta" [All exhaustive DADS files from 2000 to 2015]
	 "${miscdata}\01_AUZE_Commune.dta" [list of municipalities and employment zones, from INSEE]

  OUTPUT: 
	"${workingdata}/sirenze.dta" [Panel of siren x ze]
		
  __________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

cap erase ./data/interim/mlo30/sirenze_full.dta

forvalues i = 2000/2015 {

use "./data/external/sas_etablissements/DADS`i'_exh", clear
rename *, lower
// SAS establishment geography names changed in 2002.
if `i' >= 2002 {
    rename (dept comt) (dep com)
}

duplicates drop siren nic, force

replace siren = "0"+siren if length(siren)==9
	replace nic = "0"+nic if length(nic)==5
	replace nic = "00"+nic if length(nic)==4

replace com = dep+substr(com,-3,3)

destring com, gen(insee) force
qui merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(master matched) nogen keepusing(ze10 libze10)
	order *ze*, after(dep)
	bysort ze10: egen temp = mode(libze)
	replace libze=temp if libze==""
	drop temp

*When the commune code is wrong:
drop if ze==.

*Sirenze
tostring ze10, gen(sirenze)
	replace sirenze = siren+"-"+sirenze
destring siren, gen(sir) force

keep sirenze sir ze10 total
gcollapse (sum) emp`i'=total , by(sirenze)


cap noisily merge 1:1 sirenze using ./data/interim/mlo30/sirenze_full.dta, nogen
save ./data/interim/mlo30/sirenze_full.dta, replace
}


reshape long emp, i(sirenze) j(an)
drop if emp==0 | emp==.
save ./data/interim/mlo30/sirenze_full.dta, replace

/*END OF DOFILE*/
