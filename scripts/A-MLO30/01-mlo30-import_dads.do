*SETUP*
clear
global period_0 = 1993
global period_0b = $period_0 +1
global period_a = 2002
global period_b = $period_a +1
global period_c = 2015
global sample= 100
set seed 11091989

*1.
*Importing SIRET for each year + Merging
forvalues i=$period_0 / $period_c {
display `i'

tempfile siret_`i'
use "./data/external/sas_etablissements/DADS`i'_nov.dta" , clear
rename *, lower
// SAS establishment geography names changed in 2002.
if `i' >= 2002 {
    rename (dept comt) (dep com)
}

gen obs_postes`i' = (total>0) if total!=.

keep siren nic dep com apet obs_postes`i' catjur total_pos
rename (dep com apet total_pos) (dep`i' com`i' apet`i' emp`i')

capture destring catjur, replace
recode catjur (3100/3199=0) (5000/5999=0) (6200/6299=0) (6900/6999=0) (min/max=1) , gen(todrop)
gen tempw = int(emp)
tab todrop [fw=tempw]
drop if todrop==1
drop todrop tempw catjur

duplicates report siren nic
duplicates drop siren nic, force

replace siren = "0"+siren if length(siren)==9
replace nic = "0"+nic if length(nic)==5
replace nic = "00"+nic if length(nic)==4

replace com = dep+substr(com,-3,3)

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
merge 1:1 siren nic using `siret_`i''
	drop _merge
}

gen deb = .
forvalues i=$period_0 / $period_c {
	replace deb=`i' if emp`i'!=. & deb==.
	}
gen fin = .
forvalues i=$period_0 / $period_c {
	replace fin=`i' if emp`i'==. & fin==. & `i'>deb
	replace fin= .  if emp`i'!=. & `i'>=fin
	}


*Any firm observed with 0 employment:
*has 0 employed on eff 31.12 (but did have some during the year)
tabstat obs*, col(s) s(mean sd)
drop obs*


*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

save "./data/interim/mlo30/temp_AllSiret_$sample.dta" , replace

/*END OF DOFILE*/
