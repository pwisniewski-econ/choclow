/*______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
  
	Description: Crée les dates d'entrée et de sortie des individus dans le panel 
				 Permet notamment de calculer leur durée de tenure
				 NB: ce do-file est appelé dans 2_DispSample.do qui crée le panel de displaced workers
  
	
	INPUT:
		"${workingdata}/PAN17_`i'.dta", i in 19942001 20022007 20082012 20132017 [fichiers du Panel DADS 2017 qui sont créés par le code SAS "Export_panel.sas" dans "2_Displaced/SAS_PanelDADS".]
		"${miscdata}\01_AUZE_Commune.dta" [list of municipalities and employment zones, from INSEE]
			
	
	
	OUTPUT: "${workingdata}\pan_min.dta"
		  
  ______________________________________________________________________________
  ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/

 *SETUP*
clear


*	1.		KEEP PERIOD	
cap erase ./data/interim/mlo30/pan_min
foreach i in 20022007 20082012 20132019 {
	use nninouv SIR an NIC4 entsir entpan dept COMT NBHEUR DEBREMU FINREMU CONTRAT_TRAVAIL ANNAI SBR COMT NBSA_ENT  using ./data/external/sas_paneldads/PAN19_`i', clear
	rename *, lower
		
	duplicates drop
	
	gen com = dept+comt
	destring com, gen(insee) force
	merge m:1 insee using  "./data/external/01_AUZE_Commune.dta", keep(master matched) nogen keepusing(ze10)
	drop com
	
	destring sir, force replace
	drop if sir==.
	
	capture append using ./data/interim/mlo30/pan_min_temp
	
	duplicates drop
	save ./data/interim/mlo30/pan_min_temp, replace
	}
	*/
	
*	2.
	
use ./data/interim/mlo30/pan_min_temp, clear
	
merge m:1 nninouv sir an using ./data/interim/mlo30/mlo30_tenure, keep(master match) nogen keepusing(spell min_an_sir max_an_sir)


save ./data/interim/mlo30/pan_min.dta, replace
cap erase ./data/interim/mlo30/pan_min_temp.dta

/*END OF DOFILE*/
