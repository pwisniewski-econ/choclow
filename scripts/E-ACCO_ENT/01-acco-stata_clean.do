use "./data/interim/acco_ent/2005_2015.dta", clear

rename *, lower

duplicates drop 
* 2696 obs
* 2529 obs

gen year_sign = substr(datsign,1,4)

keep if real(year_sign) < 2014

forvalues j = 1 / 37 {
	destring objn`j', force replace
}

/* On enlève les accords pour lesquels on ne connaît pas le type, ou pour lequel il s'agit d'une erreur (accords de branche 7 ou accord de territoire 8)*/

keep if typtext == "1" | typtext == "2" | typtext == "3" | typtext == "4" | typtext == "5" | typtext == "6" | typtext == "9"
* 18 observations deleted
* 29

/*
ta typtext

2015 :
    typtext |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    526,140       54.38       54.38
          2 |    216,898       22.42       76.80
          3 |     27,939        2.89       79.69
          4 |     30,223        3.12       82.81
          5 |     20,795        2.15       84.96
          6 |    135,312       13.99       98.95
          9 |     10,171        1.05      100.00
------------+-----------------------------------
      Total |    967,478      100.00

2016 :
   typtext |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |    575,210       54.21       54.21
          2 |    242,541       22.86       77.07
          3 |     30,700        2.89       79.96
          4 |     34,000        3.20       83.16
          5 |     22,139        2.09       85.25
          6 |    145,918       13.75       99.00
          9 |     10,608        1.00      100.00
------------+-----------------------------------
      Total |  1,061,116      100.00

*/

* Type de texte "positif" : accord 1 ; avenant 2 ; adhésion à un accord 5
gen typtext_pos = (typtext=="1" | typtext=="2" | typtext=="5")


* Type de texte "négatif" / conflictuel : dénonciation 3 ; désaccord 4
gen typtext_neg1 = (typtext=="3" | typtext=="4")

* Idem mais en incluant les décisions unilatérales employeur 6 :
gen typtext_neg2 = (typtext=="3" | typtext=="4" | typtext=="6")

* NB: category 9 = other

gen typtext_pos_dum1 = 1 if (typtext=="1" | typtext=="2" | typtext=="5")
replace typtext_pos_dum1 = 0 if (typtext=="3" | typtext=="4")

gen typtext_pos_dum2 = 1 if (typtext=="1" | typtext=="2" | typtext=="5")
replace typtext_pos_dum2 = 0 if (typtext=="3" | typtext=="4" | typtext=="6")


*** Texte portant sur les salaires 
gen acc_sal1 = objn1 
label var acc_sal "Negociation on wages"

* accord salaires (positif)
gen acc_sal1_pos = (acc_sal1 & typtext_pos)
label var acc_sal1_pos "Agreement on wages"

* désaccord salaires (négatif)
gen acc_sal1_neg1 = (acc_sal1 & typtext_neg1)
label var acc_sal1_neg1 "No agreement on wages"

gen acc_sal1_neg2 = (acc_sal1 & typtext_neg2)
label var acc_sal1_neg2 "No agreement on wages"


*** Texte portant sur les salaires et rémunérations au sens large
gen acc_sal2 = (objn1 == 1 | objn2 == 1 | objn3 == 1 | objn4 == 1)
label var acc_sal2 "Negociation on wages and related outcomes"

* Accords portant sur les salaires et rémunérations au sens large
gen acc_sal2_pos = (acc_sal2 & typtext_pos)
label var acc_sal2_pos "Agreement on wages and related outcomes"

* Désaccords sur les salaires et rémunérations au sens large
gen acc_sal2_neg1 = (acc_sal2 & typtext_neg1)
label var acc_sal2_neg1 "No agreement on wages and related outcomes"

gen acc_sal2_neg2 = (acc_sal2 & typtext_neg2)
label var acc_sal2_neg2 "No agreement on wages and related outcomes"

*** Texte portant sur les questions de temps de travail, congés...
gen acc_hours = (objn9 == 1 | objn10 == 1 | objn11 == 1 | objn12 == 1 | objn34 == 1 | objn36 == 1) 
label var acc_hours "Negociation on working time"

* Accords portant sur les questions de temps de travail, congés...
gen acc_hours_pos = (acc_hours & typtext_pos)
label var acc_hours_pos "Agreement on working time"

* Désccords portant sur les questions de temps de travail, congés...
gen acc_hours_neg1 = (acc_hours & typtext_neg1)
label var acc_hours_neg1 "No agreement on working time"

gen acc_hours_neg2 = (acc_hours & typtext_neg2)
label var acc_hours_neg2 "No agreement on working time"


*** Ensemble accords salaire large + heures
gen acc_global_pos = acc_sal2_pos+acc_hours_pos
label var acc_global_pos "Agreement on wages+ & working time"


*** Texte portant sur les licenciements
gen acc_layoff = (objn15 == 1 | objn16 == 1)
label var acc_layoff "Negociation on layoffs"

* Accords portant sur les licenciements
gen acc_layoff_pos = (acc_layoff & typtext_pos)
label var acc_layoff_pos "Agreement on layoffs"

* Désccords portant sur les licenciements
gen acc_layoff_neg1 = (acc_layoff & typtext_neg1)
label var acc_layoff_neg1 "No agreement on layoffs"

gen acc_layoff_neg2 = (acc_layoff & typtext_neg2)
label var acc_layoff_neg2 "No agreement on layoffs"



destring siren year_sign, replace force
drop if siren==.
drop if siren==0
drop if year_sign==.

gcollapse (sum) acc_sal1* acc_sal2* acc_layoff* acc_hours* acc_global_pos, by(siren year_sign)

reshape wide acc_sal1* acc_sal2* acc_layoff* acc_hours* acc_global_pos, i(siren) j(year)

egen acc_global_pos_0507 = rowtotal(acc_global_pos2005 acc_global_pos2006 acc_global_pos2007)


global obj sal1 sal2 hours

foreach j in $obj {
egen acc_`j'_0513 = rowtotal(acc_`j'2*)
egen acc_`j'_pos_0513 = rowtotal(acc_`j'_pos*)
egen acc_`j'_neg1_0513 = rowtotal(acc_`j'_neg1*)
egen acc_`j'_neg2_0513 = rowtotal(acc_`j'_neg2*)

egen acc_`j'_0507 = rowtotal(acc_`j'2005 acc_`j'2006 acc_`j'2007)
egen acc_`j'_pos_0507 = rowtotal(acc_`j'_pos2005 acc_`j'_pos2006 acc_`j'_pos2007)
egen acc_`j'_neg1_0507 = rowtotal(acc_`j'_neg12005 acc_`j'_neg12006 acc_`j'_neg12007)
egen acc_`j'_neg2_0507 = rowtotal(acc_`j'_neg22005 acc_`j'_neg22006 acc_`j'_neg22007)
}

label variable acc_sal1_0513 "Nb negociations on wages, 05-13"
label variable acc_sal1_pos_0513 "Nb agreements on wages, 05-13"
label variable acc_sal1_neg1_0513 "Nb Disagreements on wages, 05-13"
label variable acc_sal1_neg2_0513 "Nb Disagreements on wages, 05-13"

label variable acc_sal2_0513 "Nb negociations on wages and related, 05-13"
label variable acc_sal2_pos_0513 "Nb agreements on wages and related, 05-13"
label variable acc_sal2_neg1_0513 "Nb Disagreements on wages and related, 05-13"
label variable acc_sal2_neg2_0513 "Nb Disagreements on wages and related, 05-13"

label variable acc_hours_0513 "Nb negociations on hours, 05-13"
label variable acc_hours_pos_0513 "Nb agreements on hours, 05-13"
label variable acc_hours_neg1_0513 "Nb Disagreements on hours, 05-13"
label variable acc_hours_neg2_0513 "Nb Disagreements on hours, 05-13"

label variable acc_sal1_0507 "Nb negociations on wages, 05-07"
label variable acc_sal1_pos_0507 "Nb agreements on wages, 05-07"
label variable acc_sal1_neg1_0507 "Nb Disagreements on wages, 05-07"
label variable acc_sal1_neg2_0507 "Nb Disagreements on wages, 05-07"

label variable acc_sal2_0507 "Nb negociations on wages and related, 05-07"
label variable acc_sal2_pos_0507 "Nb agreements on wages and related, 05-07"
label variable acc_sal2_neg1_0507 "Nb Disagreements on wages and related, 05-07"
label variable acc_sal2_neg2_0507 "Nb Disagreements on wages and related, 05-07"

label variable acc_hours_0507 "Nb negociations on hours, 05-07"
label variable acc_hours_pos_0507 "Nb agreements on hours, 05-07"
label variable acc_hours_neg1_0507 "Nb Disagreements on hours, 05-07"
label variable acc_hours_neg2_0507 "Nb Disagreements on hours, 05-07"


foreach yy in "07" "13" {
	gen wage_agreement_ind_05`yy' = 1 if acc_sal1_pos_05`yy'>0
	gen wage_agreement_num_05`yy' = acc_sal1_pos_05`yy'
	gen wage_agreement_fail_05`yy' = 1 if acc_sal1_neg2_05`yy'>0
	gen wage_agreement_share_05`yy' = acc_sal1_pos_05`yy' / acc_sal1_05`yy'
	gen extwage_agreement_ind_05`yy' = 1 if acc_sal2_pos_05`yy'>0
	gen hours_agreement_ind_05`yy' = 1 if acc_hours_pos_05`yy'>0
}

keep siren wage_agreement_ind_* wage_agreement_num_* wage_agreement_fail_* wage_agreement_share_* extwage_agreement_ind_* hours_agreement_ind_*

save "./data/interim/acco_ent/accords0513.dta", replace

/*END OF DOFILE*/
