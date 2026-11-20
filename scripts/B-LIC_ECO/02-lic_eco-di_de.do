/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
  Description : 
	1) Identify Layoffs (LE) based on pole emploi information 
	2) Get a unique identifier to match a Layoff with the Pole Emploi trajectory:
		a) Start from DE (demandeur d'emploi)
		b) Find the specific DI (demande d'indemnisation) for the DE
  
  Input : Raw files from FHDADS : 
	${choclowdata}\FHDADS\de.dta [file of employment seekers]
	${choclowdata}\FHDADS\di.dta [file of UI demands]
  
  Output : ${workingdata}\le1_dedi.dta
	Output is a unique identifiers for all LE: idfhda*ndem 
	(i.e. FHDADS individual * PoleEmploi demand number)  
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

*SETUP*
clear

*			I. DE: Identify LE event, keep their unique FH tracker (IDFHDA*ndem)

	** -- Keep LE, cf. Appendix
use "./data/external/fhdads/de.dta", clear
tab motins
keep if inlist(motins, "11")

	** -- Collapse continuous spells and keep firt ID
duplicates tag idfh, gen(t)
	sort idfhda datins
	gen temp = datann[_n-1] if idfh==idfh[_n-1]
	replace temp = datins-temp

egen tempid = group(idfhda datins) if temp==. | temp>0
	replace tempid = tempid[_n-1] if temp==0
	replace datins = . if temp==0
	replace ndem = . if temp==0
	replace motins = "" if temp==0
	replace datann = . if temp[_n+1]==0
	replace motann = "" if temp[_n+1]==0

	qui summ tempid
	replace tempid = r(max)+_n if tempid==.
	collapse (firstnm) idfhda ndem datins datann motann motins mobdist mobunit salmt salunit temps, by(tempid)
	drop tempid


	** -- Keep only 1st registry in the year
gen and = year(datins)
	gen semd = month(datins)>6
	replace semd=semd+1

bysort idfhda and: egen first = rank(datins)
	drop if first>1
	drop first

	
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
	
*		II. DI: Find the closest DI
gen dateouv = datins
local DI dateouv txrb txrn durfileg allocation droit cdtdtfin


	**-- Perfect match exists for some DE & DI
*First I merge when DI is on same date as DE
merge 1:m idfhda dateouv using "./data/external/fhdads/di", keep(master match) keepusing(`DI')

*Various DI, but similar in may variables, so dup drop should do
duplicates drop
duplicates report idfhda ndem

*Keep aside matched obs, and go on to 2nd merge
tempfile temp2
preserve
	keep if _m==3
	drop _m
	save `temp2'
restore


	**-- For other unmatched, apply a selection rule to peg DE & DI
*Working on unmatched, I first joinby to keep all possibilities
keep if _m==1
	drop _m dateouv
	sort idfhda

joinby idfhda using "./data/external/fhdads/di", unmatched(m) _merge(di)

*Then I keep smallest distance between DE and DI dates
gen dist = dateouv - datins
	duplicates drop idfhda ndem `DI', force
	bysort idfhda ndem: egen rank = rank(-dist)
	keep if rank==1 | rank==.
	tab di
	drop rank
	
*Finally, I apply the following rule:
*DI is considered valid if made:
*	a) less than 5 days before DE (measurement error? miscoded)
*OR	b) no more than 30 days after DE (delay?)
replace di = 1 if di==3 & (dist<-5 | dist>30)
summ dist if di==3
foreach v of varlist `DI' {
	capture replace `v'=. if di==1
	capture replace `v'="" if di==1
	}
	drop dist di

	
	**-- Get all matches (perfect and imperfect) together
append using `temp2'
	sort idfhda datins
	duplicates tag idfhda ndem, gen(t)
	drop if t>0 & year(cdtdtfin)==9998
	duplicates drop idfhda ndem, force

	
	
	
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*
			** THE END

drop if and<2002		
save "./data/interim/lic_eco/le1_dedi.dta", replace


	


/* 
*______________________________________________________________________________*
*¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*

			APPENDIX

MOTINS_A Motif d'inscription de la demande détaillé
	00 SANS OBJET (CATEGORIE 5)
	11 LICENCIEMENT ECONOMIQUE
	12 AUTRE LICENCIEMENT
	13 DEMISSION
	14 FIN DE CONTRAT
	15 FIN DE MISSION D'INTERIM
	16 FIN CONVENTION CONVERSION
	17 LICENCIE ECO. PAP ANTICIPE
	18 FIN DE CONTRAT EMPLOI JEUNE
	19 AUTRE CAS
	20 ENTREE EN CRP
	21 PREMIERE ENTREE MARC. TRAVAIL
	22 REPRISE ACTI. APRES INT. > 6 M
	23 BENEF. ACTI. CONV. DU 3 FEV. 9
	24 PRIMO ARRIVANT
	25 FIN DE CRP
	26 RUPTURE CNE INITIATIVE EMPLOYE
	27 RUPTURE CNE INITIATIVE SALARIE
	28 SORTIE DE STAGE
	29 FIN D'ACTIVITE NON SALARIEE
	30 FIN DE MALADIE, MATERNITE
	31 ENTREE EN CTP
	32 RUPTURE CONVENTIONNELLE DU CDI
	33 ENTREE CTP (SUITE CRP)
	34 ENTREE EN CSP
	35 RETOUR EN FRANCE
	36 FIN DE DETENTION
	37 Fin de période d'essai
	38 Fin de service civique
*/

/*END OF DOFILE*/
