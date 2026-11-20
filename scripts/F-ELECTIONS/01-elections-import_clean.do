* 23/07/2021
use "./data/external/import_casd/2009.dta", clear
drop if _n==1
drop if numsuffragesvalab > numvotants & !missing(numsuffragesvalab) 
* More valid votes than voters, that's very democratic of you! 
* Or maybe you just can't report election results properply but that's on you, I'm dropping you :)
* This represents ~100 elections (ie. arround 0.04% of our sample)

* NB: pas de doublon dans la base initiale in terms of all variables
* Mais j'ai remarqué que certaines lignes étaient strictement identiques, sauf pour le n° du deuxième tour (assez incompréhensible ???)
*=> drop les doublons après avoir viré cette variable
drop ele_num_t2
duplicates drop
* 10,939 observations deleted

gen siren = substr(siret,1,9)
destring siren, force replace
drop if siren==.

gen year = substr(datescrutin,1,4)
drop if year=="2013"

* Keep main elections only (drop élections partielles)
drop if partielcomplet == "P"


* DEFINITION DE VOTE CGT
* Erreur dans le précédent code : Clémence a utilisé le "codesyndicat == 001" pour définir CGT, alors qu'il existe de nombreux syndicats qui appartiennent à la confédération CGT sans être "001" pour code syndicat 
* => il faut utiliser le Code Confédération == 001
* Pb : codeconfederation n'est pas dans la base, mais on a la table de passage entre syndicats et confédérations.


 gen cgt = (regexm(libsyndicat,"CGT")==1)
 
 replace cgt = 1 if inlist(libsyndicat,"CGTM","FSE","FSPBA","SIASMS","SNEIP","SOMMMF","SPARTACR","SPEPSA","UGICT VOA")
 
 replace cgt = 0 if inlist(libsyndicat,"CGT DOUAI","CGT-FO", "CGT-GUY","CGTG","CGTM","CGTM-FSM","CGTM-CGSSM","CGT-G","CGT-FO-IEA")
 
  replace cgt = 0 if inlist(libsyndicat,"FE CGTG","FSAS-CGTG","FTC CGTG","UNSENRIC CGT-FO","UTG CSA CGT GUYANE 1ERE","SYNDICAT AUTONOME DU PERSONNEL DE LA SADE CGTH")

  
* Pour chaque élection : création d'une dummy "au moins un candidat CGT" 
* NB: 1 élection = 1 collège quand plusieurs, 1 siret, 1 année, 1 type de repréentation - DU, DP, CE
bys elenum: egen candidat_cgt = total(cgt)
replace candidat_cgt = (candidat_cgt>0)
label var candidat_cgt "At least one CGT candidate at the election"
   
* pour chaque élection : part du vote CGT-FO  

* NB: on doit d'abord sommer les scores des différents syndicats affilités CGT (différentes branches) pour une même élections
bys elenum cgt: egen temp = total(numbulletinsvalab) if cgt==1
replace numbulletinsvalab = temp if cgt==1
drop temp

gen total_vote_cgt = numbulletinsvalab if cgt==1
sort elenum total_vote_cgt
bys elenum: carryforward total_vote_cgt, replace



*assert candidat_cgt==0 if part_vote_cgt == .
*69 contradictions in 158,705 observations
*assertion is false
*pour la plupart, il s'agit d'élections où numsuffragesvalab==0
*pour 1 election: numsuffragesvalab==.

replace total_vote_cgt = 0 if missing(total_vote_cgt)
gen part_vote_cgt = total_vote_cgt / numsuffragesvalab
replace part_vote_cgt = 0 if numsuffragesvalab==0


* For each election : Dummy: "CGT vote share > 10%"
gen sup10_cgt = 1 if part_vote_cgt>=0.1 & part_vote_cgt!=.
replace sup10_cgt = 0 if part_vote_cgt < 0.1
label var sup10_cgt "CGT obtained more than 10% of votes"

keep siren siret year elenum effectif numinscrits numvotants numsuffragesvalab institution candidat_cgt part_vote_cgt total_vote_cgt sup10_cgt carence deno_college

duplicates drop

duplicates tag elenum, gen(dup)
assert dup==0
drop dup


* Nb total d'inscrits toutes institutions confondues, pour une même entreprise:
bys siren: egen numinscrit_tot_siren0912 = total(numinscrits), missing
bys siren: egen numvotants_tot_siren0912 = total(numvotants), missing
bys siren: egen numvalab_tot_siren0912 = total(numsuffragesvalab), missing
bys siren: egen numcgt_tot_siren0912 = total(total_vote_cgt), missing 


* Nb total d'inscrits, toutes institutions confondues, pour une mm SIREN, dont le candidat CGT correspondant a fait plus de 10% dans son collège:
gen numinscrit_sup10cgt = numinscrits * sup10_cgt
bys siren: egen nbinscrit_sup10cgt_siren0912 = total(numinscrit_sup10cgt)  

* Part des employés, tout collèges confondus qui ont élu un représentant (toute institution confondue) CGT avec plus de 10% des voix, pour un SIREN:
gen shinscrit_sup10cgt_siren0912 = nbinscrit_sup10cgt_siren0912 / numinscrit_tot_siren0912
label variable shinscrit_sup10cgt_siren0912 "Share of registered voters who eleceted a CGT representative with more than 10% of votes"

* Calcul de la participation au niveau SIREN, touts collèges confondus 
* Nb de votants tous collèges et institutions confondus:
gen participation_siren0912 = numvotants_tot_siren0912 / numinscrit_tot_siren0912

* Taux de blancs/nuls au niveau SIREN
gen bnuls_siren0912 = 1 - (numvalab_tot_siren0912 / numvotants_tot_siren0912)

* Taux CGT au niveau SIREN 
gen cgt_siren0912 = numcgt_tot_siren0912 / numvalab_tot_siren0912



* Carence 
destring carence, replace
gen numinscrit_carence = numinscrits * carence
bys siren: egen nbinscrit_carence_siren0912 = total(numinscrit_carence)  
gen shinscrit_carence_siren0912 = nbinscrit_carence_siren0912 / numinscrit_tot_siren0912

bys siren: egen mean_carence = mean(carence)
replace shinscrit_carence_siren0912 = 1 if mean_carence==1

label variable shinscrit_carence_siren0912 "Share of registered voters who did not have a candidate"

keep siren shinscrit_carence_siren0912 participation_siren0912 bnuls_siren0912 cgt_siren0912 shinscrit_sup10cgt_siren0912
duplicates drop 
drop if mi(shinscrit_carence_siren0912) | shinscrit_carence_siren0912<0

save "./data/interim/elections_pro/elections_siren_year_0912.dta", replace

/*END OF DOFILE*/
