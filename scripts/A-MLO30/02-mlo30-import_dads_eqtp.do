*SETUP*
clear
global period_0 = 1993
global period_0b = $period_0 +1
global period_a = 2002
global period_b = $period_a +1
global period_c = 2015
global sample= 100
set seed 11091989


/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  Description: 
	- Imports SIRET for each year from the exhaustive version of DADS, and merges all years.
	- Computes full time equivalent nb of workers
		
	
  INPUT: 
	 "${sasetab}\DADS`i'_exh.dta" [All exhaustive DADS files from 1993 to 2015]
  
  OUTPUT:
	${workingdata}/temp_ETP.dta

  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
  
global period_0 1993
global period_0b =$period_0 +1
global period_a 2002
global period_b 2003
global period_c 2015

*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

*1.
*Importing SIRET for each year + Merging
forvalues i=$period_0 / $period_c {
display `i'

tempfile siret_`i'
use "./data/external/sas_etablissements/DADS`i'_exh.dta" , clear
rename *, lower
// SAS establishment geography names changed in 2002.
if `i' >= 2002 {
    rename (dept comt) (dep com)
}

capture gen total_eqtc = total_nbheur/2028 if `i'==1993
capture rename total_nbheur total_h

keep siren nic dep com catjur total_eqtc total_h
rename (dep com total_eqtc total_h) (dep`i' com`i' etp`i' hour`i')

capture destring catjur, replace
recode catjur (3100/3199=0) (5000/5999=0) (6200/6299=0) (6900/6999=0) (min/max=1) , gen(todrop)
	/*gen tempw = int(etp)
	tab todrop [fw=tempw]
	drop tempw*/
	drop if todrop==1
	drop todrop catjur

replace siren = "0"+siren if length(siren)==9
replace nic = "0"+nic if length(nic)==5
replace nic = "00"+nic if length(nic)==4

replace com = dep+substr(com,-3,3)

duplicates report siren nic
duplicates drop siren nic, force

save `siret_`i''
}

/*Catjur
*31 : personne morales de droit étrangé immatriculé au RCS 
*5- : sociétés commerciales (toute cat.)
*62: groupement d'intérêt économique (immat au RCS)
*69: autre personne de droit privé immatriculé au RCS

*non inclus ici
1: entreprise indiv (non)
	11 artisant commercant
	12 comercant
	13 artisant
99: autre personne morale de droit privé
*/

use `siret_${period_0}', clear
forvalues i=$period_0b / $period_c {
display `i'
merge 1:1 siren nic using `siret_`i''
	drop _merge
}


*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

save "./data/interim/mlo30/temp_ETP.dta" , replace

/*END OF DOFILE*/