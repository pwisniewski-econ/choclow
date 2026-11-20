* Required Stata add-ons: winsor2, gtools, reghdfe, ftools, psmatch2, egenmore.

local missing ""
foreach command in winsor2 gduplicates gcollapse reghdfe ftools psmatch2 _gnvals {
    capture which `command'
    if _rc local missing "`missing' `command'"
}

if "`missing'" != "" {
    display as error "Missing Stata commands:`missing'"
    display as error "See scripts/stata_helpers/check_dependencies.do for package names."
    exit 499
}

/*END OF DOFILE*/
