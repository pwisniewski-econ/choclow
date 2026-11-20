****************************************************************
* SCRIPT pseudo_id_seniority.sas 2022/10/10 (V1)               *
* Olivier Godechot                                             *
* Email: Olivier.Godechot [at] sciencespo.fr                   *
****************************************************************
* CREATES WORKERS' FIRM AND WORKPLACE YEARS OF ENTRY           *
****************************************************************

This program creates psid_sen_yyyy.sas7bdat files for all job spells 
where wage>0 with IDENT_S, SIREN and NIC matching variables, 
IDENT_ALL, our common pseudo-identifier and two additional variables, 
firm_entry and est_entry corresponding respectively to the year of entry
in the firm and in the establishment.

This script comes with 3 joint programs : 

	* 1. pseudo_id.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
	    which creates a common identifier IDENT_ALL for all files.

	* 2. pseudo_id_foreign_born.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
	    which corrects information on foreign born and citizenship which is obviously incorrect
		 for some years.

	* 3. pseudo_id_use.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
	    which gives an example of dads file creation with common identifiers.


****************************************************************
* HOW TO RUN THE PROGRAM  
****************************************************************

	* The program comes into two parts. 

		* 1. Resolve all the macros scripts. 

		* 2. Run the macros with your own parameters

			- a. Create the libnames

				%my_libnames(casd_project=A0INEPR) 

				* !!!! CHANGE A0INEPR !!! with the name of your CASD project (the name on your CASD Card)

			- b. Run the %psid_sen(yyyy) macros 

*****************************************************************************
* OUTPUT 
*****************************************************************************
* The program will create psid_sen_yyyy.sas7bdat files in the CASD common folder : 
	C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_seniority\

* The log file will be stored in the same folder


******************************************************************************
* SPACE AND TIME REQUIREMENTS 
******************************************************************************
	* TIME: Approximately 3 hours or so with a single user config 2 CASD platform. 
	* SPACE: At least 70 go hard drive available to RUN it smoothly
	* STORAGE: 50 Go storage with seniority variables. Note that the inital 
	* psid_yyyy.sas7bdat datasets produced by pseudo_id.sas can be suppressed 
	* once you ran pseudo_id.sas.

******************************************************************************
* HOW TO USE THE psid_sen_yyyy FILES  
******************************************************************************
	* - Use psid_sen_yyyy.sas7bdat files and merge them with your DADS files with
	* IDENT_S, SIREN and NIC. 
	
******************************************************************************
* WARNINGS AND DISCLAIMERS
******************************************************************************
* This program comes with absolutely no warranty of accurateness

* Known issues
	- Years of entry are based on SIREN and NIC. They are not robust to changes
	in firms' changes of their SIREN and NIC codes.
	
	- Years of entry can be calculated for workers successfully uniquely chained.
	Workers who are not chained will be givent their year-file first appearance 
	year of entry (or t-1 if they were present in t-1 of their year-file)

	- Match in 2002 is of poor quality (70% of workers). Hence we might miss estimate 
		entry years before 2002.

	- Moreover, before 2002, we cannot follow movers : 
		So firm_entry before 2002 will be reliable only for workers who do not 
		change establishments within the same firm. 

	- Finally, all years of entry are left-censored in 1993. (And 2009 for the Fonction 
	Publique d'Etat)

*****************************************************************************
* HOW TO CITE : 
*****************************************************************************
	Babet, Damien, Olivier Godechot and Marco G. Palladino, 2022. In the Land 
	of AKM: Explaining the Dynamics of Wage Inequality in France, 
	Document de travail, Insee (forthcoming). 
******************************************************************************

**********************************************************************************************************************************;

******************************************************************************;
* 1. MACROS SCRIPTS TO RESOLVE;
******************************************************************************;
	* Select (Keys: shift + arrows) and execute (Key: F3) the following lines to resolve the macros;

	%MACRO my_libnames(casd_project); 
		options ps=MAX ls=MAX nodate nonumber nocenter DLCREATEDIR;

		libname psid "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads";
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

	%MACRO m_9401(year);
		%let year2=%substr(&year,3,2);
		%let keep= SIREN NIC BRUT BRUT_1 REG DEP ;
		%let rename= RENAME=(REG=REGT BRUT=S_BRUT BRUT_1=S_BRUT_1);
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0);
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
			%common;
			drop COMR_ COM DEPR DEP;
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
		%let keep=SIREN NIC IDENT_S S_BRUT S_BRUT_1 REGT DEPT ;
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0) and MISSING(IDENT_S)=0;
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
			po&year..post99&year2 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ))
			;
			year=&year;
			%common;
		RUN;

	%MEND;

	%MACRO m_09(year);
		%let keep=SIREN NIC IDENT_S S_BRUT S_BRUT_1 REGT DEPT ;
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0) and MISSING(IDENT_S)=0;
		%let rename=;
		
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
			po&year..post99 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ))

			;
			year=&year;
			%common;
		RUN;
	%MEND;


	%MACRO m_10(year);
		%let keep=SIREN NIC IDENT_S S_BRUT S_BRUT_1 REGT DEPT ;
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0) and MISSING(IDENT_S)=0;
		%let rename=;
		
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
			%common;
		RUN;
	%MEND;



	%MACRO m_11(year);
		%let keep=SIREN NIC IDENT_S S_BRUT S_BRUT_1 REGT DEPT ;
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0) and MISSING(IDENT_S)=0;
		%let rename=;
		
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
			po&year..post99 (&rename keep=&keep  WHERE=(REGT IN ("00","99") &where  ));
			year=&year;
			%common;
		RUN;
	%MEND;


	%MACRO m_1213(year);
		%let keep=SIREN NIC IDENT_S S_BRUT S_BRUT_1 REGT DEPT ;
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0) and MISSING(IDENT_S)=0;
		%let rename=;
		
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
			%common;
		RUN;	
	%MEND;


	%MACRO m_1417(year);
		%let keep=SIREN NIC IDENT_S S_BRUT S_BRUT_1 REGT DEPT ;
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0) and MISSING(IDENT_S)=0;
		%let rename=;
		

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
			%common;
		RUN;
	%MEND;

	%MACRO m_1819(year);
		%let keep=SIREN NIC IDENT_S S_BRUT S_BRUT_1 REGT DEPT ;
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0) and MISSING(IDENT_S)=0;
		%let rename=; 

		data b&year; 
			set 
			po&year..post_1 (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			po&year..post_2 (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			po&year..post_3 (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			po&year..post_4 (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			;
			year=&year;
				%common;		 
		RUN;

		
	%MEND;

	%MACRO m_20(year);
		%let keep=SIREN NIC IDENT_S S_BRUT S_BRUT_1 REGT DEPT ;
		%let where=AND (S_BRUT>0 OR S_BRUT_1>0) and MISSING(IDENT_S)=0;
		%let rename=; 

		data b&year; 
			set 
			po&year..post (&rename KEEP=&keep WHERE=(REGT NOT IN ("") &where))
			;
			year=&year;
				%common;		 

		RUN;

		
	%MEND;

	%MACRO common;
				%if &year<2002 %then %do;
					SIREN=compress(substr(SIREN,2,9));
					NIC=Compress(SUBSTR(NIC,2,6));
				%end;
	%MEND;

	%macro psid_sen(year);

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
				create table &b.1  
				as select * from &b
				as aa
				left join psid.psid_&year (keep=ident_s ident_all)
				as bb
				on aa.ident_s=bb.ident_s;
		quit;

		data &b.2; set &b.1;
			if Missing(ident_all) then do; 
				ident_all=ident_s*100+&year2;
			end;
			ident_all=compress(""!!ident_all!!"");
			t_1=(S_BRUT_1>0);
			t=(S_BRUT>0);
		RUN;
		PROC sql; 
				create table est  
				as select 
				min(IDENT_ALL) as IDENT_ALL, 
				min(SIREN) as SIREN, 
				min(NIC) as NIC,
				min(IDENT_S) as IDENT_S,
				max(t_1) as t_1,
				max(t) as t
				from &b.2 (keep=ident_all SIREN NIC t_1 t IDENT_S)
				GROUP BY ident_all, SIREN, NIC ; 
				;
		quit;

		%if &year=1994 %then %do; 
			data psid_sen.psid_sen_&year; 
				set est(where=(t>0)); 
				est_entry=&year-t_1;
				firm_entry=&year-t_1;
			RUN;
		%end;
		%else %do; 
			PROC sql; create table est2 as select
				* from est as aa left join psid_sen.psid_sen_&year_1 (keep=ident_all siren nic est_entry) as bb
				on aa.ident_all=bb.ident_all and aa.siren=bb.siren and aa.nic=bb.nic; 
			quit;

			PROC sql; 
				create table firm  
				as select 
				min(IDENT_ALL) as IDENT_ALL, 
				min(SIREN) as SIREN,
				min(firm_entry) as firm_entry
				from psid_sen.psid_sen_&year_1 (keep=ident_all SIREN firm_entry)
				GROUP BY ident_all, SIREN; 
				;
			quit;

			PROC sql; create table est3 as select
				*
				from est2 as aa left join firm as bb
				on aa.ident_all=bb.ident_all and aa.siren=bb.siren; 
			quit;

			PROC sql; create table est4 as select
				*,
				max(t_1) as t_1f
				from est3  GROUP BY ident_all, SIREN; 
			quit;


			data psid_sen.psid_sen_&year ; set est4 (where=(t>0)); 
				if missing(est_entry) then est_entry=&year-t_1;
				if missing(firm_entry) then firm_entry=&year-t_1f;
				drop t_1 t_1f t;
			RUN;
		%end;

		PROC datasets LIBRARY=WORK; 
			DELETE &b &b.1 &b.2 est est2 est3 firm ;
		RUN;
	%MEND;

******************************************************************************;
******************************************************************************;




******************************************************************************;
* 2. RUN THE MACROS WITH YOUR OWN PARAMETERS;
******************************************************************************;

	******************************************************************************;
	* 2.a. Libnames;
	******************************************************************************;
	%my_libnames(casd_project=%sysget(CASD_PROJECT));

	PROC printto log="C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_seniority\log_psid_sen.txt" new; 
	RUN;

	******************************************************************************;
	* 2.b. Seniority scripts;
	******************************************************************************;
	%psid_sen(1994);
	%psid_sen(1995);
	%psid_sen(1996);
	%psid_sen(1997);
	%psid_sen(1998);
	%psid_sen(1999);
	%psid_sen(2000);
	%psid_sen(2001);
	%psid_sen(2002);
	%psid_sen(2003);
	%psid_sen(2004);
	%psid_sen(2005);
	%psid_sen(2006);
	%psid_sen(2007);
	%psid_sen(2008);
	%psid_sen(2009);
	%psid_sen(2010);
	%psid_sen(2011);
	%psid_sen(2012);
	%psid_sen(2013);
	%psid_sen(2014);
	%psid_sen(2015);
	%psid_sen(2016);
	%psid_sen(2017);
	%psid_sen(2018);
	%psid_sen(2019);
	%psid_sen(2020);
******************************************************************************;
* GOOD LUCK IN THE COMPLETION OF YOUR MANUSCRIPT ;
******************************************************************************;
