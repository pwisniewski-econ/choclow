local folder "data/external/fhdads"
local files : dir "`folder'" files "*.dta"

foreach file of local files {
	di "Compressing: `file'"
	use "`folder'/`file'", clear
	compress 
	rename *, lower
	save "`folder'/`file'", replace
}

clear 

local folder "data/external/sas_fhdads"
local files : dir "`folder'" files "*.dta"

foreach file of local files {
	di "Compressing: `file'"
	use "`folder'/`file'", clear
	compress 
	rename *, lower
	save "`folder'/`file'", replace
}

/*END OF DOFILE*/
