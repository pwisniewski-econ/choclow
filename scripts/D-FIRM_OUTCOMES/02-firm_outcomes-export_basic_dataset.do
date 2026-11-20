* ------------------------------------------------------------------------------
* Build base firm-year panel from DGM FICUS-FARE dataset (no EAP).
* Output: `${workingdata}/01_ficusfare_base_1999_2015.dta`
* ------------------------------------------------------------------------------

import delimited using "./data/interim/firm_outcomes/ficusfare_profil_wof_19992015_v0222_light.csv", clear
save "./data/interim/firm_outcomes/ficusfare_profil_wof_19992015_v0222_light.dta", replace
erase "./data/interim/firm_outcomes/ficusfare_profil_wof_19992015_v0222_light.csv"

/*END OF DOFILE*/
