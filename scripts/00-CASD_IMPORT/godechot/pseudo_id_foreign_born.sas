****************************************************************
* SCRIPT pseudo_foreign_born.sas 2022/10/10 (V2)			         *
* Olivier Godechot                                             *
* Email: Olivier.Godechot [at] sciencespo.fr                   *
****************************************************************
* CORRECTING FOREIGN BORN AND CITIZENSHIP VARIABLES            *
****************************************************************

	DADS gives information on the department of birth, with a code 99 indicating that the employee is born 
	abroad and 97 and 98 born in the French DOM-TOMs (oversea departements and territories).
	It gives also information on French or foreign citizenship (up to 2015) and on EU citizenship
	between 2005 and 2015.

	These variables could be interesting for research on migration and discrimination.
	However these variables come with obvious errors.

	- In 2002, 2003, 2004 and 2005, the number of foreign born is obviously underestimated 
	and in 2011, the variable is missing. 

	- From 2005 to 2008, the variable on Non EU-Citizenship is obviously overestimated. 
	 And information is missing in 2016 and following years. 

	The script uses information from the different years to create the following robuts variables 
	on location of birth and citizenship: 

	* Birth location in psid_all_foreign_born.sas7bdat

		* fborn_def (Value : 0, 1, 9): 
			0. Born in France
			1. Foreign born 
			9. Information non available

		* domtom_def (Value : 0, 1, 9): 
			0. Born outside DOM-TOMs
			1. DOM-TOM born
			9. Information non available
 
		For limiting space consumption, we keep in psid_all_foreign_born.sas7bdat 
		only workers who are either foreign or DOM-TOM (French oversea) born, or for which we know 
		information on place of birth is missing.
		
	* Citizenship in psid_all_citizen.sas7bdat

		* foreign_nat_origin (dummy): a non French citizenship origin is mentioned at least once 
		*   between 1994 and 2015.

		* EU_nat_origin (Value : 0, 1, 9) : 
			0. non French EU citizenship is never mentioned between 2005 and 2015
			1. a non French EU citizenship is mentioned at least once between 2005 and 2015
			9. missing: there's no citizenship information available after 2004. 
		
		* gets_french_nat : (proxy of the) year where the foreigner gets French citizenship.

	* Other variables created in further step 

		* foreign_def (Value : 0, 1, 9) is not in psid_all_citizen.sas7bdat but created by %psid_sen_fborn or by %psid_use
			0. french citizen in the year of the yearfile
			1. foreign citizen in the year of the yearfile
			9. missing: no citizenship information available 

	* This script comes with 3 joint programs : 

		* 1. pseudo_id.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		*    which creates an common identifier ident_all for all files.

		* 2. pseudo_id_seniority.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		*    which calculates the year of entry in the firm and the establishment and enables to 
		*	 calculate seniority.

		* 3. pseudo_id_use.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		*    which gives an example of creating a dads files with common identifiers.


****************************************************************
* HOW TO RUN THE PROGRAM  
****************************************************************

* The program comes into two parts. 

	* 1. Resolve all the macros scripts. 

	* 2. Run the macros

		- 2.a. Create the libnames

			%my_libnames(casd_project=A0INEPR) 

			* !!!! CHANGE A0INEPR !!! with the name of your CASD project (written on your CASD card)

		- 2.b. The macro %psid_fborn (1994) to %psid_fborn (2020) will create in the work folder
		psid_fborn_yyyy.sas7bdat files with IDENT_ALL, citizenship and department of birth variables	

		- 2.c. The macro %foreign_born and following scripts creates two files psid_all_citizen.sas7bdat 
		and psid_all_foreign_born.sas7bdat with respecetively corrected foreign born and citizenship variables
		
		- 2.d  The optional macro %psid_sen_fborn(1994,citizen=NO) to %psid_sen_fborn(2020,citizen=NO) 
		will update psid_fborn_yyyy.sas7bdat files (which contain siren,nic,seniority variables) 
		with corrected foreign born and citizenship variables (use citizen=YES to have citizenship variables).
		(WARNING: Running psid_seniority.sas before is required before running this part).

*****************************************************************************
* OUTPUT 
*****************************************************************************
	* The program will create files psid_all_foreign_born.sas7bdat and psid_all_citizen.sas7bdat 
		in the CASD common folder: C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_foreign_born\

		* psid_all_foreign_born.sas7bdat contains variables for correcting missings and errors on 
			workers born abroad and in French over sea departments and territories.

		* psid_all_citizen.sas7bdat contains variables for correcting missings and errors on 
			workers born abroad and in French over sea departments and territories.

	* The log file is also recorded in the same folder.

******************************************************************************
* SPACE AND TIME REQUIREMENTS 
******************************************************************************
	* TIME: Approximately 4 hours or so. 
	* SPACE: At least 50 go hard drive available to RUN it smoothly
	* STORAGE: 
		- 2.3 Go storage in the C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_foreign_born\ folder

		- 64 Go (instead of 48 Go) in the C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_seniority\ folder
		if you add foreign born variables to the seniority files (optional %psid_sen_fborn macro)

	   - 96 Go (instead of 48 Go) in the C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_seniority\ folder
		if you add both foreign born and citizenship variables to the seniority files (optional %psid_sen_fborn macro)
 

******************************************************************************
* HOW TO USE THE pseudo_id_foreign_born FILES 
******************************************************************************
	* Two options. 

	* - Either use psid_all_foreign_born.sas7bdat and psid_all_citizen.sas7bdat and merge with IDENT_all

	* - Or RUN %psid_sen_fborn(), and then merge psid_sen_yyyy.sas7bdat files with your DADS files 
	*  with IDENT_S, SIREN and NIC as merging keys. 
	
******************************************************************************
* WARNINGS AND DISCLAIMERS
******************************************************************************

	* This program comes with absolutely no warranty of accurateness

	* Reminder: not all foreign born are migrants ! 

*****************************************************************************
* HOW TO CITE : 
*****************************************************************************
	Babet, Damien, Olivier Godechot and Marco G. Palladino, 2022. In the Land
	of AKM: Explaining the Dynamics of Wage Inequality in France, Document de 
	travail, Insee (forthcoming). 
*****************************************************************************
	
****************************************************************************************************************************;


******************************************************************************;
* 1. MACROS SCRIPTS TO RESOLVE;
******************************************************************************;
	* Select (Keys: shift + arrows) and execute (Key: F3) the following lines to resolve the macros;
	%MACRO my_libnames(casd_project); 

		options ps=MAX ls=MAX nodate nonumber nocenter DLCREATEDIR;
		libname psid "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads"; 
		libname psid_fbo "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_foreign_born";
		libname psid_sen "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_seniority"; 

	
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
		libname po2018 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2018";
		libname po2019 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2019";
		libname po2020 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2020";

		*Paris region libnames;
		libname pi2012 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2012\Ile de France";
		libname pi2013 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2013\Ile de France";
		libname pi2014 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2014\Départements";
		libname pi2015 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2015\Départements";
		libname pi2016 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2016\Départements";
		libname pi2017 "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_2017\Départements";
	%MEND;

******************************************************************************;
* MACRO SCRIPTS;
******************************************************************************;
	%MACRO m_9401(year);
		%let year2=%substr(&year,3,2);
		%let keep= SIREN NIC BRUT REG ETRANG DEPNAI;
		%let rename= RENAME=(REG=REGT BRUT=S_BRUT ETRANG=ETRANGER DEPNAI=DEP_NAISS);
		%let where=AND S_BRUT>0;
			%MACRO b_reg(reg);
				DATA b&reg._&year2; 
					SET po&year..post&reg.&year2 
						(&rename 
							KEEP=&keep);
					ident_s=_N_*100+REGT;
				RUN;
			%MEND;
		%b_reg(reg=11);
		%b_reg(reg=21);
		%b_reg(reg=22);
		%b_reg(reg=23);
		%b_reg(reg=24);
		%b_reg(reg=25);
		%b_reg(reg=26);
		%b_reg(reg=31);
		%b_reg(reg=41);
		%b_reg(reg=42);
		%b_reg(reg=43);
		%b_reg(reg=52);
		%b_reg(reg=53);
		%b_reg(reg=54);
		%b_reg(reg=72);
		%b_reg(reg=73);
		%b_reg(reg=74);
		%b_reg(reg=82);
		%b_reg(reg=83);
		%b_reg(reg=91);
		%b_reg(reg=93);
		%b_reg(reg=94);
		%b_reg(reg=97);
		%b_reg(reg=99);

		DATA b&year; 
			set 
			b11_&year2 (WHERE=(REGT="11" &where ))
			b21_&year2 (WHERE=(REGT="21" &where ))
			b22_&year2 (WHERE=(REGT="22" &where ))
			b23_&year2 (WHERE=(REGT="23" &where ))
			b24_&year2 (WHERE=(REGT="24" &where ))
			b25_&year2 (WHERE=(REGT="25" &where ))
			b26_&year2 (WHERE=(REGT="26" &where ))
			b31_&year2 (WHERE=(REGT="31" &where ))
			b41_&year2 (WHERE=(REGT="41" &where ))
			b42_&year2 (WHERE=(REGT="42" &where ))
			b43_&year2 (WHERE=(REGT="43" &where ))
			b52_&year2 (WHERE=(REGT="52" &where ))
			b53_&year2 (WHERE=(REGT="53" &where ))
			b54_&year2 (WHERE=(REGT="54" &where ))
			b72_&year2 (WHERE=(REGT="72" &where ))
			b73_&year2 (WHERE=(REGT="73" &where ))
			b74_&year2 (WHERE=(REGT="74" &where ))
			b82_&year2 (WHERE=(REGT="82" &where ))
			b83_&year2 (WHERE=(REGT="83" &where ))
			b91_&year2 (WHERE=(REGT="91" &where ))
			b93_&year2 (WHERE=(REGT="93" &where ))
			b94_&year2 (WHERE=(REGT="94" &where ))
			b97_&year2 (WHERE=(REGT IN ("01","02","03","04","05","06","97","97") &where ))
			b99_&year2 (WHERE=(REGT IN ("00","99") &where )) 
			;
			year=&year;
			noise=ranuni(191973)/1000;
		RUN;

		PROC datasets LIBRARY=WORK; 
			DELETE 
				b11_&year2 
				b21_&year2 
				b22_&year2 
				b23_&year2 
				b24_&year2 
				b25_&year2 
				b26_&year2 
				b31_&year2 
				b41_&year2 
				b42_&year2 
				b43_&year2 
				b52_&year2 
				b53_&year2 
				b54_&year2 
				b72_&year2 
				b73_&year2 
				b74_&year2 
				b82_&year2 
				b83_&year2 
				b91_&year2 
				b93_&year2 
				b94_&year2 
				b97_&year2 
				b99_&year2 
			;
		RUN;

	%MEND;

	%MACRO m_0208(year);
		%let year2=%substr(&year,3,2);
		%let keep=SIREN NIC IDENT_S S_BRUT REGT ETRANGER DEP_NAISS;
		%let where=AND S_BRUT>0 and MISSING(IDENT_S)=0;
		%let rename=;
		data b&year; 
			set 	
			po&year..post11&year2 (&rename keep=&keep  WHERE=(REGT="11" &where  )) 
			po&year..post21&year2 (&rename keep=&keep  WHERE=(REGT="21" &where  )) 
			po&year..post22&year2 (&rename keep=&keep  WHERE=(REGT="22" &where  )) 
			po&year..post23&year2 (&rename keep=&keep  WHERE=(REGT="23" &where  )) 
			po&year..post24&year2 (&rename keep=&keep  WHERE=(REGT="24" &where  )) 
			po&year..post25&year2 (&rename keep=&keep  WHERE=(REGT="25" &where  )) 
			po&year..post26&year2 (&rename keep=&keep  WHERE=(REGT="26" &where  )) 
			po&year..post31&year2 (&rename keep=&keep  WHERE=(REGT="31" &where  )) 
			po&year..post41&year2 (&rename keep=&keep  WHERE=(REGT="41" &where  )) 
			po&year..post42&year2 (&rename keep=&keep  WHERE=(REGT="42" &where  )) 
			po&year..post43&year2 (&rename keep=&keep  WHERE=(REGT="43" &where  )) 
			po&year..post52&year2 (&rename keep=&keep  WHERE=(REGT="52" &where  )) 
			po&year..post53&year2 (&rename keep=&keep  WHERE=(REGT="53" &where  )) 
			po&year..post54&year2 (&rename keep=&keep  WHERE=(REGT="54" &where  )) 
			po&year..post72&year2 (&rename keep=&keep  WHERE=(REGT="72" &where  )) 
			po&year..post73&year2 (&rename keep=&keep  WHERE=(REGT="73" &where  )) 
			po&year..post74&year2 (&rename keep=&keep  WHERE=(REGT="74" &where  )) 
			po&year..post82&year2 (&rename keep=&keep  WHERE=(REGT="82" &where  )) 
			po&year..post83&year2 (&rename keep=&keep  WHERE=(REGT="83" &where  )) 
			po&year..post91&year2 (&rename keep=&keep  WHERE=(REGT="91" &where  )) 
			po&year..post93&year2 (&rename keep=&keep  WHERE=(REGT="93" &where ))
			po&year..post94&year2 (&rename keep=&keep  WHERE=(REGT="94" &where  ))			
			po&year..post97&year2 (&rename keep=&keep  WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where  ))
			po&year..post99&year2 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ));
			year=&year;
			noise=ranuni(191973)/1000;
		RUN;
	%MEND;

	%MACRO m_09(year);
		%let keep=SIREN NIC IDENT_S S_BRUT REGT IND_ETRANGER DEP_NAISS;
		%let where=AND S_BRUT>0 and MISSING(IDENT_S)=0;
		%let rename=RENAME=(IND_ETRANGER=ETRANGER);
		
		data b&year; 
			set 
			po&year..post11aa (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post11bb (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post11cc (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post11dd (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post21 (&rename keep=&keep WHERE=(REGT="21" &where  )) 
			po&year..post22 (&rename keep=&keep WHERE=(REGT="22" &where  )) 
			po&year..post23 (&rename keep=&keep WHERE=(REGT="23" &where  )) 
			po&year..post24 (&rename keep=&keep WHERE=(REGT="24" &where  )) 
			po&year..post25 (&rename keep=&keep WHERE=(REGT="25" &where  )) 
			po&year..post26 (&rename keep=&keep WHERE=(REGT="26" &where  )) 
			po&year..post31 (&rename keep=&keep WHERE=(REGT="31" &where  )) 
			po&year..post41 (&rename keep=&keep WHERE=(REGT="41" &where  )) 
			po&year..post42 (&rename keep=&keep WHERE=(REGT="42" &where  )) 
			po&year..post43 (&rename keep=&keep WHERE=(REGT="43" &where  )) 
			po&year..post52 (&rename keep=&keep WHERE=(REGT="52" &where  )) 
			po&year..post53 (&rename keep=&keep WHERE=(REGT="53" &where  )) 
			po&year..post54 (&rename keep=&keep WHERE=(REGT="54" &where  )) 
			po&year..post72 (&rename keep=&keep WHERE=(REGT="72" &where  )) 
			po&year..post73 (&rename keep=&keep WHERE=(REGT="73" &where  )) 
			po&year..post74 (&rename keep=&keep WHERE=(REGT="74" &where  ))
			po&year..post82 (&rename keep=&keep WHERE=(REGT="82" &where  )) 
			po&year..post83 (&rename keep=&keep WHERE=(REGT="83" &where  )) 
			po&year..post91 (&rename keep=&keep WHERE=(REGT="91" &where  )) 
			po&year..post93 (&rename keep=&keep WHERE=(REGT="93" &where  ))
			po&year..post94 (&rename keep=&keep WHERE=(REGT="94" &where  ))
			po&year..post97 (&rename keep=&keep  WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where  ))
			po&year..post99 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ));
			year=&year;
			noise=ranuni(191973)/1000;	
		RUN;
	%MEND;


	%MACRO m_10(year);
		%let keep=SIREN NIC IDENT_S S_BRUT REGT IND_ETRANGER DEP_NAISS;
		%let where=AND S_BRUT>0 and MISSING(IDENT_S)=0;
		%let rename=RENAME=(IND_ETRANGER=ETRANGER);
		
		data b&year; 
			set 
			po&year..post11aa (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post11bb (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post11cc (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post11dd (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post21 (&rename keep=&keep WHERE=(REGT="21" &where  )) 
			po&year..post22 (&rename keep=&keep WHERE=(REGT="22" &where  )) 
			po&year..post23 (&rename keep=&keep WHERE=(REGT="23" &where  )) 
			po&year..post24 (&rename keep=&keep WHERE=(REGT="24" &where  )) 
			po&year..post25 (&rename keep=&keep WHERE=(REGT="25" &where  )) 
			po&year..post26 (&rename keep=&keep WHERE=(REGT="26" &where  )) 
			po&year..post31 (&rename keep=&keep WHERE=(REGT="31" &where  )) 
			po&year..post41 (&rename keep=&keep WHERE=(REGT="41" &where  )) 
			po&year..post42 (&rename keep=&keep WHERE=(REGT="42" &where  )) 
			po&year..post43 (&rename keep=&keep WHERE=(REGT="43" &where  )) 
			po&year..post52 (&rename keep=&keep WHERE=(REGT="52" &where  )) 
			po&year..post53 (&rename keep=&keep WHERE=(REGT="53" &where  )) 
			po&year..post54 (&rename keep=&keep WHERE=(REGT="54" &where  )) 
			po&year..post72 (&rename keep=&keep WHERE=(REGT="72" &where  )) 
			po&year..post73 (&rename keep=&keep WHERE=(REGT="73" &where  )) 
			po&year..post74 (&rename keep=&keep WHERE=(REGT="74" &where  ))
			po&year..post82a (&rename keep=&keep WHERE=(REGT="82" &where  )) 
			po&year..post82b (&rename keep=&keep WHERE=(REGT="82" &where  )) 
			po&year..post91 (&rename keep=&keep WHERE=(REGT="91" &where  )) 
			po&year..post93 (&rename keep=&keep WHERE=(REGT="93" &where))
			po&year..post94 (&rename keep=&keep WHERE=(REGT="94" &where  ))
			po&year..post97 (&rename keep=&keep  WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where  ))
			po&year..post99 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ))
			;
			year=&year;
			noise=ranuni(191973)/1000;
		RUN;
	%MEND;



	%MACRO m_11(year);
		%let keep=SIREN NIC IDENT_S S_BRUT REGT DEPT IND_ETRANGER DEP_NAISS;
		%let where=AND S_BRUT>0 and MISSING(IDENT_S)=0;
		%let rename=RENAME=(IND_ETRANGER=ETRANGER);
		
		data b&year; 
			set 
			po&year..post11 (&rename keep=&keep WHERE=(REGT="11" &where  )) 
			po&year..post21 (&rename keep=&keep WHERE=(REGT="21" &where  )) 
			po&year..post22 (&rename keep=&keep WHERE=(REGT="22" &where  )) 
			po&year..post23 (&rename keep=&keep WHERE=(REGT="23" &where  )) 
			po&year..post24 (&rename keep=&keep WHERE=(REGT="24" &where  )) 
			po&year..post25 (&rename keep=&keep WHERE=(REGT="25" &where  )) 
			po&year..post26 (&rename keep=&keep WHERE=(REGT="26" &where  )) 
			po&year..post31 (&rename keep=&keep WHERE=(REGT="31" &where  )) 
			po&year..post41 (&rename keep=&keep WHERE=(REGT="41" &where  )) 
			po&year..post42 (&rename keep=&keep WHERE=(REGT="42" &where  )) 
			po&year..post43 (&rename keep=&keep WHERE=(REGT="43" &where  )) 
			po&year..post52 (&rename keep=&keep WHERE=(REGT="52" &where  )) 
			po&year..post53 (&rename keep=&keep WHERE=(REGT="53" &where  )) 
			po&year..post54 (&rename keep=&keep WHERE=(REGT="54" &where  )) 
			po&year..post72 (&rename keep=&keep WHERE=(REGT="72" &where  )) 
			po&year..post73 (&rename keep=&keep WHERE=(REGT="73" &where  )) 
			po&year..post74 (&rename keep=&keep WHERE=(REGT="74" &where  ))
			po&year..post82 (&rename keep=&keep WHERE=(REGT="82" &where  )) 
			po&year..post83 (&rename keep=&keep WHERE=(REGT="83" &where  )) 
			po&year..post91 (&rename keep=&keep WHERE=(REGT="91" &where  )) 
			po&year..post93 (&rename keep=&keep WHERE=(REGT="93" &where))
			po&year..post94 (&rename keep=&keep WHERE=(REGT="94" &where  ))
			po&year..post97 (&rename keep=&keep  WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where  ))
			po&year..post99 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ))

			;
			year=&year;
			noise=ranuni(191973)/1000;
		RUN;
	%MEND;


	%MACRO m_1213(year);
		%let keep=SIREN NIC IDENT_S S_BRUT REGT DEPT IND_ETRANGER DEP_NAISS;
		%let where=AND S_BRUT>0 and MISSING(IDENT_S)=0;
		%let rename=RENAME=(IND_ETRANGER=ETRANGER);
		
		data b&year; 
			set 
			pi&year..post75 (&rename keep=&keep DEPT WHERE=(DEPT="75" &where  ))
			pi&year..post77 (&rename keep=&keep DEPT WHERE=(DEPT="77" &where  ))
			pi&year..post78 (&rename keep=&keep DEPT WHERE=(DEPT="78" &where  ))
			pi&year..post91 (&rename keep=&keep DEPT WHERE=(DEPT="91" &where  ))
			pi&year..post92 (&rename keep=&keep DEPT WHERE=(DEPT="92" &where  ))
			pi&year..post93 (&rename keep=&keep DEPT WHERE=(DEPT="93" &where  ))
			pi&year..post94 (&rename keep=&keep DEPT WHERE=(DEPT="94" &where  ))
			pi&year..post95 (&rename keep=&keep DEPT WHERE=(DEPT="95" &where  ))
			po&year..post21 (&rename keep=&keep WHERE=(REGT="21" &where  )) 
			po&year..post22 (&rename keep=&keep WHERE=(REGT="22" &where  )) 
			po&year..post23 (&rename keep=&keep WHERE=(REGT="23" &where  )) 
			po&year..post24 (&rename keep=&keep WHERE=(REGT="24" &where  )) 
			po&year..post25 (&rename keep=&keep WHERE=(REGT="25" &where  )) 
			po&year..post26 (&rename keep=&keep WHERE=(REGT="26" &where  )) 
			po&year..post31 (&rename keep=&keep WHERE=(REGT="31" &where  )) 
			po&year..post41 (&rename keep=&keep WHERE=(REGT="41" &where  )) 
			po&year..post42 (&rename keep=&keep WHERE=(REGT="42" &where  )) 
			po&year..post43 (&rename keep=&keep WHERE=(REGT="43" &where  )) 
			po&year..post52 (&rename keep=&keep WHERE=(REGT="52" &where  )) 
			po&year..post53 (&rename keep=&keep WHERE=(REGT="53" &where  )) 
			po&year..post54 (&rename keep=&keep WHERE=(REGT="54" &where  )) 
			po&year..post72 (&rename keep=&keep WHERE=(REGT="72" &where  )) 
			po&year..post73 (&rename keep=&keep WHERE=(REGT="73" &where  )) 
			po&year..post74 (&rename keep=&keep WHERE=(REGT="74" &where  ))
			po&year..post82 (&rename keep=&keep WHERE=(REGT="82" &where  )) 
			po&year..post83 (&rename keep=&keep WHERE=(REGT="83" &where  )) 
			po&year..post91 (&rename keep=&keep WHERE=(REGT="91" &where  )) 
			po&year..post93 (&rename keep=&keep WHERE=(REGT="93" &where))
			po&year..post94 (&rename keep=&keep WHERE=(REGT="94" &where  ))
			po&year..post97 (&rename keep=&keep  WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where  ))
			po&year..post99 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ))

			;
			year=&year;
			noise=ranuni(191973)/1000;
		RUN;
	%MEND;


	%MACRO m_1417(year);
		%if &year<2016 %then %do; 
			%let ETRANGER=IND_ETRANGER;
			%let rename=RENAME=(IND_ETRANGER=ETRANGER);
		%end;
		%else %do;
			%let rename=;
			%let ETRANGER=;
		%end;

		%let keep=SIREN NIC IDENT_S S_BRUT REGT DEPT &ETRANGER DEP_NAISS;
		%let where=AND S_BRUT>0 and MISSING(IDENT_S)=0;

		data b&year; 
			set 
			pi&year..post75 (&rename keep=&keep DEPT WHERE=(DEPT="75" &where  ))
			pi&year..post77 (&rename keep=&keep DEPT WHERE=(DEPT="77" &where  ))
			pi&year..post78 (&rename keep=&keep DEPT WHERE=(DEPT="78" &where  ))
			pi&year..post91 (&rename keep=&keep DEPT WHERE=(DEPT="91" &where  ))
			pi&year..post92 (&rename keep=&keep DEPT WHERE=(DEPT="92" &where  ))
			pi&year..post93 (&rename keep=&keep DEPT WHERE=(DEPT="93" &where  ))
			pi&year..post94 (&rename keep=&keep DEPT WHERE=(DEPT="94" &where  ))
			pi&year..post95 (&rename keep=&keep DEPT WHERE=(DEPT="95" &where  ))

			po&year..post24 (&rename keep=&keep WHERE=(REGT="24" &where  )) 
			po&year..post27 (&rename keep=&keep WHERE=(REGT="27" &where  )) 
			po&year..post28 (&rename keep=&keep WHERE=(REGT="28" &where  )) 
			po&year..post32 (&rename keep=&keep WHERE=(REGT="32" &where  )) 
			po&year..post44 (&rename keep=&keep WHERE=(REGT="44" &where  )) 
			po&year..post52 (&rename keep=&keep WHERE=(REGT="52" &where  )) 
			po&year..post53 (&rename keep=&keep WHERE=(REGT="53" &where  )) 
			po&year..post75 (&rename keep=&keep WHERE=(REGT="75" &where  )) 
			po&year..post76 (&rename keep=&keep WHERE=(REGT="76" &where  )) 
			po&year..post84 (&rename keep=&keep WHERE=(REGT="84" &where  )) 
			po&year..post93 (&rename keep=&keep WHERE=(REGT="93" &where  ))
			po&year..post94 (&rename keep=&keep WHERE=(REGT="94" &where  ))
			po&year..post97 (&rename keep=&keep  WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where  ))
			po&year..post99 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ))

			;
			year=&year;
			noise=ranuni(191973)/1000;
		RUN;
	%MEND;

	%MACRO m_1819(year);
		%let keep=SIREN NIC IDENT_S S_BRUT REGT DEP_NAISS;
		%let where=AND S_BRUT>0 and MISSING(IDENT_S)=0;
		%let rename=; 

		data b&year; 
			set 
			po&year..post_1 (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			po&year..post_2 (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			po&year..post_3 (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			po&year..post_4 (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			;
			year=&year;
			noise=ranuni(191973)/1000;
		RUN;
	%MEND;

	%MACRO m_20(year);
		%let keep=SIREN NIC IDENT_S S_BRUT REGT DEPT DEP_NAISS;
		%let where=AND S_BRUT>0 and MISSING(IDENT_S)=0;
		%let rename=; 

		data b&year; 
			set 
			po&year..post (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			;
			year=&year;
			noise=ranuni(191973)/1000;
		RUN;
	%MEND;



	%MACRO psid_fborn (year);
		%if &year<2002 %then %m_9401(&year);
		%else %if &year<2009 %then %m_0208(&year);
		%else %if &year=2009 %then %m_09(&year);
		%else %if &year=2010 %then %m_10(&year);
		%else %if &year=2011 %then %m_11(&year);
		%else %if &year<2014 %then %m_1213(&year);
		%else %if &year<2018 %then %m_1417(&year);
		%else %if &year<2020 %then %m_1819(&year);
		%else %if &year=2020 %then %m_20(&year);

		%let year_1=%eval(&year-1);
		%let year2=%substr(&year,3,2);
		

		* HOW TO GET FULL PANEL ID;
		%let b=b&year;

		PROC sql; 
				create table &b.0 (where=(max_s_brut=S_BRUT+noise))  
				as select 
				*,
				max(S_BRUT+noise) as max_s_brut
				from &b
				group by ident_s;
		QUIT;

		PROC sql; 
				create table &b.1  
				as select * from &b.0 (drop=max_s_brut noise s_brut)
				as aa
				left join psid.psid_&year (keep=ident_s ident_all)
				as bb
				on aa.ident_s=bb.ident_s;
		QUIT;

		data psid_fborn_&year; set &b.1;
			if Missing(ident_all) then do; 
				ident_all=ident_s*100+&year2;
			end;
			ident_all=compress(""!!ident_all!!"");
			drop IDENT_S ;
		RUN;

		PROC datasets LIBRARY=WORK; 
			DELETE &b &b.0 &b.1 ;
		RUN;
	%MEND;

	%MACRO all_foreign_born;
		%let i=1;
		%do %while (&i<10);
			%let where= where=(substr(left(put(IDENT_ALL,14.)),1,1)="&i");

			DATA psid_all_fborn_cit&i; 
			FORMAT dep_naiss $5.;
			SET 
				psid_fborn_1994 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_1995 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_1996 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_1997 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_1998 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_1999 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2000 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2001 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2002 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2003 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2004 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2005 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2006 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2007 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2008 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2009 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2010 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2011 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2012 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2013 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2014 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2015 (keep=IDENT_ALL DEP_NAISS ETRANGER YEAR  &where)
				psid_fborn_2016 (keep=IDENT_ALL DEP_NAISS YEAR  &where)
				psid_fborn_2017 (keep=IDENT_ALL DEP_NAISS YEAR  &where)
				psid_fborn_2018 (keep=IDENT_ALL DEP_NAISS YEAR  &where)
				psid_fborn_2019 (keep=IDENT_ALL DEP_NAISS YEAR  &where)
				psid_fborn_2020 (keep=IDENT_ALL DEP_NAISS YEAR  &where)
			; 
			RUN;				

			data psid_all_fborn_citB&i; set psid_all_fborn_cit&i; 
				noncitizen=(ETRANGER in ("C","E"))*1;
				if year>=2005 then EU_citizen=(ETRANGER in ("C"))*1;
				if year>=2005 then nonEU_citizen=(ETRANGER in ("E"))*1;

				if DEP_NAISS in ("97","98","971","972","973","974","97A","975","976",
					"9A","9B","9C","9D","985","986","987","988") then domtom=1;

				if DEP_NAISS in ("97A","9A","971") then DEP_NAISS="971";
				if DEP_NAISS in ("97B","9B","972") then DEP_NAISS="972";
				if DEP_NAISS in ("97C","9C","973") then DEP_NAISS="973";
				if DEP_NAISS in ("97D","9D","974") then DEP_NAISS="974";

				if DEP_NAISS IN ("2A","2B","2a","2b","20A","20B","20a","20b") THEN DEP_NAISS="20";
				
				dep_naiss_err=1-(domtom=1 OR (1<=DEP_NAISS*1<=99) OR (DEP_NAISS IN ("2A","2B","2a","2b","20A","20B","20a","20b")));

				if dep_naiss_err=1 then DEP_NAISS="";


				if dep_naiss_err=0 then foreign_born=(DEP_NAISS="99")*1;
				if dep_naiss_err=0 and domtom ne 1 then domtom=0;

			RUN;

			PROC datasets lib=WORK; 
				delete psid_all_fborn_cit&i ; 
			RUN;

			PROC sql; 
				create table psid_all_foreign_born&i. 
				as select 
				min(ident_all) as ident_all,
				min(year) as minyear,
				max(year) as maxyear,
				COUNT(ident_all) as nb_ident_all,
				SUM(dep_naiss_err) as nb_dep_naiss_err, 
				SUM(foreign_born) as nb_foreign_born, 
				SUM(domtom) as nb_domtom
				from psid_all_fborn_citB&i (DROP=ETRANGER DEP_NAISS )
				group by ident_all;
			QUIT;

			data psid_all_foreign_bornB&i (keep=ident_all minyear maxyear fborn_def domtom_def
										where=(fborn_def>0 or domtom_def>0)); 
				set psid_all_foreign_born&i; 
				if nb_ident_all-nb_dep_naiss_err>0 then pforeign_born=nb_foreign_born/(nb_ident_all-nb_dep_naiss_err);
				if nb_ident_all-nb_dep_naiss_err>0 then pdomtom=nb_domtom/(nb_ident_all-nb_dep_naiss_err);
				fborn_def=(pforeign_born>=0.5);
				domtom_def=(pdomtom>=0.5);
				if nb_dep_naiss_err=nb_ident_all then do; 
					fborn_def=9;
					domtom_def=9;
				end;
			RUN;

			PROC datasets lib=WORK; 
				delete psid_all_foreign_born&i ; 
			RUN;

			PROC sql; 
				create table psid_all_citizen&i (where = (nb_noncitizen>0))
				as select
				MIN(IDENT_ALL) as IDENT_ALL,
				COUNT(ident_all) as nb_ident_all,
				MIN(YEAR) as minyear,
				MAX(YEAR) as maxyear,
				MIN(exp(log(YEAR*noncitizen))) as firstyearnoncitizen, 
				MAX(YEAR*noncitizen) as lastyearnoncitizen, 
				MIN(exp(log(YEAR*(1-noncitizen)))) as firstyearcitizen, 
				SUM(noncitizen) as nb_noncitizen, 
				SUM(nonEU_citizen) as nb_nonEU_citizen,
				SUM(EU_citizen) as nb_EU_citizen,
				SUM(nonEU_citizen=1 and 2005<=YEAR<=2008 ) as nb_nonEU_citizen_pby,
				count(year) as nb_year
				from psid_all_fborn_citB&i (KEEP =IDENT_ALL noncitizen EU_citizen nonEU_citizen year where=(year<2016))
				group by ident_all;
			QUIT;

			PROC datasets lib=WORK; 
				delete psid_all_fborn_citB&i ; 
			RUN;

			data psid_all_citizenB&i (where=(foreign_nat_origin=1));
				set psid_all_citizen&i ;
				if (MAX(2005-minyear,0)+Max(maxyear-2008,0))>0 then 
					share_foreign=(nb_noncitizen-nb_nonEU_citizen_pby)/(MAX(2005-minyear,0)+Max(maxyear-2008,0));
				
				errornat=((nb_nonEU_citizen_pby=nb_noncitizen and nb_EU_citizen<1 and (minyear<2005 or maxyear>2008)) 
					OR (firstyearnoncitizen>minyear+1 and share_foreign<0.5 and nb_noncitizen-nb_nonEU_citizen_pby<4)
					OR (firstyearnoncitizen=minyear+1 and nb_year>3 and nb_noncitizen<2 and share_foreign<0.5 and nb_noncitizen-nb_nonEU_citizen_pby<4))*1;

				if errornat=0 then do; 
					gets_french_nat=max(lastyearnoncitizen+1,firstyearcitizen);
					if gets_french_nat>maxyear then gets_french_nat=.;
					foreign_nat_origin=1;
					IF nb_EU_citizen>0 then EU_nat_origin=1;
					else if ((gets_french_nat<2005 and gets_french_nat NE .) or (gets_french_nat=. and maxyear<2005)) and foreign_nat_origin=1 and EU_nat_origin=. then EU_nat_origin=9;
					if EU_nat_origin <1 then EU_nat_origin=0;
				end;
			RUN;

			PROC datasets lib=WORK; 
				delete psid_all_citizen&i ; 
			RUN;

			%let i=%eval(&i+1);
		%end;
		data psid_fbo.psid_all_foreign_born ; 
			set psid_all_foreign_bornb1 psid_all_foreign_bornb2 psid_all_foreign_bornb3 psid_all_foreign_bornb4 psid_all_foreign_bornb5 psid_all_foreign_bornb6 psid_all_foreign_bornb7 psid_all_foreign_bornb8 psid_all_foreign_bornb9; 
			keep ident_all fborn_def domtom_def minyear maxyear ;
		RUN;

		data psid_fbo.psid_all_citizen; 
			set psid_all_citizenb1 psid_all_citizenb2 psid_all_citizenb3 psid_all_citizenb4 psid_all_citizenb5 psid_all_citizenb6 psid_all_citizenb7 psid_all_citizenb8 psid_all_citizenb9; 
			keep ident_all gets_french_nat minyear EU_nat_origin foreign_nat_origin minyear maxyear;
		RUN;

		PROC datasets lib=work;
			delete psid_all_citizenb1 psid_all_citizenb2 psid_all_citizenb3 psid_all_citizenb4 psid_all_citizenb5 psid_all_citizenb6 psid_all_citizenb7 psid_all_citizenb8 psid_all_citizenb9 
					psid_all_foreign_bornb1 psid_all_foreign_bornb2 psid_all_foreign_bornb3 psid_all_foreign_bornb4 psid_all_foreign_bornb5 psid_all_foreign_bornb6 psid_all_foreign_bornb7 psid_all_foreign_bornb8 psid_all_foreign_bornb9; 
		RUN;

	PROC datasets lib=WORK; 
					Delete
						psid_fborn_1994 
						psid_fborn_1995 
						psid_fborn_1996 
						psid_fborn_1997 
						psid_fborn_1998 
						psid_fborn_1999 
						psid_fborn_2000 
						psid_fborn_2001 
						psid_fborn_2002 
						psid_fborn_2003 
						psid_fborn_2004 
						psid_fborn_2005 
						psid_fborn_2006 
						psid_fborn_2007 
						psid_fborn_2008 
						psid_fborn_2009 
						psid_fborn_2010 
						psid_fborn_2011 
						psid_fborn_2012 
						psid_fborn_2013 
						psid_fborn_2014 
						psid_fborn_2015 
						psid_fborn_2016 
						psid_fborn_2017 
						psid_fborn_2018 
						psid_fborn_2019 
						psid_fborn_2020 
						; 
					RUN;
	%MEND;

	%MACRO psid_sen_fborn(y,citizen); 
		%let y02=%substr(&y,3,2);
		%if &y<2016 %then %let ETRANGER=ETRANGER;
			%else %let ETRANGER=;

		PROC sql; 
			create table psid_sen.psidA_&y (drop=minyear maxyear)
				as select * from psid_sen.psid_sen_&y as a 
				left join psid_fbo.psid_all_foreign_born 
							(keep=ident_all fborn_def domtom_def minyear maxyear 
							where=(minyear<=&y and maxyear>=&y)) as b
				on a.ident_all=b.ident_all; 
		QUIT;
		DATA psid_sen.psidB_&y; 
			SET psid_sen.psidA_&y; 
				if domtom_def=. then domtom_def=0; 
				if fborn_def=. then fborn_def=0; 
		RUN;

		PROC datasets lib=psid_sen;
				DELETE psidA_&y;
		RUN;

		PROC datasets lib=psid_sen;
			CHANGE psidB_&y=psidA_&y;
		RUN;

		%if &y>2015 %then %let where=(minyear>2014);
		%else %let where=(minyear<=&y and maxyear>=&y);


		%if &citizen=YES %then %do; 
			PROC sql; 
				create table psid_sen.psidB_&y (drop=minyear maxyear) 
					as select * from psid_sen.psidA_&y as a 
					left join psid_fbo.psid_all_citizen (keep=ident_all gets_french_nat minyear EU_nat_origin foreign_nat_origin minyear maxyear where=&where) as b
					on a.ident_all=b.ident_all; 
			QUIT;

			PROC datasets lib=psid_sen;
				DELETE psidA_&y;
			RUN;

			data psid_sen.psid_sen_&y; set psid_sen.psidB_&y;
				foreign_def=(foreign_nat_origin=1 and (gets_french_nat=. or &y<gets_french_nat));
				year_entry=(ident_all-100*int(ident_all/100))+
							((ident_all-100*int(ident_all/100))>90)*1900+
							((ident_all-100*int(ident_all/100))<90)*2000;							
				if year_entry>2015 then foreign_def=9;
				if foreign_nat_origin=. then foreign_nat_origin=0; 
				if EU_nat_origin=. then EU_nat_origin=0; 
				DROP year_entry;
			RUN;
		
			PROC datasets lib=psid_sen;
				DELETE psidB_&y;
			RUN;
		%end;
		%else %do; 
			PROC datasets lib=psid_sen;
				DELETE psid_sen_&y;
			RUN;
			PROC datasets lib=psid_sen;
				CHANGE psidA_&y=psid_sen_&y;
			RUN;
		%end;
	%MEND;
******************************************************************************;



******************************************************************************;
* 2. RUN THE MACROS WITH YOUR OWN PARAMETERS;
******************************************************************************;

	******************************************************************************;
	* 2.a. Libnames;
	******************************************************************************;
	%my_libnames(casd_project=%sysget(CASD_PROJECT));

	PROC printto log="C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_foreign_born\log_psid_fbor.txt" new; 
	RUN;
		
		/* Uncomment below if you want to see the log again;*/
		/*
		PROC printto log=log new; 
		RUN; 
		*/

	******************************************************************************;
	* 2.b. Collecting foreign born and citizenship variables with a common identifier;
	******************************************************************************;
		%psid_fborn(1994);
		%psid_fborn(1995);
		%psid_fborn(1996);
		%psid_fborn(1997);
		%psid_fborn(1998);
		%psid_fborn(1999);
		%psid_fborn(2000);
		%psid_fborn(2001);
		%psid_fborn(2002);
		%psid_fborn(2003);
		%psid_fborn(2004);
		%psid_fborn(2005);
		%psid_fborn(2006);
		%psid_fborn(2007);
		%psid_fborn(2008);
		%psid_fborn(2009);
		%psid_fborn(2010);
		%psid_fborn(2011);
		%psid_fborn(2012);
		%psid_fborn(2013);
		%psid_fborn(2014);
		%psid_fborn(2015);
		%psid_fborn(2016);
		%psid_fborn(2017);
		%psid_fborn(2018);
		%psid_fborn(2019);
		%psid_fborn(2020);

	******************************************************************************;
	* 2.c. CREATING TWO CORRECTED FILES OF citizenship AND PLACE OF BIRTH;
	******************************************************************************;

		%all_foreign_born;

* note CH 21/03/23 - Il faut d'abor lancer le programme seniority avant de lancer la macro ci-dessous
* Le programme foreign born ci-dessus est lancé le 21/03/2023 à 11h30


	******************************************************************************;
	* 2.d. OPTIONAL: INCORPORATING INFORMATION IN psid_sen_yyyy FILES;
	*****************************************************************************;
	*	%psid_sen_fborn(1994,citizen=NO);
	*	%psid_sen_fborn(1995,citizen=NO);
	*	%psid_sen_fborn(1996,citizen=NO);
	*	%psid_sen_fborn(1997,citizen=NO);
	*	%psid_sen_fborn(1998,citizen=NO);
	*	%psid_sen_fborn(1999,citizen=NO);
	*	%psid_sen_fborn(2000,citizen=NO);
	*	%psid_sen_fborn(2001,citizen=NO);
	*	%psid_sen_fborn(2002,citizen=NO);
	*	%psid_sen_fborn(2003,citizen=NO);
	*	%psid_sen_fborn(2004,citizen=NO);
	*	%psid_sen_fborn(2005,citizen=NO);
	*	%psid_sen_fborn(2006,citizen=NO);
	*	%psid_sen_fborn(2007,citizen=NO);
	*	%psid_sen_fborn(2008,citizen=NO);
	*	%psid_sen_fborn(2009,citizen=NO);
	*	%psid_sen_fborn(2010,citizen=NO);
	*	%psid_sen_fborn(2011,citizen=NO);
	*	%psid_sen_fborn(2012,citizen=NO);
	*	%psid_sen_fborn(2013,citizen=NO);
	*	%psid_sen_fborn(2014,citizen=NO);
	*	%psid_sen_fborn(2015,citizen=NO);
	*	%psid_sen_fborn(2016,citizen=NO);
	*	%psid_sen_fborn(2017,citizen=NO);
	*	%psid_sen_fborn(2018,citizen=NO);
	*	%psid_sen_fborn(2019,citizen=NO);
	*	%psid_sen_fborn(2020,citizen=NO);

******************************************************************************;
* GOOD LUCK IN THE COMPLETION OF YOUR MANUSCRIPT ;
******************************************************************************;
