cap erase ./data/_tmp/siren_outcomes.dta

foreach i in 19942001 20022007 20082012 20132019 {

	use an nninouv SX AGE ANNAI SIR dept COMT CS2 NBHEUR SBR CATJUR FINREMU if NBHEUR>0 & !missing(NBHEUR) using "./data/external/sas_paneldads/PAN19_`i'", clear
	rename *, lower

	gen one = 1 if finremu == 360
	drop finremu
	
	*Keep firms in CATJUR = private firm
	cap destring catjur, replace
	recode catjur (3100/3199=0) (5000/5999=0) (6200/6299=0) (6900/6999=0) (min/max=1) , gen(todrop)
	drop if todrop==1
	drop todrop

	gen cs1 = substr(cs2, 1, 1)
	
	gen com = dept+comt
	destring com, gen(insee) force
	merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(master matched) nogen keepusing(ze10)

	gen siren = sir
	destring sir, replace force
	merge m:1 an nninouv sir using  "./data/interim/mlo30/mlo30_tenure.dta", keep(master match) nogen keepusing(min_an_sir)
	gen tenure = an - min_an_sir + 1
	
	replace tenure = . if an < 2002 & mod(annai, 2)==1 //before 2002 tenure is only observed for 1/24 of our sample	
	
	destring sx, replace force

	foreach v of varlist sx age sbr tenure {
		gen nbheur_`v' = nbheur
		replace nbheur_`v' = . if missing(`v')
		gen `v'_nb = `v' * nbheur
	}
	
	collapse (sum) n=one nbheur* *_nb, by(ze10 an siren sir cs1)
	bysort an ze10 cs1: egen total_zecs1 = total(nbheur)
	gen hhi_comp = (nbheur / total_zecs1)^2 
	replace hhi_comp = . if missing(ze)

	cap append using ./data/_tmp/siren_outcomes.dta
	save ./data/_tmp/siren_outcomes, replace
	
}


*PART1: SIREN LEVEL EFFECTIVE OUTCOMES

use an sir n nbheur* *_nb if !mi(sir) using ./data/_tmp/siren_outcomes, clear

collapse (sum) n nbheur* *_nb, by(an sir)

local outvars sx age tenure sbr
foreach v of local outvars {
	gen mean_`v'_eqtp = `v'_nb / nbheur_`v'
}

gen dads_eqtp = nbheur / 1820

xtset sir an

/*PART1A: growth rate!
preserve 
gen growth = n / L1.n 
gen no_growth = 1 if growth<=1 & !missing(growth)
rename (sir an) (sir_cl an_cl)
keep sir_cl an_cl no_growth
keep if no_growth == 1
save ./data/interim/panel_outcomes/no_growth.dta, replace
restore*/ 

*PART1B: dads_outcomes
ds mean_* dads_eqtp
local meanvar `r(varlist)'
foreach v of local meanvar {
	tssmooth ma `v'_ma3 = `v', window(1 1 1)
	replace `v'_ma3 = . if missing(L1.`v') | missing(`v') | missing(F1.`v')
}


ds *_ma3*
local vars `r(varlist)'
egen nmiss = rowmiss(`vars')
drop if nmiss == `:word count `vars''
drop nmiss

keep if an > 1998
keep sir an *_ma3*

save ./data/interim/panel_outcomes/firm_dads.dta, replace


*PART2: SIRENxZE LEVEL EFFECTIVE OUTCOMES
use an sir ze10 hhi_comp cs1 nbheur if !mi(sir) using ./data/_tmp/siren_outcomes, clear

drop if mi(hhi_comp) | mi(cs1) | cs1=="" 

bysort sir ze10 an: egen hhi_comp_nb = total(hhi_comp * nbheur) 
bysort sir ze10 an: egen nbheur_hhi_comp = total(nbheur)
gen hhi_comp_sirze_eqtp = hhi_comp_nb / nbheur_hhi_comp
rename hhi_comp hhi_comp_sirzecs1
	
egen sirzecs1 = group(sir ze10 cs1)
xtset sirzecs1 an
	
ds hhi_comp_sir*
local meanvar `r(varlist)'
foreach v of local meanvar {
	tssmooth ma `v'_ma3 = `v', window(1 1 1)
	replace `v'_ma3 = . if missing(L1.`v') | missing(`v') | missing(F1.`v')
}

keep if !missing(hhi_comp_sirze_eqtp_ma3) | !missing(hhi_comp_sirzecs1_ma3)
keep if an > 1998
keep sir ze10 cs1 an *_ma3
sort sir ze10 an cs1 

save ./data/interim/panel_outcomes/firm_hhi_dads.dta, replace


*PART3: ZE LEVEL OUTCOMES	
use ./data/_tmp/siren_outcomes, clear

drop if mi(hhi_comp) | mi(cs1) | cs1=="" | mi(ze10)

collapse (sum) hhi_zecs1 = hhi_comp, by(an ze10 cs1)
replace hhi_zecs1 = hhi_zecs1 * 10000
	
egen zecs1_id = group(ze cs1)
xtset zecs1_id an

tssmooth ma hhi_zecs1_ma3 = hhi_zecs1, window(1 1 1)
replace hhi_zecs1_ma3 = . if missing(L1.hhi_zecs1) | missing(hhi_zecs1) | missing(F1.hhi_zecs1)

keep an cs1 ze10 hhi_zecs1_ma3
drop if missing(hhi_zecs1_ma3)

save ./data/interim/panel_outcomes/hhi_zecs1.dta, replace

/*END OF DOFILE*/
