* 23/07/2021
use "./data/external/import_casd/2009.dta", clear
drop if _n==1
* Missing inputs are handled per outcome below. Observed contradictions in
* election-wide counts instead invalidate the entire election report.

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

* Reject untrustworthy reports from EVERY outcome. Compare only observed
* counts: missing values alone are not evidence of a contradiction.
gen byte inconsistent_counts = ///
    (!missing(numvotants, numinscrits) & numvotants>numinscrits) | ///
    (!missing(numsuffragesvalab, numvotants) & numsuffragesvalab>numvotants) | ///
    numinscrits<0 | numvotants<0 | numsuffragesvalab<0 | numbulletinsvalab<0
* Counts repeat on union-list rows. If any row is contradictory, remove all
* rows of that election before summing CGT ballots; never retain a partial sum.
bys elenum: egen byte inconsistent_election = max(inconsistent_counts)
bys elenum: gen byte inconsistent_election_tag = inconsistent_election==1 & _n==1
quietly count if inconsistent_election_tag==1
display as text "Excluded elections with contradictory counts: " as result r(N)
drop if inconsistent_election==1
drop inconsistent_counts inconsistent_election inconsistent_election_tag


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
   
* Sum CGT lists within each election, before reducing to one election row.
* A partial sum is not a known total: preserve missingness if any CGT list
* has missing ballots. Negative counts have already been excluded above.
* Zero is justified when no CGT list is present,
* under the union classification above, or when all CGT ballots are known zero.
gen double cgt_ballots = numbulletinsvalab if cgt==1
gen byte cgt_ballots_unknown = cgt==1 & missing(numbulletinsvalab)
bys elenum: egen byte incomplete_cgt = max(cgt_ballots_unknown)
bys elenum: egen double total_vote_cgt = total(cgt_ballots)

replace total_vote_cgt = . if incomplete_cgt==1
replace total_vote_cgt = 0 if candidat_cgt==0

* CGT-specific inconsistencies invalidate this rate, not the whole election.
gen double part_vote_cgt = total_vote_cgt / numsuffragesvalab ///
    if !missing(total_vote_cgt, numsuffragesvalab) & numsuffragesvalab>0 ///
    & inrange(total_vote_cgt, 0, numsuffragesvalab)
gen byte sup10_cgt = (part_vote_cgt>=0.1) if !missing(part_vote_cgt)
* With zero valid and CGT votes, threshold success is zero but the vote
* share itself remains undefined; registered weights must not turn 0/0 into 0.
replace sup10_cgt = 0 if numsuffragesvalab==0 & total_vote_cgt==0
* Known absence of a CGT candidate implies no CGT threshold success,
* even when the valid-vote denominator is unreported.
replace sup10_cgt = 0 if candidat_cgt==0
label var sup10_cgt "CGT obtained at least 10% of votes"

keep siren siret year elenum effectif numinscrits numvotants numsuffragesvalab institution candidat_cgt part_vote_cgt total_vote_cgt sup10_cgt carence deno_college

duplicates drop

duplicates tag elenum, gen(dup)
assert dup==0
drop dup


* Election-level outcomes among the retained reports. Missing inputs or
* unusable denominators invalidate the relevant rate, never becoming zero.
gen double participation_elec = numvotants / numinscrits ///
    if !missing(numvotants, numinscrits) & numinscrits>0
gen double bnuls_elec = 1 - numsuffragesvalab / numvotants ///
    if !missing(numsuffragesvalab, numvotants) & numvotants>0
destring carence, replace
gen byte carence_elec = carence if inlist(carence, 0, 1)

* Firm electoral environment: weight every outcome by registered voters.
* Each outcome has its own observed rates. Missing registration counts propagate
* to both weighted quantities; zero counts contribute zero. Recompute the
* registration total for each outcome rather than reusing a different support.
local rates participation_elec bnuls_elec part_vote_cgt sup10_cgt carence_elec
local outcomes participation_siren0912 bnuls_siren0912 cgt_siren0912 ///
    shinscrit_sup10cgt_siren0912 shinscrit_carence_siren0912

forvalues j = 1/5 {
    local rate : word `j' of `rates'
    local outcome : word `j' of `outcomes'
    tempvar obs_weight weighted_value total_weight total_value

    gen double `obs_weight' = numinscrits if !missing(`rate')
    gen double `weighted_value' = `rate' * `obs_weight'
    bys siren: egen double `total_weight' = total(`obs_weight'), missing
    bys siren: egen double `total_value' = total(`weighted_value'), missing
    gen double `outcome' = `total_value' / `total_weight'

    * Verify the result; this assertion does not select or drop observations.
    assert inrange(`outcome', 0, 1) | missing(`outcome')
    drop `obs_weight' `weighted_value' `total_weight' `total_value'
}

* Preserve the all-failed exception only when EVERY recorded election
* explicitly reports failure. Unknown carence must not qualify as failure.
* If all elections failed, the share is one regardless of missing weights.
bys siren: egen byte all_failed = min(carence_elec==1)
replace shinscrit_carence_siren0912 = 1 if all_failed==1

label variable participation_siren0912 "Registered-voter-weighted turnout over elections with usable counts"
label variable bnuls_siren0912 "Registered-voter-weighted blank/invalid share over elections with usable counts"
label variable cgt_siren0912 "Registered-voter-weighted CGT vote share over elections with usable counts"
label variable shinscrit_sup10cgt_siren0912 "Share of registered voters covered by a known CGT result of at least 10%"
label variable shinscrit_carence_siren0912 "Share of registered voters without a candidate, among known election statuses"



keep siren shinscrit_carence_siren0912 participation_siren0912 bnuls_siren0912 cgt_siren0912 shinscrit_sup10cgt_siren0912
duplicates drop 
* Retain the existing final sample rule: the failure share must be observed.
drop if mi(shinscrit_carence_siren0912) | shinscrit_carence_siren0912<0

* Preserve the column order used to assign downstream regression model IDs.
order siren shinscrit_sup10cgt_siren0912 participation_siren0912 ///
    bnuls_siren0912 cgt_siren0912 shinscrit_carence_siren0912

save "./data/interim/elections_pro/elections_siren_year_0912.dta", replace

/*END OF DOFILE*/
