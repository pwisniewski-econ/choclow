* ------------------------------------------------------------------------------
* DGM-style production function estimation (revenue specification; no EAP/quantity).
* Produces industry-level coefficients used to compute markups + TFP downstream.
* Output: `${workingdata}/03_dgm_coefficients_byind_revenue.dta`
* ------------------------------------------------------------------------------

clear 
cap mkdir "./data/_tmp"
global temp "./data/_tmp"

* Clean up / settings (mirrors DGM code)
clear mata
set matsize 11000
mata: mata clear
mata: mata set matastrict off

* Identifiers
local firm firmsId
local year year

* Options (keep aligned with DGM defaults where possible)
local prodar1_sq 0
local est_k 1
local order 2

use "./data/interim/firm_outcomes/01_ficusfare_base_1999_2015.dta", clear

* Require key variables for revenue production function
foreach v in `firm' year naf2d_num catotalR acha4R salR immocorR autachaR {
	capture confirm variable `v'
	if _rc!=0 {
		di as error "Missing required variable `v' in base dataset."
		error 111
	}
}

* Construct logs for PF estimation
gen double s = ln(catotalR) if catotalR>0
gen double m = ln(acha4R)   if acha4R>0
gen double v = ln(salR)     if salR>0
gen double k = ln(immocorR) if immocorR>0
gen double o = ln(autachaR) if autachaR>0

* Market share control (DGM uses `ms5d`; compute if missing)
capture confirm variable ms5d
if _rc!=0 {
	capture confirm variable catotal
	local rc_catotal = _rc
	capture confirm variable naf_single
	local rc_naf = _rc
	if `rc_catotal'==0 & `rc_naf'==0 {
		bysort year naf_single: egen double __catotal_tot = total(catotal)
		gen double ms5d = catotal/__catotal_tot if __catotal_tot>0
		drop __catotal_tot
	}
}
capture confirm variable ms5d
if _rc!=0 gen double ms5d = .

* Drop observations with missing essentials
drop if missing(s, m, v, k, o, naf2d_num, `firm', year)

xtset `firm' `year'

* ------------------------------------------------------------------------------
* Mata routines (from DGM `markup_estimation_dgmacf.do`; kept as close as possible)
* ------------------------------------------------------------------------------
mata

	// Cobb-Douglas
	void GMM_DLW(todo,betas,crit,g,H)
	{
		PHI 	= st_data(.,("phi"))
		PHI_LAG = st_data(.,("phi_lag"))

		Z = st_data(.,("const","v","k","m_lag","o_lag"))
		X = st_data(.,("const","v","k","m","o"))
		X_lag = st_data(.,("const","v_lag","k_lag","m_lag","o_lag"))

		C = st_data(.,("const"))

		OMEGA			= PHI - X*betas'
		OMEGA_lag		= PHI_LAG - X_lag*betas'
		OMEGA_lag_sq	= OMEGA_lag:*OMEGA_lag
		if ("`prodar1_sq'" == "1")  OMEGA_lag_pol = (C,OMEGA_lag,OMEGA_lag_sq)
		else 						OMEGA_lag_pol = (C,OMEGA_lag)

		g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA
		XI  = OMEGA - OMEGA_lag_pol*g_b

		crit = (Z'XI)'(Z'XI)
	}

	void DLW()
	{
		S = optimize_init()
		optimize_init_evaluator(S, &GMM_DLW())
		optimize_init_evaluatortype(S, "d0")
		optimize_init_technique(S, "nm")
		optimize_init_nmsimplexdeltas(S, 0.1)
		optimize_init_which(S, "min")
		optimize_init_conv_nrtol(S, 0.00001)
		optimize_init_conv_maxiter(S,1000)

		if ("`est_k'" == "1") {
			b = st_matrix("beta_ols_cd")
			optimize_init_params(S, b)
		}

		p = optimize(S)
		st_matrix("beta_dlw", p)
	}

	// Translog
	void GMM_DLW_TL(todo,betas,crit,g,H)
	{
		PHI 	= st_data(.,("phi"))
		PHI_LAG = st_data(.,("phi_lag"))

		Z = st_data(.,("const","v","k","m_lag","o_lag","v2","k2","m_lag2","o_lag2","m_lagv","m_lago_lag","m_lagk","vo_lag","vk","o_lagk"))
		X = st_data(.,("const","v","k","m","o","v2","k2","m2","o2","mv","mo","mk","vo","vk","ok"))
		X_lag = st_data(.,("const","v_lag","k_lag","m_lag","o_lag","v_lag2","k_lag2","m_lag2","o_lag2","m_lagv_lag","m_lago_lag","m_lagk_lag","v_lago_lag","v_lagk_lag","o_lagk_lag"))

		C = st_data(.,("const"))

		OMEGA 			= PHI - X*betas'
		OMEGA_lag 		= PHI_LAG - X_lag*betas'
		OMEGA_lag_sq	= OMEGA_lag:*OMEGA_lag
		if ("`prodar1_sq'" == "1")  OMEGA_lag_pol = (C,OMEGA_lag,OMEGA_lag_sq)
		else 						OMEGA_lag_pol = (C,OMEGA_lag)

		g_b = invsym(OMEGA_lag_pol'OMEGA_lag_pol)*OMEGA_lag_pol'OMEGA
		XI  = OMEGA - OMEGA_lag_pol*g_b

		crit = (Z'XI)'(Z'XI)
	}

	void DLW_TRANSLOG()
	{
		S = optimize_init()
		optimize_init_evaluator(S, &GMM_DLW_TL())
		optimize_init_evaluatortype(S, "d0")
		optimize_init_technique(S, "nm")
		optimize_init_nmsimplexdeltas(S, 0.1)
		optimize_init_which(S, "min")
		optimize_init_conv_maxiter(S,1000)

		b = st_matrix("beta_ols_tl")
		optimize_init_params(S, b)

		p = optimize(S)
		st_matrix("beta_dlwtranslog", p)
	}

end

capture program drop dlw
program dlw, rclass
	sort `firm' year
	mata DLW()
end

capture program drop dlw_translog
program dlw_translog, rclass
	sort `firm' year
	mata DLW_TRANSLOG()
end

* ------------------------------------------------------------------------------
* Estimate by 2-digit sector (naf2d_num)
* ------------------------------------------------------------------------------

capture mkdir "${temp}"

levelsof naf2d_num if !missing(naf2d_num), local(indlist)
foreach i of local indlist {

	preserve
		keep if naf2d_num == `i'

		quietly count
		if r(N) < 50 {
			restore
			continue
		}

		* Higher-order terms (order 2)
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

		* Initial guesses
		quietly regress s v k m o
		matrix __b = e(b)
		matrix beta_ols_cd = __b[1,5], __b[1,1], __b[1,2], __b[1,3], __b[1,4]

		quietly regress s v k m o v2 k2 m2 o2 mv mo mk vo vk ok
		matrix __b = e(b)
		matrix beta_ols_tl = __b[1,15], __b[1,1], __b[1,2], __b[1,3], __b[1,4], __b[1,5], __b[1,6], __b[1,7], __b[1,8], __b[1,9], __b[1,10], __b[1,11], __b[1,12], __b[1,13], __b[1,14]

		* First stage (proxy) regression to obtain phi_it
		quietly regress s v k m o v2 k2 m2 o2 mv mo mk vo vk ok i.year ms5d
		predict double phi if e(sample)
		gen double phi_lag = l.phi

		* Lags and instruments (as in DGM code)
		gen double v_lag = l.v
		gen double k_lag = l.k
		gen double m_lag = l.m
		gen double o_lag = l.o

		gen double v_lag2 = v_lag^2
		gen double k_lag2 = k_lag^2
		gen double m_lag2 = m_lag^2
		gen double o_lag2 = o_lag^2

		gen double m_lagv_lag = m_lag*v_lag
		gen double m_lago_lag = m_lag*o_lag
		gen double m_lagk_lag = m_lag*k_lag
		gen double v_lago_lag = v_lag*o_lag
		gen double v_lagk_lag = v_lag*k_lag
		gen double o_lagk_lag = o_lag*k_lag

		gen double m_lagv = m_lag*v
		gen double m_lagk = m_lag*k
		gen double vo_lag = v*o_lag
		gen double o_lagk = o_lag*k

		sort `firm' year
		gen byte const = 1

		drop if s==.
		drop if v_lag==.
		drop if k==.
		drop if phi==.
		drop if phi_lag==.

		* GMM estimation in Mata
		dlw
		gen double beta_const_cd = beta_dlw[1,1]
		gen double beta_v_cd     = beta_dlw[1,2]
		gen double beta_k_cd     = beta_dlw[1,3]
		gen double beta_m_cd     = beta_dlw[1,4]
		gen double beta_o_cd     = beta_dlw[1,5]

		dlw_translog
		gen double beta_const_tl = beta_dlwtranslog[1,1]
		gen double beta_v_tl     = beta_dlwtranslog[1,2]
		gen double beta_k_tl     = beta_dlwtranslog[1,3]
		gen double beta_m_tl     = beta_dlwtranslog[1,4]
		gen double beta_o_tl     = beta_dlwtranslog[1,5]

		gen double beta_v2_tl    = beta_dlwtranslog[1,6]
		gen double beta_k2_tl    = beta_dlwtranslog[1,7]
		gen double beta_m2_tl    = beta_dlwtranslog[1,8]
		gen double beta_o2_tl    = beta_dlwtranslog[1,9]

		gen double beta_mv_tl    = beta_dlwtranslog[1,10]
		gen double beta_mo_tl    = beta_dlwtranslog[1,11]
		gen double beta_mk_tl    = beta_dlwtranslog[1,12]
		gen double beta_vo_tl    = beta_dlwtranslog[1,13]
		gen double beta_vk_tl    = beta_dlwtranslog[1,14]
		gen double beta_ok_tl    = beta_dlwtranslog[1,15]

		duplicates drop naf2d_num, force
		keep naf2d_num beta_*

		save "${temp}/coefficients_ind`i'.dta", replace
	restore
}

* Combine coefficient files
local combined 0
foreach i of local indlist {
	capture confirm file "${temp}/coefficients_ind`i'.dta"
	if _rc!=0 continue

	if `combined'==0 {
		use "${temp}/coefficients_ind`i'.dta", clear
		local combined 1
	}
	else {
		append using "${temp}/coefficients_ind`i'.dta"
	}
}
if `combined'==0 {
	di as error "No sector coefficients were produced; check sample size / missingness."
	error 2000
}

compress
save "./data/interim/firm_outcomes/03_dgm_coefficients_byind_revenue.dta", replace

* Clean up temporary coefficient shards
foreach i of local indlist {
	capture erase "${temp}/coefficients_ind`i'.dta"
}

/*END OF DOFILE*/
