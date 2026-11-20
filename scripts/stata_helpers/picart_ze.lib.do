*1.a	Pre-cleaning
drop move from to t*15

destring comt, gen(insee)
	merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(master matched) keepusing(ze10) nogen
	tostring ze10, gen(sirenze)
	replace sirenze = siren+"-"+sirenze
	drop siren comt ze10 insee


*1.b	Start we reorganizing from and to
sort ident_s datdeb_1 datdeb

gen to = (datfin>=300)
	replace to=0 if filt=="" & filt_1!=""
	
bysort ident_s: egen temp_n1 = rank(-nbheur_1)

/*THIS IS NOT CORRECT!
Changes can occur within the year.
Example : in 2005 ident_s==645888 & more broadly the change
from sirenze==672014099-2513 to sirenze==410217640-2513
I need to change the "from" definition (at least) so
as to accept change within 1 specific year
[this should have been fine, had their been info on
_n-1;, but it is missing for some reason...]
[panel would deal with that easily...]
*/
	gen temp_f = datdeb_1 if temp_n1==1.5
	bysort ident_s: egen temp_first = rank(temp_f)
	replace temp_n1 = 1 if temp_first<=1.5 & temp_n1==1.5
	gen from = (temp_n1==1)
	drop temp*


by ident_s: egen temp1=total(from)
	by ident_s: egen temp2=total(to)
	by ident_s: egen temp3=mean(from)
	by ident_s: egen temp4=mean(to)
	drop if temp1==0 | temp2==0
	drop if temp3==1 & temp4==1
	drop temp*

drop if to==0 & from==0	

by ident_s: gen move=_N
	drop if move<2
	drop move

	
*1.c	I build a NxN matrix of move
bysort ident_s to: gen order_t = _n
bysort ident_s from: gen order_f = _n

summ order_f if from==1
local maxfrom `r(max)'
summ order_t if to==1
local maxto `r(max)'

forvalues i = 1/`maxto' {
	gen temp_t_`i' = sirenze if to==1 & order_t==`i'
	by ident_s: egen sirenze2`i'= mode(temp_t_`i')
	gen temp_deb = datdeb if to==1 & order_t==`i'
	by ident_s: egen datdeb2`i' = max(temp_deb)
	drop temp*
	}

	
drop if from==0
keep ident_s sirenze* datdeb2*
duplicates drop 

by ident_s: gen order=_n
	replace ident_s = ident_s*10000+order
	format ident_s %18.0g
	drop order
	
rename sirenze sirenze1

reshape long sirenze2 datdeb2, i(ident_s sirenze1) j(dupmov)
	drop if sirenze2 == ""
	drop if sirenze1==sirenze2

*1.d	I clean for export into PicartZE
replace datdeb2=1 if datdeb2<=1	


