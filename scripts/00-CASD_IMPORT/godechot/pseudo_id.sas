****************************************************************
* SCRIPT pseudo_id.sas 2022/10/15 (V2.12)                      *
* Olivier Godechot                                             *
* Email: Olivier.Godechot [at] sciencespo.fr                   *
****************************************************************
* CREATES A COMMON PSEUDO IDENTIFIER IN THE DADS FILES         * 
****************************************************************

The SAS program pseudo_id.sas is a program for the CASD platform which creates 
a common identifier IDENT_ALL in the DADS files thanks to overlapping 
information between year t-1 of yearfile y and year t of yearfile y-1.
It enables to chain stayers and movers from 2002 to 2020 
(provided movers reappear in the DADS perimeter in less than one year). 
Before 2001, while we cannot chain movers (who change workplace), we can still chain stayers.

* Possible updates can be found here : http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip

* It comes with 3 joint programs : 

	* 1. pseudo_id_seniority.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		which calculates the year of entry in the firm and the establishment and enables to 
		calculate seniority.

	* 2. pseudo_id_foreign_born.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		which corrects information on foreign and over-sea borns and citizenship which is obviously incorrect
		for some years.

	* 3. pseudo_id_use.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		which gives an example of creating a dads files with common identifiers.


****************************************************************
* HOW TO RUN THE PROGRAM  
****************************************************************

	* The program comes into two parts. 

		* 1. Resolve the macros scripts. 

		* 2. Run the macros with your own parameters

			- a. Create the libnames

				%my_libnames(casd_project=A0INEPR) 

				* !!!! CHANGE A0INEPR !!! with the name of your CASD project (written on your CASD card)

			- b. Chaining two year files
			The macro %psid_2(1995) to %psid_3(2020) will match regional yearfiles y with yearfile y-1. 
			(So if you need to have a common id for two yearfiles, this might be sufficient.

			- c. Creating a common identifiers to all year files. 
			%psid_4(y=1996,last=0) to %psid_4(y=2020,last=psid.psid_2019) creates a common identifier IDENT_ALL for all years

*****************************************************************************
* OUTPUT 
*****************************************************************************
	* The program will create psid_yyyy.sas7bdat files in the CASD common folder : 
		C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads

				* In the psid_yyyy.sas7bdat files, we keep 2 variables : 
				* IDENT_S : yearfile  identifier of the year 
						* From 1994 to 2001, there's no IDENT_S variables in the DADS.
						* We create an IDENT_S variable as follows: 
              Row number of year of entry file * 100 + Region of work 

				* IDENT_ALL : the common identifier we created
					IDENT_ALL is created as follows:
            IDENT_ALL = IDENT_S * 100 + 2-digit year of entry. 

	* It also creates control files for quality of the match  
		C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\ctrl\

	* The log file is also stored in C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\ctrl\

******************************************************************************
* SPACE AND TIME REQUIREMENTS 
******************************************************************************
	* TIME: Approximately 10 hours on a casd platform with 8 MO ram. 
	* SPACE: At least 20 go hard drive available to RUN it smoothly
	* STORAGE: 11 Go 

******************************************************************************
* HOW TO USE THE psid_yyyy FILES : 
******************************************************************************
	* In the psid_yyyy.sas7bdat files you will only have year t-1 employees of yearfile y that were succefully 
	* chained (i.e. a unique match) with year t employees of yearfile y-1. Therefore, to use this chaining you must : 

	* 1. KEEP all t employees from DADS year files y, match them with psid_yyyy.sas7bdat. 
		* with IDENT_S both in the DADS file and the psid file.

	* 2. CREATE an IDENT_ALL variable for all employees that were NOT matched in stage 1
		* adding the the 2-digit year of the yearfile to the end of the IDENT_S variable
		*  You can use the the following formula : 
			 if MISSING(IDENT_ALL) then IDENT_ALL=100*IDENT_S+(year>=2000)*(year-2000)+(year<2000)*(year-1900)
		* Before 2002, create before an IDENT_S in EACH regional file (before appending them): 
				ident_s=_N_*100+REGT

	* You can also use : pseudo_id_use.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
	
******************************************************************************
* WARNINGS AND DISCLAIMERS
******************************************************************************
	* This program comes with absolutely no warranty of accurateness

	* It can still be improved. Here are a few issues :

		* We do a chaining on employees' regional top wages (we could do it on all wages and 
		select the one with top wages in the end).

		* We exclude multiple matches instead of trying to find the most relevant.

		* When employees have jobs in two different regions producing two different unique regional matches, 
		we drop them from the match (instead of selecting "the best" one). 

		* In 2002, the match is difficult due to a change in the series. We dropped NBHEUR 
		and SONDE from the matching key.

		* We use a double condition for the match (<2014) : 
			closest wage AND absolute age difference<2. 
			
      => This double condition might exclude some possible matches.

		* After 2014 we introduce a triple condition for the match : 
				closest wage AND closest number of hours AND absolute age difference<2. 
				
      => This triple condition might also restrict the number of matches.

		* For employees not matched, we did not try to find better matches by diminishing 
		the number of variables in the matching key.

*****************************************************************************
* HOW TO CITE : 
*****************************************************************************
	Babet, Damien, Olivier Godechot and Marco G. Palladino, 2022. In the 
	Land of AKM: Explaining the Dynamics of Wage Inequality in France, 
	Document de travail, Insee (forthcoming). 

******************************************************************************
* UPDATES
******************************************************************************

2022/10/11. Changing Francs to Euros for the 1999-2000 match.

2022/10/13. Bug corrected in %psid_4 which led to a crash in 
the production of psid_yyyy files after 1996.

2022/10/15. Improving 2015 match by 10 percentage points by dropping the number 
of hours criteria


******************************************************************************************************************************;

******************************************************************************;
* 1. MACROS SCRIPTS TO RESOLVE;
******************************************************************************;
	* Select (Keys: shift + arrows) and execute (Key: F3) the following lines to resolve the macros;

	* MACRO MY_LIBNAMES;
	
	%MACRO my_libnames(casd_project); 
		OPTIONS PS=MAX LS=MAX NODATE NONUMBER NOCENTER DLCREATEDIR;

		libname psid "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads"; *Folder in the common space where ID files will be stored;
		libname ctrl "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\ctrl"; *Statistics on quality of the match;
		libname po2018 "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\DADS_2018"; *Folders where regional files are recreated for 2018;
		libname po2019 "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\DADS_2019"; *Folders where regional files are recreated for 2019;
		libname po2020 "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\DADS_2020"; *Folders where regional files are recreated for 2020;

		*DADS Libnames, full france;
		libname po1994 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_1994";
		libname po1995 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_1995";
		libname po1996 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_1996";
		libname po1997 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_1997";
		libname po1998 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_1998";
		libname po1999 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_1999";
		libname po2000 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2000";
		libname po2001 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2001";
		libname po2002 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2002";
		libname po2003 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2003";
		libname po2004 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2004";
		libname po2005 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2005";
		libname po2006 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2006";
		libname po2007 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2007";
		libname po2008 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2008";
		libname po2009 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2009";
		libname po2010 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2010";
		libname po2011 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2011";
		libname po2012 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2012";
		libname po2013 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2013";
		libname po2014 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2014\Régions";
		libname po2015 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2015\Régions";
		libname pob2016 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2016\Versions\V1";
		libname po2016 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2016\Régions";
		libname po2017 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2017\Régions";
		libname po2018B "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2018";
		libname po2019B "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2019";
		libname po2020B "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2020";

		*Paris region libnames;
		libname pi2012 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2012\Ile de France";
		libname pi2013 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2013\Ile de France";
		libname pi2014 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2014\Départements";
		libname pi2015 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2015\Départements";
		libname pi2016 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2016\Départements";
		libname pi2017 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2017\Départements";
	%MEND;


	PROC FORMAT; 
		value mynb
		5-100000="5&more";

		value mynb_b
		.="not matched"
		1="unique match";
	RUN;


	%MACRO idf_1(y_1);
		%let y_12=%substr(&y_1,3,2);
		%if &y_1>2011 %then %do;
			DATA idf&y_12;SET
				pi&y_1..post75 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT where=(DEPT="75"))
				pi&y_1..post77 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT where=(DEPT="77"))
				pi&y_1..post78 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT where=(DEPT="78"))
				pi&y_1..post91 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT where=(DEPT="91"))
				pi&y_1..post92 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT where=(DEPT="92"))
				pi&y_1..post93 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT where=(DEPT="93"))
				pi&y_1..post94 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT where=(DEPT="94"))
				pi&y_1..post95 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT where=(DEPT="95"))
			;
			RUN;
		%end;

		%if &y_1=2009 or &y_1=2010 %then %do;
			DATA idf&y_12;SET
				po&y_1..post11aa (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE )
				po&y_1..post11bb (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE )
				po&y_1..post11cc (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE )
				po&y_1..post11dd (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE )
			;
			RUN;
		%end;
	%MEND;

	%MACRO idf(y);
		%let y2=%substr(&y,3,2);
		%if &y>2011 %then %do;
			DATA idf&y2 ; SET
					pi&y..post75 (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
				REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1 where=(DEPT_1="75") )
					pi&y..post77 (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
				REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1 where=(DEPT_1="77"))
					pi&y..post78 (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
				REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1 where=(DEPT_1="78"))
					pi&y..post91 (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
				REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1 where=(DEPT_1="91"))
					pi&y..post92 (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
				REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1 where=(DEPT_1="92"))
					pi&y..post93 (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
				REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1 where=(DEPT_1="93"))
					pi&y..post94 (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
				REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1 where=(DEPT_1="94"))
					pi&y..post95 (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
				REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1 where=(DEPT_1="95"))
				;
			RUN;
		%end;
		%if &y=2009 or &y=2010 %then %do;
			DATA idf&y2 ; SET
				po&y..post11aa (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
			REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE )
				po&y..post11bb (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
			REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE )
				po&y..post11cc (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
			REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE )
				po&y..post11dd (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
			REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE )
			;
			RUN;
		%end;
	%MEND;

	%MACRO rh_1(y_1);
		%let y_12=%substr(&y_1,3,2);
			DATA rh&y_12;SET
				po&y_1..post82a (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE )
				po&y_1..post82b (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE )
			;
				
			RUN;
	%MEND;

	%MACRO rh(y);
		%let y2=%substr(&y,3,2);
		DATA rh&y2;SET
				po&y..post82a (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
			REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE)
				po&y..post82b (keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 COMT_1 PCS_1 SONDE_1
			REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE)
			;
		RUN;
	%MEND;

	%MACRO newreg(reg);
		%if &reg=27 %then %do;
			DATA newreg&reg;SET
				po2013.post26 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="26"))
				po2013.post43 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="43"))
				;
				REGT="27";
			RUN;
		%end;
		%else %if &reg=28 %then %do;
			DATA newreg&reg;SET
				po2013.post23 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="23"))
				po2013.post25 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="25"))
			;
				REGT="28";
			RUN;
		%end;
		%else %if &reg=32 %then %do;
			DATA newreg&reg;SET
				po2013.post22 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="22"))
				po2013.post31 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="31"))
				;
				REGT="32";
			RUN;
		%end;
		%else %if &reg=44 %then %do;
			DATA newreg&reg;SET
				po2013.post21 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="21"))
				po2013.post41 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="41"))
				po2013.post42 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="42"))
				;
				REGT="44";
			RUN;
		%end;
		%else %if &reg=75 %then %do;
			DATA newreg&reg;SET
				po2013.post54 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="54"))
				po2013.post72 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="72"))
				po2013.post74 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="74"))
				;
				REGT="75";
			RUN;
		%end;
		%else %if &reg=76 %then %do;
			DATA newreg&reg; SET
				po2013.post73 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="73"))
				po2013.post91 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="91"))
				;
				REGT="76";
			RUN;
		%end;
		%else %if &reg=84 %then %do;
			DATA newreg&reg; SET
				po2013.post82 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="82"))
				po2013.post83 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE WHERE=(REGT="83"))
				;
				REGT="84";
			RUN;
		%end;
	%MEND;

	%MACRO old_1(reg,y_1);
	%let y_12=%substr(&y_1,3,2);
		DATA old&y_12;
			SET	po&y_1..post&reg.&y_12 (
			RENAME=(DEBREMU=DATDEB FINREMU=DATFIN COMR=COMR_ REG=REGT BRUT=S_BRUT ) 
			keep=SEXE &SIREN &NIC NBHEUR DEBREMU FINREMU DUREE COMR COM REG BRUT AGE DEPR DEP )
			;
			%if (&y_1=1999) %then %do; 
        S_BRUT=S_BRUT/6.55957;
			%end;
			%if (&y_1=2001) %then %do; 
				SIREN=COMPRESS(substr(SIREN,2,9));
				NIC=COMPRESS(substr(NIC,2,5));

				DEPR=TRANWRD(DEPR,"9A","97");
				DEPR=TRANWRD(DEPR,"9B","97");
				DEPR=TRANWRD(DEPR,"9C","97");
				DEPR=TRANWRD(DEPR,"9D","97");
				DEP=TRANWRD(DEP,"9A","97");
				DEP=TRANWRD(DEP,"9B","97");
				DEP=TRANWRD(DEP,"9C","97");
				DEP=TRANWRD(DEP,"9D","97");

			%end;
			%if (&y_1=1994) %then %do;
				DEPR=TRANWRD(DEPR,"2A","20");
				DEPR=TRANWRD(DEPR,"2B","20");
				DEP=TRANWRD(DEP,"2A","20");
				DEP=TRANWRD(DEP,"2B","20");
			%end;
			IDENT_S=_N_;
			COMR=DEPR!!COMR_;
			COMT=DEP!!COM;
			%if (&y_1=1994 and &reg=94) %then %do;
				COMT="20000";
			%end;
			SONDE=0;
			PPS="1";
			Drop COM COMR_ DEPR DEP;
		RUN;
	%MEND;

	%MACRO old(reg,y);
		%let y2=%substr(&y,3,2);
		DATA old&y2;SET
			po&y..post&reg.&y2 (
			RENAME=(DEBREM_1=DATDEB_1 FINREM_1=DATFIN_1 COMR_1=COMR__1 REG=REGT_1 BRUT_1=S_BRUT_1 ) 
			keep=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DEBREM_1 FINREM_1 DUREE_1 COMR_1 COM REG BRUT_1 AGE DEPR_1 DEP)
			;
			IDENT_S=_N_;
			%if (&y=1995) %then %do;
				DEPR_1=TRANWRD(DEPR_1,"2A","20");
				DEPR_1=TRANWRD(DEPR_1,"2B","20");
				DEP=TRANWRD(DEP,"2A","20");
				DEP=TRANWRD(DEP,"2B","20");
			%end;
			%if (&y=1996) %then %do;
				DEPR_1=TRANWRD(DEPR_1,"9A","97");
				DEPR_1=TRANWRD(DEPR_1,"9B","97");
				DEPR_1=TRANWRD(DEPR_1,"9C","97");
				DEPR_1=TRANWRD(DEPR_1,"9D","97");
				DEP=TRANWRD(DEP,"9A","97");
				DEP=TRANWRD(DEP,"9B","97");
				DEP=TRANWRD(DEP,"9C","97");
				DEP=TRANWRD(DEP,"9D","97");
			%end;

			COMR_1=DEPR_1!!COMR__1;
			COMT_1=DEP!!COM;
			%if (&y=1995 and &reg=94) %then %do;
				COMT_1="20000";
			%end;
			SONDE_1=0;
			PPS_1="1";
			Drop COM COMR__1 DEPR_1 DEP ;
		RUN;
	%MEND;


	%MACRO full2reg_1 (y_1);
			%if &y_1>2017 %then %do; 
				%let SIREN=SIREN_EMPL;
				%let NIC=NIC_EMPL;
			%end;
			%else %do; 
				%let SIREN=SIREN;
				%let NIC=NIC;
			%end;

			DATA po&y_1..post11
						po&y_1..post24 po&y_1..post27 po&y_1..post28 po&y_1..post32 po&y_1..post44 
						po&y_1..post52 po&y_1..post53 po&y_1..post75 po&y_1..post76 
						po&y_1..post84 po&y_1..post93 po&y_1..post94 po&y_1..post97 po&y_1..post99 
			 ; 
			%if &y_1>=2020 %then %do; 
			SET
						po&y_1.B.post (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT );
			%end;
			%else %do; 
			SET
						po&y_1.B.post_1 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT )
						po&y_1.B.post_2 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT )
						po&y_1.B.post_3 (keep=SEXE &SIREN &NIC  NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT )
						po&y_1.B.post_4 (keep=SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE REGT S_BRUT PPS IDENT_S AGE DEPT )
						;
			%end;
			%if &y_1>2018 %then %do; 
				informat COMT_1 $6.;
			%end;

				if REGT ="11" then output po&y_1..post11 ;
				else if REGT ="24" then output po&y_1..post24 ;
				else if REGT ="27" then output po&y_1..post27 ;
				else if REGT ="28" then output po&y_1..post28 ;
				else if REGT ="32" then output po&y_1..post32 ;
				else if REGT ="44" then output po&y_1..post44 ;
				else if REGT ="52" then output po&y_1..post52 ;
				else if REGT ="53" then output po&y_1..post53 ;
				else if REGT ="75" then output po&y_1..post75 ;
				else if REGT ="76" then output po&y_1..post76 ;
				else if REGT ="84" then output po&y_1..post84 ;
				else if REGT ="93" then output po&y_1..post93 ;
				else if REGT ="94" then output po&y_1..post94 ;
				else if REGT IN ("01","02","03","04","05","06","97","98") then output po&y_1..post97 ;
				else if REGT IN ("00","99") then output po&y_1..post99 ;
			RUN;
	%MEND;

	%MACRO full2reg (y);
			%if &y>2018 %then %do; 
				%let SIREN_1=SIREN_EMPL_1;
				%let NIC_1=NIC_EMPL_1;
			%end;
			%else %do; 
				%let SIREN_1=SIREN;
				%let NIC_1=NIC;
			%end;
			DATA po&y..post11 
						po&y..post24 po&y..post27 po&y..post28 po&y..post32 po&y..post44 
						po&y..post52 po&y..post53 po&y..post75 po&y..post76 
						po&y..post84 po&y..post93 po&y..post94 po&y..post97 po&y..post99 
			 ; 
			%if &y>=2020 %then %do; 
							SET po&y.B.post (KEEP=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 
											COMT_1 SONDE_1 REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1
										where=(S_BRUT_1>0 and NBHEUR_1>0 and AGE>0 and &SIREN_1 NE "000000000" ));

			%end;
			%else %do;
							SET po&y.B.post_1 (KEEP=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 
											COMT_1 SONDE_1 REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1
										where=(S_BRUT_1>0 and NBHEUR_1>0 and AGE>0 and &SIREN_1 NE "000000000" ))
								po&y.B.post_2 (KEEP=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 
											COMT_1 SONDE_1 REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1
										where=(S_BRUT_1>0 and NBHEUR_1>0 and AGE>0 and &SIREN_1 NE "000000000" ))
								po&y.B.post_3 (KEEP=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 
											COMT_1 SONDE_1 REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1
										where=(S_BRUT_1>0 and NBHEUR_1>0 and AGE>0 and &SIREN_1 NE "000000000" ))
								po&y.B.post_4 (KEEP=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 
											COMT_1 SONDE_1 REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE DEPT_1
										where=(S_BRUT_1>0 and NBHEUR_1>0 and AGE>0 and &SIREN_1 NE "000000000" )); 
			%end;
			%if &y>2018 %then %do; 
				informat COMT_1 $6.;
			%end;

			if regT_1 ="11" then output po&y..post11 ;
			else if regT_1 ="24" then output po&y..post24 ;
			else if regT_1 ="27" then output po&y..post27 ;
			else if regT_1 ="28" then output po&y..post28 ;
			else if regT_1 ="32" then output po&y..post32 ;
			else if regT_1 ="44" then output po&y..post44 ;
			else if regT_1 ="52" then output po&y..post52 ;
			else if regT_1 ="53" then output po&y..post53 ;
			else if regT_1 ="75" then output po&y..post75 ;
			else if regT_1 ="76" then output po&y..post76 ;
			else if regT_1 ="84" then output po&y..post84 ;
			else if regT_1 ="93" then output po&y..post93 ;
			else if regT_1 ="94" then output po&y..post94 ;
			else if regT_1 IN ("01","02","03","04","05","06","97","98") then output po&y..post97 ;
			else if regT_1 IN ("00","99") then output po&y..post99 ;
		RUN;
	%MEND;




	%MACRO psid(reg,y);
		%if &reg=97 %then %let regbis="01","02","03","04","05","06","97";
		%else %if &reg=99 %then %let regbis="00","99";
			%else %let regbis="&reg";
		%if &y>2018 %then %do; 
				%let SIREN_1=SIREN_EMPL_1;
				%let NIC_1=NIC_EMPL_1;
				%let SIREN=SIREN_EMPL;
				%let NIC=NIC_EMPL;

			%end;
			%else %do;
				%let SIREN=SIREN;
				%let NIC=NIC;
				%let SIREN_1=SIREN;
				%let NIC_1=NIC;
			%end;

		%let del=%str();
		%let del_1=%str();
		%let y=%eval(&y);
		%let y_1=%eval(&y-1);
		%let y_12=%substr(&y_1,3,2);
		%let y2=%substr(&y,3,2);
		%let reg=%eval(&reg);
		%let file_1=%str(po&y_1..post&reg.&y_12);

		%if &y_1>2008 %then %let file_1=%str(po&y_1..post&reg);

		%if ((&y_1=2009 or &y_1=2010 or (&y_1>2011 and &y_1<2018 )) and &reg=11) %then %do;
			%idf_1(&y_1);
			%let file_1=idf&y_12;
			%let del_1=&file_1;
		%end;

		%if (&y_1=2010 and &reg=82) %then %do;
			%rh_1(&y_1);
			%let file_1=rh&y_12;
			%let del_1=&file_1;
		%end;
		%if (&y_1=2013 and (&reg=27 or &reg=28 or &reg=32 or &reg=44 or &reg=75 or &reg=76 or &reg=84)) %then %do;
			%newreg(&reg);
			%let file_1=%str(newreg&reg);
			%let del_1=&file_1;
		%end;
		%if (&y_1<2002) %then %do;
			%old_1(&reg,&y_1);
			%let file_1=old&y_12;
			%let del_1=&file_1;
		%end;

		%let file=%str(po&y..post&reg.&y2);
		%if (&y>2008) %then %let file=%str(po&y..post&reg);

		%if ((&y=2009 or &y=2010 or (&y >2011 And &y< 2018)) and &reg=11) %then %do;
			%idf(&y);
			%let file=idf&y2;
			%let del=&file;
		%end;
		%if (&y=2010 and &reg=82) %then %do;
			%rh(&y);
			%let file=rh&y2;
			%let del=&file;
		%end;
		%if (&y<2002) %then %do;
			%old(&reg,&y);
			%let file=old&y2;
			%let del=&file;
		%end;

		DATA a; 
			%if &y_1>2017 %then %do; 
				%let SIREN=SIREN_EMPL;
				%let NIC=NIC_EMPL;
			%end;
			%else %do;
				%let SIREN=SIREN;
				%let NIC=NIC;
			%end;
				SET &file_1 (KEEP= SEXE &SIREN &NIC NBHEUR DATDEB DATFIN DUREE COMR COMT SONDE
										REGT S_BRUT PPS IDENT_S AGE
								where=(S_BRUT>0 and NBHEUR>0 and AGE>0 and &SIREN NE "000000000"
										AND REGT IN (&regbis))) ;
				%if &y_1<2001 %then %do;
					&SIREN=compress(substr(&SIREN,2,9));
					&NIC=Compress(SUBSTR(&NIC,2,6));
				%end;
				%if &y_1<2012 and &y_1 NE 2001 and &y_1 NE 1994 %then %do;
				pseudoid=COMPRESS(SEXE!!"#"!!&SIREN!!"#"
				!!&NIC!!"#"!!ROUND(NBHEUR,1)!!"#"!!DATDEB!!"#"!!DATFIN!!"#"!!DUREE !! "#"
				!!COMR!!"#"!!COMT !! "#" !! SONDE);
				%end;
				%else %if &y_1=2012 %then %do;
				pseudoid=COMPRESS(SEXE!!"#"!!&SIREN!!"#"
				!!&NIC!!"#"!!ROUND(NBHEUR,1)!!"#"!!DATDEB!!"#"!!DATFIN!!"#"!!DUREE !! "#"
				!!COMR!!"#"!!COMT);
				%end;
				%else %if &y_1 = 2001 OR &y_1 = 1994 %then %do;;
					pseudoid=COMPRESS(SEXE!!"#"!!&SIREN!!"#"
					!!&NIC!!"#"!!DATDEB!!"#"!!DATFIN!!"#"!!DUREE !! "#"
					!!COMR!!"#"!!COMT);
				%end;
				%else %do;
					pseudoid=COMPRESS(SEXE!!"#"!!&SIREN!!"#"
					!!&NIC!!"#"!!DATDEB!!"#"!!DATFIN!!"#"!!DUREE !! "#"
					!!COMR!!"#"!!COMT !! "#" !! SONDE);
				%end;
				id2=_N_;
				random=ranuni(46546);
			RUN;

		DATA b;
			SET &file (KEEP=SEXE &SIREN_1 &NIC_1 NBHEUR_1 DATDEB_1 DATFIN_1 DUREE_1 COMR_1 
									COMT_1 SONDE_1 REGT_1 S_BRUT_1 PPS_1 IDENT_S AGE
								where=(S_BRUT_1>0 and NBHEUR_1>0 and AGE>0  and &SIREN_1 NE "000000000"
								 		AND REGT_1 IN (&regbis))) ;
			%if &y<2002 %then %do;
				&SIREN_1=compress(substr(&SIREN_1,2,9));
				&NIC_1=Compress(SUBSTR(&NIC_1,2,6));
			%end;
			%if &y<2013 and &y NE 2002 and &y NE 1995 %then %do;
				pseudoid=COMPRESS(SEXE!!"#"!!&SIREN_1!!"#" !!&NIC_1!!"#"!!ROUND(NBHEUR_1,1)!!"#"
								!!DATDEB_1!!"#"!!DATFIN_1!!"#"!!DUREE_1!! "#"
								!! COMR_1!!"#"!!COMT_1!!"#" !! SONDE_1);
			%end;
			%else %if &y=2013 %then %do;
				pseudoid=COMPRESS(SEXE!!"#"!!&SIREN_1!!"#" !!&NIC_1!!"#"!!ROUND(NBHEUR_1,1)!!"#"
								!!DATDEB_1!!"#"!!DATFIN_1!!"#"!!DUREE_1!! "#"
								!! COMR_1!!"#"!!COMT_1);
			%end;
			%else %if &y=2002 OR  &y=1995 %then %do;
				pseudoid=COMPRESS(SEXE!!"#"!!&SIREN_1!!"#" !!&NIC_1!!"#"
								!!DATDEB_1!!"#"!!DATFIN_1!!"#"!!DUREE_1!! "#"
								!! COMR_1!!"#"!!COMT_1);
			%end;
			%else %do;
				pseudoid=COMPRESS(SEXE!!"#"!!&SIREN_1!!"#" !!&NIC_1!!"#"
								!!DATDEB_1!!"#"!!DATFIN_1!!"#"!!DUREE_1!! "#"
								!! COMR_1!!"#"!!COMT_1!!"#" !! SONDE_1);
			%end;
			id2_B=_N_;
			random=ranuni(87989);
		RUN;

		PROC SQL;
			CREATE TABLE a1 (where=(max_s_brut=s_brut))  AS SELECT *, Max(S_BRUT) as max_s_brut from a group by IDENT_S;
	 		CREATE TABLE b1 (where=(max_s_brut_1=s_brut_1)) AS SELECT *, Max(S_BRUT_1) as max_s_brut_1 from b group by IDENT_S;
		QUIT;

		PROC DATASETS lib=work memtype=data ;
		 delete A &del_1 &del;
		RUN;

		RUN;

		%if &y>2013 %then %let having=AND ABS(aa.nbheur-bb.nbheur_1)=MIN(ABS(aa.nbheur-bb.nbheur_1));
		%else %let having=;

		PROC SQL;
		CREATE TABLE ab (drop=pseudoid pseudoid_b S_BRUT S_BRUT_1 AGE) AS SELECT *
				from a1 (keep=pseudoid s_brut IDENT_S ID2 REGT AGE NBHEUR) as aa
				full join 
					b1 (keep=pseudoid s_brut_1 IDENT_S ID2_B AGE NBHEUR_1
						rename=(pseudoid=pseudoid_b IDENT_S=IDENT_S_B AGE=AGE_B)) as bb
			on aa.pseudoid=bb.pseudoid_B
				GROUP BY aa.S_BRUT,aa.PSEUDOID
					having ABS(aa.s_brut-bb.s_brut_1)=MIN(ABS(aa.s_brut-bb.s_brut_1))
					&having
					AND (0<=bb.AGE_B-aa.AGE<2 or AGE_B=. or AGE=.)
						ORDER BY aa.PSEUDOID,bb.s_brut_1;
		QUIT; 
		PROC DATASETS lib=work memtype=data ;
			delete A1 B1 ; 
		RUN;


		PROC SQL; 
			CREATE TABLE ab2 AS SELECT *, SUM(ID2>0) as nbID2_A
			from ab group by ID2; 
			CREATE TABLE ab3 AS SELECT *, SUM(ID2_B>0) as nbID2_B  
			from ab2 group by ID2_b; 
		QUIT;

		PROC DATASETS lib=work memtype=data ;
			delete AB AB2 ; 
		RUN;

		PROC freq data=ab3 noprint; tables NBID2_A*NBID2_B / out=ctrl.match_topjob_&reg._&y; 
			title "region &reg line match fileyears &y_1 &y year &y_1" ;	
			format NBID2_A NBID2_B mynb.;
		RUN;
		
		DATA ctrl.match_topjob&reg._&y; SET ctrl.match_topjob_&_reg._&y;
      NBMATCH_Y_1T=PUT(NBID2_A,mynb.);
      NBMATCH_YT_1=PUT(NBID2_B,mynb.);
      REGT=&reg;
      MATCH=compress( &y_1 !! "-" !! &y );
      DROP NBID2_A NBID2_B;
		RUN;

		%if (&y>2002) %then %do;
		PROC SQL;
			CREATE TABLE ab4 AS SELECT MIN(IDENT_S) as IDENT_S, 
									  MIN(IDENT_S_B) as IDENT_S_B, 
									  MIN(REGT) AS REGT 
										from ab3 (where=(nbID2_B=1 and nbID2_A=1)) 
											GROUP BY IDENT_S, IDENT_S_B;
			CREATE TABLE ab5 AS SELECT *, SUM(IDENT_S>0) as nbID3_A 
				from ab4 group by IDENT_S; 
				CREATE TABLE ab6 AS SELECT *, SUM(IDENT_S_B>0) as nbID3_B
				from ab5 group by IDENT_S_B; 
			QUIT;
			PROC DATASETS lib=work memtype=data ;
				delete AB4 AB5 ; 
			RUN;

		%end;
		%else %do;
			data ab6; SET ab3 (where=(nbID2_B=1 and nbID2_A=1));
			NBID3_A=1;NBID3_B=1;
			RUN;
		%end;


		PROC DATASETS lib=work memtype=data ;
			delete AB3  ; 
		RUN;

		PROC SQL; 
			CREATE TABLE ab7 AS SELECT * from b (keep=IDENT_S) as aa
				LEFT JOIN ab6 (keep=NBID3_B NBID3_A IDENT_S_B where=(NBID3_A=1 and NBID3_B=1)) as bb
			on aa.ident_s=bb.ident_s_b;
		QUIT;

		PROC DATASETS lib=work memtype=data ;
			delete B; 
		RUN;

		PROC freq data=ab7 noprint; tables NBID3_B / missing out=ctrl.match_alljobs_&reg._&y; 
			title "region &reg final match fileyears &y_1 &y year &y_1" ;
			format NBID3_B mynb.;
		RUN;
		
		DATA ctrl.match_alljobs_&reg._&y; SET ctrl.match_alljobs_&reg._&y;
      REGT=&reg;
      MATCH=compress(&y_1 !! "-" !! &y);
      NBMATCH_YT_1=PUT(NBID3_B,mynb_b.);
      DROP NBID3_B ;
		RUN;

		data psid.id&reg.&y2; 
			SET ab6 (keep=IDENT_S IDENT_S_B REGT NBID3_A NBID3_B where=(NBID3_A=1 and NBID3_B=1)); 
			rename IDENT_S_B=IDENT_S&y2 IDENT_S=IDENT_S&y_12 ;
			drop NBID3_A NBID3_B ;
		RUN; 

		PROC DATASETS lib=work memtype=data ;
			delete AB7 AB6;
		RUN;
	%MEND;

	%MACRO psid_2(y);
		%psid(reg=11,y=&y);
		%psid(reg=21,y=&y);
		%psid(reg=22,y=&y);
		%psid(reg=23,y=&y);
		%psid(reg=24,y=&y);
		%psid(reg=25,y=&y);
		%psid(reg=26,y=&y);
		%psid(reg=31,y=&y);
		%psid(reg=41,y=&y);
		%psid(reg=42,y=&y);
		%psid(reg=43,y=&y);
		%psid(reg=52,y=&y);
		%psid(reg=53,y=&y);
		%psid(reg=54,y=&y);
		%psid(reg=72,y=&y);
		%psid(reg=73,y=&y);
		%psid(reg=74,y=&y);
		%psid(reg=82,y=&y);
		%psid(reg=83,y=&y);
		%psid(reg=91,y=&y);
		%psid(reg=93,y=&y);
		%psid(reg=94,y=&y);
		%psid(reg=97,y=&y);
		%psid(reg=99,y=&y);
	%MEND;

	%MACRO psid_3(y);
		%if &y>2017 %then %full2reg(&y);
		%let y_1=%eval(&y-1);
		%if &y>2018 %then %full2reg_1(&y_1);

		%psid(reg=11,y=&y);
		%psid(reg=24,y=&y);
		%psid(reg=27,y=&y);
		%psid(reg=28,y=&y);
		%psid(reg=32,y=&y);
		%psid(reg=44,y=&y);
		%psid(reg=52,y=&y);
		%psid(reg=53,y=&y);
		%psid(reg=75,y=&y);
		%psid(reg=76,y=&y);
		%psid(reg=84,y=&y);
		%psid(reg=93,y=&y);
		%psid(reg=94,y=&y);
		%psid(reg=97,y=&y);
		%psid(reg=99,y=&y);
		
		%if &y>2017 %then %do; 
			PROC DATASETS lib=po&y ;
				delete post11 
					post24 post27 post28 post32 post44 
					post52 post53 post75 post76 
					post84 post93 post94 post97 post99 ;
			RUN;
		%end;

		%if &y>2018 %then %do; 
			PROC DATASETS lib=po&y_1 ;
				delete post11 
					post24 post27 post28 post32 post44 
					post52 post53 post75 post76 
					post84 post93 post94 post97 post99 ;
			RUN;
		%end;
	%MEND;

	%MACRO psid_4(y,last);

		%let y1=&y;
		%let y0=%eval(&y-1);
		%let y_1=%eval(&y-2);

		%let y12=%substr(&y,3,2);
		%let y02=%substr(%eval(&y-1),3,2);
		%let y_12=%substr(%eval(&y-2),3,2);


		%if &y>2018 %then %do; 
				%let SIREN_1=SIREN_EMPl_1;
				%let NIC_1=NIC_EMPl_1;
				%let SIREN=SIREN_EMPl;
				%let NIC=NIC_EMPl;

			%end;
			%else %do;
				%let SIREN=SIREN;
				%let NIC=NIC;
				%let SIREN_1=SIREN;
				%let NIC_1=NIC;
		%end;

		
		%if (&last=0) %then %do;
			%if (&y0>=2018) %then %do; 
				data a; 
				SET 
				psid.id0&y02;
			RUN;
			%end;
			%else %if (&y0>=2014) %then %do; 
				data a; 
				SET 
				psid.id11&y02 
				psid.id24&y02 psid.id27&y02 psid.id28&y02 psid.id32&y02 psid.id44&y02 
				psid.id52&y02 psid.id53&y02 psid.id75&y02 psid.id76&y02 
				psid.id84&y02 psid.id93&y02 psid.id94&y02 psid.id97&y02 psid.id99&y02;

				if ident_s&y_12=. then ident_all=ident_s&y02*100+&y02;
				else ident_all=ident_s&y_12*100+&y_12;

				RUN;
			%end;
			%else %do; 
				data a; 
					SET psid.id11&y02 
						psid.id21&y02 psid.id22&y02 psid.id23&y02 psid.id24&y02 psid.id25&y02 psid.id26&y02 
						psid.id31&y02 psid.id41&y02 psid.id42&y02 psid.id43&y02
						psid.id52&y02 psid.id53&y02 psid.id54&y02 psid.id72&y02 psid.id73&y02 psid.id74&y02 
						psid.id82&y02 psid.id83&y02 psid.id91&y02 psid.id93&y02 psid.id94&y02 psid.id97&y02 psid.id99&y02;
					%if (&y0<2003) %then %do;
						ident_s&y_12=ident_s&y_12*100+REGT;
						%if (&y0<2002) %then %do;
							ident_s&y02=ident_s&y02*100+REGT;
						%end;
					%end;	

					if ident_s&y_12=. then ident_all=ident_s&y02*100+&y02;
					else ident_all=ident_s&y_12*100+&y_12;

				RUN;
			%end;

			PROC SQL; 
				CREATE TABLE a1 AS SELECT 
					min(ident_s&y_12) as ident_s&y_12,
					min(ident_s&y02) as ident_s&y02, 
					min(IDENT_ALL) as IDENT_ALL,
					min(REGT) as REGT 
					from a GROUP BY ident_s&y02, ident_s&y_12;
				CREATE TABLE a2 (where=(nb<2)) AS SELECT *, 
					sum(ident_s&y_12>0) as nb from a1 group by ident_s&y_12;
				CREATE TABLE a3 (where=(nb<2)) AS SELECT *, 
					sum(ident_s&y02>0) as nb from a2 (drop=nb) group by ident_s&y02;
			QUIT;
		%end;
		%if (&y1>=2014) %then %do; 
			data b; 
				SET 
				psid.id11&y12 
				psid.id24&y12 psid.id27&y12 psid.id28&y12 psid.id32&y12 psid.id44&y12 
				psid.id52&y12 psid.id53&y12 psid.id75&y12 psid.id76&y12 
				psid.id84&y12 psid.id93&y12 psid.id94&y12 psid.id97&y12 psid.id99&y12;
			RUN;
		%end;
		%else %do; 
			data b; 
			SET 
			psid.id11&y12 
			psid.id21&y12 psid.id22&y12 psid.id23&y12 psid.id24&y12 psid.id25&y12 psid.id26&y12 
			psid.id31&y12 psid.id41&y12 psid.id42&y12 psid.id43&y12
			psid.id52&y12 psid.id53&y12 psid.id54&y12 psid.id72&y12 psid.id73&y12 psid.id74&y12
			psid.id82&y12 psid.id83&y12 psid.id91&y12 psid.id93&y12 psid.id94&y12 psid.id97&y12 psid.id99&y12;
			%if (&y1<2003) %then %do;
				ident_s&y02=ident_s&y02*100+REGT;
				%if (&y1<2002) %then %do;
					ident_s&y12=ident_s&y12*100+REGT;
				%end;
			%end;
			RUN;
		%end;
		PROC SQL; 
			CREATE TABLE b1 AS SELECT 
				min(ident_s&y02) as ident_s&y02,
				min(ident_s&y12) as ident_s&y12, 
				min(REGT) as REGT from b GROUP BY ident_s&y12, ident_s&y02;
			CREATE TABLE b2 (where=(nb<2)) AS SELECT *, 
				sum(ident_s&y02>0) as nb from b1 group by ident_s&y02;
			CREATE TABLE b3 (where=(nb<2)) AS SELECT *, 
				sum(ident_s&y12>0) as nb from b2 (drop=nb) group by ident_s&y12;
		QUIT;

		%if (&last=0) %then %do;
			PROC SQL; 
			CREATE TABLE c AS SELECT * from b3 
					(rename=(REGT=REGT&y12)
					 drop=nb ) as bb 
				LEFT JOIN a3 
				(KEEP=IDENT_ALL ident_s&y02 ) as aa 
				on bb.ident_s&y02=aa.ident_s&y02; 
			QUIT;

			data psid.psid_&y (drop=ident_s&y02 REGT&y12 rename=(ident_s&y12=ident_s)); SET c ; 
				if ident_all =. then ident_all=ident_s&y02*100+&y02;
			RUN;

			PROC DATASETS lib=work;
				delete a a1 a2;
			RUN;

		%end;
		%else %do;
			PROC SQL; 
			CREATE TABLE c AS SELECT * from b3 
					(rename=(REGT=REGT&y12)
					 Drop=nb) as bb 
				LEFT JOIN &last 
					(KEEP=IDENT_ALL ident_s rename=(IDENT_S=ident_s&y02)) as aa
				on bb.ident_s&y02=aa.ident_s&y02; 
			QUIT;

			data psid.psid_&y (drop=ident_s&y02 REGT&y12 rename=(ident_s&y12=ident_s)); SET c ; 
			if ident_all =. then ident_all=ident_s&y02*100+&y02;
			RUN;
		%end;
		PROC DATASETS lib=work;
			delete b b1 b2 b3 c ; 
		RUN;

	%if &y1>2013 %then %do;
		PROC DATASETS lib=psid;
			 delete	id11&y12 
				id24&y12 id27&y12 id28&y12 id32&y12 id44&y12 
				id52&y12 id53&y12 id75&y12 id76&y12 
				id84&y12 id93&y12 id94&y12 id97&y12 id99&y12;
		
			; 
		RUN;
	%end;
	%else %do;
		PROC DATASETS lib=psid;
			delete id11&y12 
			id21&y12 id22&y12 id23&y12 id24&y12 id25&y12 id26&y12 
			id31&y12 id41&y12 id42&y12 id43&y12
			id52&y12 id53&y12 id54&y12 id72&y12 id73&y12 id74&y12
			id82&y12 id83&y12 id91&y12 id93&y12 id94&y12 id97&y12 id99&y12;
		RUN;
		
	%end;

	%MEND;
******************************************************************************;
******************************************************************************;




******************************************************************************;
* 2. RUN THE MACROS WITH YOUR OWN PARAMETERS;
******************************************************************************;

	******************************************************************************;
	* 2.a. Libnames;
	******************************************************************************;

	/* %my_libnames(casd_project=A0INEPR); */
	%my_libnames(casd_project=%sysget(CASD_PROJECT));

	*Recording the log file in a specific file;
	PROC PRINTTO LOG="C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\ctrl\log.txt" NEW; 
	RUN;

	******************************************************************************;
	* 2.b. Regional yearly match;
	******************************************************************************;
	%psid_2(1995);/*Match difficult */
	%psid_2(1996);
	%psid_2(1997);
	%psid_2(1998);
	%psid_2(1999);
	%psid_2(2000);
	%psid_2(2001);
	%psid_2(2002);/*Match difficult */
	%psid_2(2003);
	%psid_2(2004);
	%psid_2(2005);
	%psid_2(2006);
	%psid_2(2007);
	%psid_2(2008);
	%psid_2(2009);
	%psid_2(2010);
	%psid_2(2011);
	%psid_2(2012);
	%psid_2(2013);
	%psid_3(2014);
	%psid_3(2015);
	%psid_3(2016);
	%psid_3(2017);
	%psid_3(2018);
	%psid_3(2019);
	%psid_3(2020);

	******************************************************************************;
	* 2.c. Appending data on total France;
	******************************************************************************;
	%psid_4(y=1996,last=0);

		DATA psid.psid_1995 (DROP=nb ident_s94 REGT RENAME=(ident_s95=ident_s)); 
			SET a3; 
		RUN;

		DATA psid.psid_1994 (DROP=nb ident_s95 REGT RENAME=(ident_s94=ident_s)); 
			SET a3; 
		RUN;

		DATA psid.psid_1996 (DROP=ident_s94); 
			SET psid.psid_1996 ; 
		RUN;

		PROC DATASETS LIB=psid;
			%let y1=95;
				DELETE id11&y1 
				id21&y1 id22&y1 id23&y1 id24&y1 id25&y1 id26&y1 
				id31&y1 id41&y1 id42&y1 id43&y1
				id52&y1 id53&y1 id54&y1 id72&y1 id73&y1 id74&y1
				id82&y1 id83&y1 id91&y1 id93&y1 id94&y1 id97&y1 id99&y1;
		RUN;

	%psid_4(y=1997,last=psid.psid_1996);
	%psid_4(y=1998,last=psid.psid_1997);
	%psid_4(y=1999,last=psid.psid_1998);
	%psid_4(y=2000,last=psid.psid_1999);
	%psid_4(y=2001,last=psid.psid_2000);
	%psid_4(y=2002,last=psid.psid_2001);
	%psid_4(y=2003,last=psid.psid_2002);
	%psid_4(y=2004,last=psid.psid_2003);
	%psid_4(y=2005,last=psid.psid_2004);
	%psid_4(y=2006,last=psid.psid_2005);
	%psid_4(y=2007,last=psid.psid_2006);
	%psid_4(y=2008,last=psid.psid_2007);
	%psid_4(y=2009,last=psid.psid_2008);
	%psid_4(y=2010,last=psid.psid_2009);
	%psid_4(y=2011,last=psid.psid_2010);
	%psid_4(y=2012,last=psid.psid_2011);
	%psid_4(y=2013,last=psid.psid_2012);
	%psid_4(y=2014,last=psid.psid_2013);
	%psid_4(y=2015,last=psid.psid_2014);
	%psid_4(y=2016,last=psid.psid_2015);
	%psid_4(y=2017,last=psid.psid_2016);
	%psid_4(y=2018,last=psid.psid_2017);
	%psid_4(y=2019,last=psid.psid_2018);
	%psid_4(y=2020,last=psid.psid_2019);


******************************************************************************;
* GOOD LUCK IN THE COMPLETION OF YOUR MANUSCRIPT ;
******************************************************************************;
