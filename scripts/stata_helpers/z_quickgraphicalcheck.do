
/*
Sanity check 
*/


clear
do "C:\Users\Public\Documents\Layoffs\1_Paths.do"
cd ${LE}
set more off
set matsize 11000



global outg ${output}/Export20240214

*Chose between:
*S in LE MLO
*COND in All Log PreTrend Young 
*OUTCOME in labor firm Joint SectorBW
	*global outcome employed sbr sbrhour nbheur lnsbr lnnbheur lnsbrhour fe_current 
	*global outcome ln_* maxmfg* mfg* prod_res* separation* 

	*
foreach S in  MLO {
foreach COND in  Log {
foreach OUTCOME in Labor Firm {
global file event`OUTCOME'_`S'_`COND'
}
}


import excel using "${outg}/${file}.xls", clear first

set scheme s1color

global Paint tw (con coef dist, lc(blue) mc(blue)) (rcap ci_u ci_l dist, mc(blue) lc(blue))
global Option  yline(0, lc(black)) xline(0, lc(red))

*$Paint if Outcome=="ln_LRoll", $Option name(L`S', replace)
*$Paint if Outcome=="seprate0114", $Option name(sep14`S', replace)
*$Paint if Outcome=="seprate0104", $Option name(sep04`S', replace)
*$Paint if Outcome=="fe0104", $Option name(L`S', replace)
*$Paint if Outcome=="fe0115", $Option name(L`S', replace)
$Paint if Outcome=="fe0215_god", $Option name(L`S', replace)
*$Paint if Outcome=="lnnbheur", $Option name(L`S', replace)
*$Paint if Outcome=="lnsbrhour", $Option name(L`S', replace)
*$Paint if Outcome=="lnsbr", $Option name(L`S', replace)
*$Paint if Outcome=="prod_resRoll", $Option name(prod`S', replace)
*$Paint if Outcome=="ln_Kinc_ratio", $Option name(intratio`S', replace)
*$Paint if Outcome=="ln_Kinc_ratio_yres", $Option name(resintratio`S', replace)
$Paint if Outcome=="effsalmRoll", $Option name(L`S', replace)


/*
*Flow mat
$Paint if Outcome=="flowmat2_dum1", $Option name(dum1`S', replace) legend(off) title("FE1,Prod1")
$Paint if Outcome=="flowmat2_dum2", $Option name(dum2`S', replace) legend(off) title("FE1,Prod2")
$Paint if Outcome=="flowmat2_dum3", $Option name(dum3`S', replace) legend(off) title("FE2,Prod1")
$Paint if Outcome=="flowmat2_dum4", $Option name(dum4`S', replace) legend(off) title("FE2,Prod2")
$Paint if Outcome=="resid_Nocond", $Option name(dum4`S', replace) legend(off) title("Residualized Premium") yline(-0.0759474486112595,lc(green))
*/

/*Between, within
$Paint if Outcome=="d3FE_ln_Lshare", $Option name(Lshare_fe`S', replace) legend(order(1 "3d FE"))
$Paint if Outcome=="d3res_ln_Lshare", $Option name(Lshare_res`S', replace) legend(order(1 "3d res"))
$Paint if Outcome=="d3FE_firm_fe", $Option name(FE_fe`S', replace) legend(order(1 "3d FE"))
$Paint if Outcome=="d3res_firm_fe", $Option name(FE_res`S', replace) legend(order(1 "3d res"))
$Paint if Outcome=="d3FE_prod_res", $Option name(Prod_fe`S', replace) legend(order(1 "3d FE"))
$Paint if Outcome=="d3res_prod_res", $Option name(Prod_res`S', replace) legend(order(1 "3d res"))
*/
}
tokoss

graph combine Lshare_feLE Lshare_resLE, ycom title(LShare)
graph combine Prod_feLE Prod_resLE, ycom title(Prod)
graph combine FE_feLE FE_resLE, ycom title(Premium)

graph combine dum1LE dum2LE dum3LE dum4LE, ycom row(2) 
