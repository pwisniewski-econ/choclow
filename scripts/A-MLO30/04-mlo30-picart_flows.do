/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  NB : all do-files starting with "3" correct closures using flows of workers between establishments or Siren x ZE. For instance, we check that they are not massively displaced toward the same firm (all corrections suggsted by Picart).
  
  Description: Creates flows of workers between siren x ZE.
	
  INPUT: 
	"${sasflux}\DADS`y'_pic.dta" [annual DADS data from 2002 to 2015; created by SAS dofiles]
	"${miscdata}\01_AUZE_Commune.dta" [list of municipalities and employment zones, from INSEE]

  OUTPUT: 
	${workingdata}\sirenzepic2_`y'.dta [all flows from year y-1 to year y]
		
  __________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

*SETUP*
clear
global period_a 2002
global period_c 2015

*	1. Loop over the years
forvalues i = $period_a / $period_c {
local ylist `ylist' `i'
}
tempfile `ylist'

*	1.a Call year specific
foreach y in `ylist' {
use "./data/external/sas_flux/DADS`y'_pic", clear
rename *, lower
keep if siren!="" & (filt=="1" | filt_1=="1")

display `y'
keep siren ident_s filt* comt* datdeb* datfin* nbheur*

*	1.b Keep movers
bysort ident_s: gen move = _N
	drop if move<2
	
	

*	1.c. Additional cleaning
duplicates drop

replace comt=comt_1 if filt=="" & comt==""
	drop comt_1

drop if comt=="" | siren==""
drop if regexm(comt,"[aA-zZ]")==1

replace siren = "0"+siren if length(siren)==9



*	1.d Main job in year y
bysort ident_s: egen temp_n1 = rank(-nbheur_1)
	gen temp_f = datdeb_1 if temp_n1==1.5
	bysort ident_s: egen temp_first = rank(temp_f)
	replace temp_n1 = 1 if temp_first==1 & temp_n1==1.5
	gen from = (temp_n1==1)
	by ident_s: egen t15 = min(temp_n1)
	drop temp*


gen to = (datfin>=300)
	replace to=0 if filt=="" & filt_1!=""
	*bysort ident_s: egen temp_n = rank(-nbheur) if to==1 & nbheur>0
	bysort ident_s: egen temp_n = rank(-datfin) if to==1 & nbheur>0
	bysort ident_s: egen temp_nn = rank(-nbheur) if temp_n==1.5
	replace temp_n= temp_nn if temp_nn==1 & temp_n==1.5
	replace temp_n = 1 if temp_n==1.5 & temp_nn==1.5 & filt_1==""
	replace to=0 if to==1 & temp_n!=1
	by ident_s: egen tt15 = min(temp_n)
	drop temp*

preserve
	keep if t15==1.5 | tt15==1.5
	save ./data/interim/mlo30/temp_15_`y'.dta, replace 
	
	run ./scripts/stata_helpers/picart_ze.lib.do
	save ./data/interim/mlo30/temp_15_`y'.dta, replace

	restore
	drop t15 tt15
	
	
drop if from==1 & to==1	
drop if from==0 & to==0
bysort ident_s: egen temp1=total(from)
bysort ident_s: egen temp2=total(to)
drop if temp1==0 | temp2==0
drop temp*

sort ident_s to
	by ident_s: gen order = _n
	drop if order==3
	assert order==to+1

keep siren datdeb comt ident_s order



*	1.e. ZE
destring comt, gen(insee)

merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(master matched) keepusing(ze10) nogen
	tostring ze10, gen(sirenze)
	replace sirenze = siren+"-"+sirenze
	drop siren comt ze10 insee



*	1.f. Reshape to get A-B
reshape wide sirenze datdeb, i(ident_s) j(order)
	drop datdeb1
	replace datdeb2=1 if datdeb2<=1
	

	
*	1.g. Add extra movers 
format ident_s %18.0g
append using ./data/interim/mlo30/temp_15_`y'.dta

/*replace ident_s=ident_s-dupmov if dupmov!=""
gen double ident2 = .
	format ident2 %18.0g
	replace ident2=ident_s/10000 if t==.
	replace ident2=ident_s if t==1
	duplicates tag ident2, gen(test)
	drop ident2 test
	*/
drop dupmov
	
*	1.g. Keep biggest move
*		move_count : size of move rank 1 (even if several equals)
*		move_sh	: size of move ranks 1 & 2 & 3
bysort sirenze1 sirenze2: egen move_count = count(ident_s)
tab move_c
bysort sirenze1 sirenze2: gen tempn = _n
bysort sirenze1: egen temprank = rank(-move_c) if tempn==1, unique

gen temp = sirenze2 if temprank==1
bysort sirenze1: egen move_main = mode(temp)

bysort sirenze1: egen temp2 = sum(move_c) if temprank<=3
bysort sirenze1: egen move_sh = max(temp2)
drop temp*

keep if sirenze2==move_main
drop move_main



*	1.h. Geo move?
gen move_geo = (substr(sirenze1,12,.)!=substr(sirenze2,12,.))
tab move_geo



*	1.i. collapse to firm panel
collapse (first) move_geo move_c move_sh (median) datdeb*, by(sirenze1 sirenze2)

rename * *_`y'
rename sirenze1* sirenze

save ./data/interim/mlo30/sirenzepic2/sirenzepic2_`y'.dta, replace
erase ./data/interim/mlo30/temp_15_`y'.dta
}

/*END OF DOFILE*/
