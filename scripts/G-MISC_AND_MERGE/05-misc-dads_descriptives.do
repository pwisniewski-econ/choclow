cap erase ./data/_tmp/descriptives_panel.dta
foreach i in 19942001 20022007 20082012 20132019 {

	use an nninouv SX ANNAI SIR CS2 APET apet2 NBHEUR SBR CATJUR if NBHEUR>0 & !missing(NBHEUR) using "./data/external/sas_paneldads/PAN19_`i'", clear
	rename *, lower

	*Keep firms in CATJUR = private firm
	cap destring catjur, replace
	recode catjur (3100/3199=0) (5000/5999=0) (6200/6299=0) (6900/6999=0) (min/max=1) , gen(todrop)
	drop if todrop==1
	drop todrop
	
	rename apet naf2003 
	merge m:1 naf2003 using ./data/external/naf2003_naf2008.dta, keep(master match) nogen
	gen sec1d = substr(naf2008, 1,2)
	destring sec1d, replace force
	
	replace apet2 = substr(apet2, 1, 2) 
	destring apet2, replace force
	
	replace sec1d = apet2 if mi(sec1d)
	
	gen siren = sir
	destring sir, replace force
	merge m:1 an nninouv sir using  "./data/interim/mlo30/mlo30_tenure.dta", keep(master match) nogen keepusing(min_an_sir spell)
	gen tenure = an - min_an_sir + 1
	
	gen cs1 = substr(cs2, 1, 1)

	
	destring sx, replace force
	
	keep an cs1 sec1d siren spell tenure annai sx sbr nbheur
	
	cap append using ./data/_tmp/descriptives_panel.dta
	save ./data/_tmp/descriptives_panel.dta, replace
	
}

*PART I: DESCRIPTIVES ON OCCUPATION AND SECTOR

use ./data/_tmp/descriptives_panel.dta, clear 

gen age = an - annai 
gen one = 1

local outvars sx sbr
foreach v of local outvars {
	gen nbheur_`v' = nbheur
	replace nbheur_`v' = . if missing(`v')
	gen `v'_nb = `v' * nbheur
	gen one_`v' = one 
	replace one_`v' = . if missing(`v')
}

collapse (sum) one* `outvars' nbheur* *_nb, by(an age cs1 sec1d)

recode sec1d (1/3 = 1) (5/39 = 2) (41/43 = 3) (45/56 = 4) (58/63 = 5) (64/66 = 6) (68 = 7) (69/82 = 8) (84/88 = 9) (90/99=10 ) , gen(sec_a10)
replace sec_a10 = . if sec_a10<1 | sec_a10 >10
label define A10 1 "Agriculture" 2 "Manufacturing & Extract." 3 "Construction" 4 "Retail" 5 "Info & Com" 6 "Finance" 7 "Real Estate" 8 "Services to Firms" 9 "Public" 10 "Other Services"
label value sec_a10 A10

rename one n
keep an age n `outvars' *_nb cs1 sec_a10 one* nbheur*

save ./data/interim/panel_outcomes/descriptives_panel.dta, replace
clear

*PART II: TENURE DESCRIPTIVES (DIRECT RESULTS)

use an annai siren spell tenure nbheur if !mi(spell) using "./data/_tmp/descriptives_panel.dta", clear 
gen one = 1
collapse (sum) n=one nbheur, by(an annai tenure)
	
save ./data/interim/panel_outcomes/tenure_panel.dta, replace
cap erase ./data/_tmp/descriptives_panel.dta
	
/*END OF DOFILE*/
