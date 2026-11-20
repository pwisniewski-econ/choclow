* ------------------------------------------------------------------------------
* Compute firm-level markups and TFP from DGM-style PF coefficients.
* Output: `./data/interim/firm_outcomes/04_ficusfare_with_markup_tfp_1999_2015.dta`
* ------------------------------------------------------------------------------

clear

des *R using "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta"

use siren year naf2d_num catotalR salR immocorR autachaR acha4R catotal sal immocorR autacha acha4 mfg maxmfg ///
 using "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta", clear

compress
 
merge m:1 naf2d_num using "./data/interim/firm_outcomes/03_dgm_coefficients_byind_revenue.dta", keep(1 3) nogen

* PF logs
gen double s = ln(catotalR) if catotalR>0
gen double m = ln(acha4R)   if acha4R>0
gen double v = ln(salR)     if salR>0
gen double k = ln(immocorR) if immocorR>0
gen double o = ln(autachaR) if autachaR>0

* Ratio (revenue over variable input expenditure; DGM uses nominal catotal/acha4)
gen double ratio_catotal_acha4 = catotal/acha4 if catotal>0 & acha4>0
label var ratio_catotal_acha4 "catotal/acha4 (revenue over materials expenditure)"

* Elasticities and markups (materials as variable input)
gen double elast_m_cd = beta_m_cd
gen double elast_m_tl = beta_m_tl ///
	+ 2*beta_m2_tl*m ///
	+ beta_mv_tl*v ///
	+ beta_mo_tl*o ///
	+ beta_mk_tl*k

label var elast_m_cd "Output elasticity of materials (CD)"
label var elast_m_tl "Output elasticity of materials (TL)"

gen double mu_cd = elast_m_cd * ratio_catotal_acha4
gen double mu_tl = elast_m_tl * ratio_catotal_acha4
label var mu_cd "Markup (CD)"
label var mu_tl "Markup (TL)"

gen double ln_mu_cd = ln(mu_cd) if mu_cd>0
gen double ln_mu_tl = ln(mu_tl) if mu_tl>0
label var ln_mu_cd "Log markup (CD)"
label var ln_mu_tl "Log markup (TL)"

* TFP (log) as production function residual
gen double tfp_cd = s - (beta_const_cd + beta_v_cd*v + beta_k_cd*k + beta_m_cd*m + beta_o_cd*o)
label var tfp_cd "TFP (log residual, CD)"

gen double v2 = v^2
gen double k2 = k^2
gen double m2 = m^2
gen double o2 = o^2
gen double mv = m*v
gen double mo = m*o
gen double mk = m*k
gen double vo = v*o
gen double vk = v*k
gen double ok = o*k

gen double __pred_tl = beta_const_tl ///
	+ beta_v_tl*v + beta_k_tl*k + beta_m_tl*m + beta_o_tl*o ///
	+ beta_v2_tl*v2 + beta_k2_tl*k2 + beta_m2_tl*m2 + beta_o2_tl*o2 ///
	+ beta_mv_tl*mv + beta_mo_tl*mo + beta_mk_tl*mk + beta_vo_tl*vo + beta_vk_tl*vk + beta_ok_tl*ok

gen double tfp_tl = s - __pred_tl
drop __pred_tl v2 k2 m2 o2 mv mo mk vo vk ok
label var tfp_tl "TFP (log residual, TL)"

* Keep tidy; drop PF log shorthands
drop s m v k o
drop beta_*

compress
save "./data/interim/firm_outcomes/04_ficusfare_with_markup_tfp_1999_2015.dta", replace

/*END OF DOFILE*/
