****************************************************************
* SCRIPT pseudo_id_use.sas 2022/10/10 (V1)                     *
* Olivier Godechot                                             *
* Email: Olivier.Godechot [at] sciencespo.fr                   *
****************************************************************
* EXAMPLE OF DADS USE FILES CREATION WITH COMMON IDENTIFIERS,
* SENIORITY VARIABLES, AND CORRECTED FOREIGN BORN VARIABLES
****************************************************************

This script helps you to create complete yearly DADS SAS or STATA
files with our common pseudo-identifier IDENT_ALL, optionally seniority
variables and corrected birth location, wage S_BRUT, firms id variables SIREN and NIC,
region of work REGT as well as all variables that you decide to keep from the DADS.


* This script  comes with 3 joint programs : 

	* 1. pseudo_id.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		which creates an common identifier IDENT_ALL for all files.

	* 2. pseudo_id_foreign_born.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		which corrects information on foreign and over-sea borns and citizenship which is obviously incorrect
		for some years.

	* 3. pseudo_id_seniority.sas (http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip)
		which calculates the year of entry in the firm and the establishment and enables to 
		calculate seniority.


****************************************************************
* HOW TO RUN THE PROGRAM  
****************************************************************

* The program comes into two parts. 

	* 1. Resolve all the macros scripts. 

	* 2. Run the macros with your own parameters

		* 2.a Create the libnames

			%my_libnames(casd_project=A0INEPR) 

			* !!!! CHANGE A0INEPR !!! with the name of your CASD project (written on your CASD card)

		* 2.b Run the macros %psid_use()

		Parameters:

			keep=VAR1 ... VARn
				Supplementary variables you want to keep. Beware some variable names change

					(By default we already keep IDENT_S SIREN NIC S_BRUT REGT and for some years DEPT)
				
			rename=NAMEVAR1=NEWNAMEVAR1 ... NAMEVARn=NEWNAMEVARn
				Rename the variables to append data more easily. 
				Beware codings change : Notably DOMEMPL in 2002, APET and APEN in 2008, etc.

			where=VAR1>THRESHOLD1 AND VAR2=VALUE2 (example)
				Supplementary restrictions on the dataset.

					(By default we already restrict to S_BRUT>0 AND REGT="codereg" 
					 -- i.e. workers who work in the region of the regionyearfile (to avoid double count)--)

			seniority=YES imports the year of entry variables

				(you must RUN first pseudo_id_seniority.sas)

			foreign_born=YES imports the corrected foreign and oversea born variables

				(you must RUN first pseudo_id_foreign_born.sas)

			citizen=YES imports the corrected citizenship variables

				(you must RUN first pseudo_id_foreign_born.sas)

			stata=YES creates a Stata dads file instead of a SAS one (and deletes the sas output)
	
*****************************************************************************
* OUTPUT 
*****************************************************************************

	* The program will create dads_yyyy.sas7bdat SAS files 
		or dads_yyyy.dta STATA files in the DADS_OUT folder : 
		C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\dads_out\


******************************************************************************
* SPACE AND TIME REQUIREMENTS 
******************************************************************************

	* TIME: Approximately 5 to 30 minutes per yearfile depending on the 
		options.

	* SPACE: 1 to 6.3 Go per yearfile depending on the options and the number 
		of variables you keep 

******************************************************************************
* WARNINGS AND DISCLAIMERS
******************************************************************************

	* This program comes with absolutely no warranty of accurateness

*****************************************************************************
* HOW TO CITE : 
*****************************************************************************
	Babet, Damien, Olivier Godechot and Marco G. Palladino, 2022. In the Land 
	of AKM: Explaining the Dynamics of Wage Inequality in France, Document 
	de travail, Insee (forthcoming). 
******************************************************************************


**********************************************************************************************************************************;

******************************************************************************;
* 1. MACROS SCRIPTS TO RESOLVE;
******************************************************************************;
	* Select (Keys: shift + arrows) and execute (Key: F3) the following lines to resolve the macros;

	* MACRO MY_LIBNAMES;
	%MACRO my_libnames(casd_project); 
		options ps=MAX ls=MAX nodate nonumber nocenter DLCREATEDIR;
	
		libname psid "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads";
		libname psid_sen "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_seniority";
		libname psid_fbo "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\pseudo_id_foreign_born";
		libname dads_out "C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\dads_out";


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

**********************************************;
* 1. MACRO SCRIPTS; 
**********************************************;
	%MACRO m_9401(year,keep,where,rename);
		%let year2=%substr(&year,3,2);

		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;

		%let keep_2=SIREN NIC BRUT REG &keep;
		%let rename_2=RENAME=(REG=REGT BRUT=S_BRUT &rename);
		%let where_2= AND S_BRUT>0 &where_p;

			%MACRO b_reg(reg);
				DATA b&reg._&year2; 
					SET po&year..post&reg.&year2 
						(&rename_2 
							KEEP=&keep_2);
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
			b11_&year2 (WHERE=(REGT="11" &where_2))
			b21_&year2 (WHERE=(REGT="21" &where_2))
			b22_&year2 (WHERE=(REGT="22" &where_2))
			b23_&year2 (WHERE=(REGT="23" &where_2))
			b24_&year2 (WHERE=(REGT="24" &where_2))
			b25_&year2 (WHERE=(REGT="25" &where_2))
			b26_&year2 (WHERE=(REGT="26" &where_2))
			b31_&year2 (WHERE=(REGT="31" &where_2))
			b41_&year2 (WHERE=(REGT="41" &where_2))
			b42_&year2 (WHERE=(REGT="42" &where_2))
			b43_&year2 (WHERE=(REGT="43" &where_2))
			b52_&year2 (WHERE=(REGT="52" &where_2))
			b53_&year2 (WHERE=(REGT="53" &where_2))
			b54_&year2 (WHERE=(REGT="54" &where_2))
			b72_&year2 (WHERE=(REGT="72" &where_2))
			b73_&year2 (WHERE=(REGT="73" &where_2))
			b74_&year2 (WHERE=(REGT="74" &where_2))
			b82_&year2 (WHERE=(REGT="82" &where_2))
			b83_&year2 (WHERE=(REGT="83" &where_2))
			b91_&year2 (WHERE=(REGT="91" &where_2))
			b93_&year2 (WHERE=(REGT="93" &where_2))
			b94_&year2 (WHERE=(REGT="94" &where_2))
			b97_&year2 (WHERE=(REGT IN ("01","02","03","04","05","06","97","97") &where_2))
			b99_&year2 (WHERE=(REGT IN ("00","99") &where_2))
			;
			year=&year;
			%common;
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

	%MACRO m_0208(year,keep,where,rename);
		%let year2=%substr(&year,3,2);

		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;

		%let keep_2=SIREN NIC IDENT_S S_BRUT REGT &keep ;
		%let where_2= AND S_BRUT>0 &where_p;
		%let rename_2=&rename_p;

		data b&year; 
			set 
			po&year..post11&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post21&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="21" &where_2  )) 
			po&year..post22&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="22" &where_2  )) 
			po&year..post23&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="23" &where_2  )) 
			po&year..post24&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="24" &where_2  )) 
			po&year..post25&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="25" &where_2  )) 
			po&year..post26&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="26" &where_2  )) 
			po&year..post31&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="31" &where_2  )) 
			po&year..post41&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="41" &where_2  )) 
			po&year..post42&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="42" &where_2  )) 
			po&year..post43&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="43" &where_2  )) 
			po&year..post52&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="52" &where_2  )) 
			po&year..post53&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="53" &where_2  )) 
			po&year..post54&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="54" &where_2  )) 
			po&year..post72&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="72" &where_2  )) 
			po&year..post73&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="73" &where_2  )) 
			po&year..post74&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="74" &where_2  )) 
			po&year..post82&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="82" &where_2  )) 
			po&year..post83&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="83" &where_2  )) 
			po&year..post91&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="91" &where_2  )) 
			po&year..post93&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="93" &where_2 ))
			po&year..post94&year2 (&rename_2 keep=&keep_2 WHERE=(REGT="94" &where_2  ))
			po&year..post97&year2 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where_2  ))
			po&year..post99&year2 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("00","99") &where_2  ))
			;
			year=&year;
			%common;
		RUN;

	%MEND;

	%MACRO m_09(year,keep,where,rename);
		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;

		%let keep_2=SIREN NIC IDENT_S S_BRUT REGT &keep ;
		%let where_2= AND S_BRUT>0 &where_p;
		%let rename_2=&rename_p;
		
		data b&year; 
			set 
			po&year..post11aa (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post11bb (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post11cc (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post11dd (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post21 (&rename_2 keep=&keep_2 WHERE=(REGT="21" &where_2  )) 
			po&year..post22 (&rename_2 keep=&keep_2 WHERE=(REGT="22" &where_2  )) 
			po&year..post23 (&rename_2 keep=&keep_2 WHERE=(REGT="23" &where_2  )) 
			po&year..post24 (&rename_2 keep=&keep_2 WHERE=(REGT="24" &where_2  )) 
			po&year..post25 (&rename_2 keep=&keep_2 WHERE=(REGT="25" &where_2  )) 
			po&year..post26 (&rename_2 keep=&keep_2 WHERE=(REGT="26" &where_2  )) 
			po&year..post31 (&rename_2 keep=&keep_2 WHERE=(REGT="31" &where_2  )) 
			po&year..post41 (&rename_2 keep=&keep_2 WHERE=(REGT="41" &where_2  )) 
			po&year..post42 (&rename_2 keep=&keep_2 WHERE=(REGT="42" &where_2  )) 
			po&year..post43 (&rename_2 keep=&keep_2 WHERE=(REGT="43" &where_2  )) 
			po&year..post52 (&rename_2 keep=&keep_2 WHERE=(REGT="52" &where_2  )) 
			po&year..post53 (&rename_2 keep=&keep_2 WHERE=(REGT="53" &where_2  )) 
			po&year..post54 (&rename_2 keep=&keep_2 WHERE=(REGT="54" &where_2  )) 
			po&year..post72 (&rename_2 keep=&keep_2 WHERE=(REGT="72" &where_2  )) 
			po&year..post73 (&rename_2 keep=&keep_2 WHERE=(REGT="73" &where_2  )) 
			po&year..post74 (&rename_2 keep=&keep_2 WHERE=(REGT="74" &where_2  ))
			po&year..post82 (&rename_2 keep=&keep_2 WHERE=(REGT="82" &where_2  )) 
			po&year..post83 (&rename_2 keep=&keep_2 WHERE=(REGT="83" &where_2  )) 
			po&year..post91 (&rename_2 keep=&keep_2 WHERE=(REGT="91" &where_2  )) 
			po&year..post93 (&rename_2 keep=&keep_2 WHERE=(REGT="93" &where_2  ))
			po&year..post94 (&rename_2 keep=&keep_2 WHERE=(REGT="94" &where_2  ))
			po&year..post97 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where_2  ))
			po&year..post99 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("00","99") &where_2  ))

			;
			year=&year;
			%common;
			
		RUN;

		
	%MEND;


	%MACRO m_10(year,keep,where,rename);
		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;

		%let keep_2=SIREN NIC IDENT_S S_BRUT REGT &keep ;
		%let where_2= AND S_BRUT>0 &where_p;
		%let rename_2=&rename_p;
		
		data b&year; 
			set 
			po&year..post11aa (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post11bb (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post11cc (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post11dd (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post21 (&rename_2 keep=&keep_2 WHERE=(REGT="21" &where_2  )) 
			po&year..post22 (&rename_2 keep=&keep_2 WHERE=(REGT="22" &where_2  )) 
			po&year..post23 (&rename_2 keep=&keep_2 WHERE=(REGT="23" &where_2  )) 
			po&year..post24 (&rename_2 keep=&keep_2 WHERE=(REGT="24" &where_2  )) 
			po&year..post25 (&rename_2 keep=&keep_2 WHERE=(REGT="25" &where_2  )) 
			po&year..post26 (&rename_2 keep=&keep_2 WHERE=(REGT="26" &where_2  )) 
			po&year..post31 (&rename_2 keep=&keep_2 WHERE=(REGT="31" &where_2  )) 
			po&year..post41 (&rename_2 keep=&keep_2 WHERE=(REGT="41" &where_2  )) 
			po&year..post42 (&rename_2 keep=&keep_2 WHERE=(REGT="42" &where_2  )) 
			po&year..post43 (&rename_2 keep=&keep_2 WHERE=(REGT="43" &where_2  )) 
			po&year..post52 (&rename_2 keep=&keep_2 WHERE=(REGT="52" &where_2  )) 
			po&year..post53 (&rename_2 keep=&keep_2 WHERE=(REGT="53" &where_2  )) 
			po&year..post54 (&rename_2 keep=&keep_2 WHERE=(REGT="54" &where_2  )) 
			po&year..post72 (&rename_2 keep=&keep_2 WHERE=(REGT="72" &where_2  )) 
			po&year..post73 (&rename_2 keep=&keep_2 WHERE=(REGT="73" &where_2  )) 
			po&year..post74 (&rename_2 keep=&keep_2 WHERE=(REGT="74" &where_2  ))
			po&year..post82a (&rename_2 keep=&keep_2 WHERE=(REGT="82" &where_2  )) 
			po&year..post82b (&rename_2 keep=&keep_2 WHERE=(REGT="82" &where_2  )) 
			po&year..post91 (&rename_2 keep=&keep_2 WHERE=(REGT="91" &where_2  )) 
			po&year..post93 (&rename_2 keep=&keep_2 WHERE=(REGT="93" &where_2))
			po&year..post94 (&rename_2 keep=&keep_2 WHERE=(REGT="94" &where_2  ))
			po&year..post97 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where_2  ))
			po&year..post99 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("00","99") &where_2  ))
			;
			year=&year;
			%common;
			
		RUN;

		
	%MEND;



	%MACRO m_11(year,keep,where,rename);
		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;
		%let keep_2=SIREN NIC IDENT_S S_BRUT REGT &keep ;
		%let where_2= AND S_BRUT>0 &where_p;
		%let rename_2=&rename_p;
		
		data b&year; 
			set 
			po&year..post11 (&rename_2 keep=&keep_2 WHERE=(REGT="11" &where_2  )) 
			po&year..post21 (&rename_2 keep=&keep_2 WHERE=(REGT="21" &where_2  )) 
			po&year..post22 (&rename_2 keep=&keep_2 WHERE=(REGT="22" &where_2  )) 
			po&year..post23 (&rename_2 keep=&keep_2 WHERE=(REGT="23" &where_2  )) 
			po&year..post24 (&rename_2 keep=&keep_2 WHERE=(REGT="24" &where_2  )) 
			po&year..post25 (&rename_2 keep=&keep_2 WHERE=(REGT="25" &where_2  )) 
			po&year..post26 (&rename_2 keep=&keep_2 WHERE=(REGT="26" &where_2  )) 
			po&year..post31 (&rename_2 keep=&keep_2 WHERE=(REGT="31" &where_2  )) 
			po&year..post41 (&rename_2 keep=&keep_2 WHERE=(REGT="41" &where_2  )) 
			po&year..post42 (&rename_2 keep=&keep_2 WHERE=(REGT="42" &where_2  )) 
			po&year..post43 (&rename_2 keep=&keep_2 WHERE=(REGT="43" &where_2  )) 
			po&year..post52 (&rename_2 keep=&keep_2 WHERE=(REGT="52" &where_2  )) 
			po&year..post53 (&rename_2 keep=&keep_2 WHERE=(REGT="53" &where_2  )) 
			po&year..post54 (&rename_2 keep=&keep_2 WHERE=(REGT="54" &where_2  )) 
			po&year..post72 (&rename_2 keep=&keep_2 WHERE=(REGT="72" &where_2  )) 
			po&year..post73 (&rename_2 keep=&keep_2 WHERE=(REGT="73" &where_2  )) 
			po&year..post74 (&rename_2 keep=&keep_2 WHERE=(REGT="74" &where_2  ))
			po&year..post82 (&rename_2 keep=&keep_2 WHERE=(REGT="82" &where_2  )) 
			po&year..post83 (&rename_2 keep=&keep_2 WHERE=(REGT="83" &where_2  )) 
			po&year..post91 (&rename_2 keep=&keep_2 WHERE=(REGT="91" &where_2  )) 
			po&year..post93 (&rename_2 keep=&keep_2 WHERE=(REGT="93" &where_2))
			po&year..post94 (&rename_2 keep=&keep_2 WHERE=(REGT="94" &where_2  ))
			po&year..post97 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where_2  ))
			po&year..post99 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("00","99") &where_2  ))

			;
			year=&year;
			%common;
			
		RUN;

		
	%MEND;


	%MACRO m_1213(year,keep,where,rename);
		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;

		%let keep_2=SIREN NIC IDENT_S S_BRUT REGT DEPT &keep ;
		%let where_2= AND S_BRUT>0 &where_p;
		%let rename_2=&rename_p;
		
		data b&year; 
			set 
			pi&year..post75 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="75" &where_2  ))
			pi&year..post77 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="77" &where_2  ))
			pi&year..post78 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="78" &where_2  ))
			pi&year..post91 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="91" &where_2  ))
			pi&year..post92 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="92" &where_2  ))
			pi&year..post93 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="93" &where_2  ))
			pi&year..post94 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="94" &where_2  ))
			pi&year..post95 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="95" &where_2  ))
			po&year..post21 (&rename_2 keep=&keep_2 WHERE=(REGT="21" &where_2  )) 
			po&year..post22 (&rename_2 keep=&keep_2 WHERE=(REGT="22" &where_2  )) 
			po&year..post23 (&rename_2 keep=&keep_2 WHERE=(REGT="23" &where_2  )) 
			po&year..post24 (&rename_2 keep=&keep_2 WHERE=(REGT="24" &where_2  )) 
			po&year..post25 (&rename_2 keep=&keep_2 WHERE=(REGT="25" &where_2  )) 
			po&year..post26 (&rename_2 keep=&keep_2 WHERE=(REGT="26" &where_2  )) 
			po&year..post31 (&rename_2 keep=&keep_2 WHERE=(REGT="31" &where_2  )) 
			po&year..post41 (&rename_2 keep=&keep_2 WHERE=(REGT="41" &where_2  )) 
			po&year..post42 (&rename_2 keep=&keep_2 WHERE=(REGT="42" &where_2  )) 
			po&year..post43 (&rename_2 keep=&keep_2 WHERE=(REGT="43" &where_2  )) 
			po&year..post52 (&rename_2 keep=&keep_2 WHERE=(REGT="52" &where_2  )) 
			po&year..post53 (&rename_2 keep=&keep_2 WHERE=(REGT="53" &where_2  )) 
			po&year..post54 (&rename_2 keep=&keep_2 WHERE=(REGT="54" &where_2  )) 
			po&year..post72 (&rename_2 keep=&keep_2 WHERE=(REGT="72" &where_2  )) 
			po&year..post73 (&rename_2 keep=&keep_2 WHERE=(REGT="73" &where_2  )) 
			po&year..post74 (&rename_2 keep=&keep_2 WHERE=(REGT="74" &where_2  ))
			po&year..post82 (&rename_2 keep=&keep_2 WHERE=(REGT="82" &where_2  )) 
			po&year..post83 (&rename_2 keep=&keep_2 WHERE=(REGT="83" &where_2  )) 
			po&year..post91 (&rename_2 keep=&keep_2 WHERE=(REGT="91" &where_2  )) 
			po&year..post93 (&rename_2 keep=&keep_2 WHERE=(REGT="93" &where_2))
			po&year..post94 (&rename_2 keep=&keep_2 WHERE=(REGT="94" &where_2  ))
			po&year..post97 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where_2  ))
			po&year..post99 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("00","99") &where_2  ))

			;
			year=&year;
			%common;
			
		RUN;

		
	%MEND;


	%MACRO m_1417(year,keep,where,rename);
		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;

		%let keep_2=SIREN NIC IDENT_S S_BRUT REGT DEPT &keep ;
		%let where_2= AND S_BRUT>0 &where_p;
		%let rename_2=&rename_p;
		

		data b&year; 
			set 
			pi&year..post75 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="75" &where_2  ))
			pi&year..post77 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="77" &where_2  ))
			pi&year..post78 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="78" &where_2  ))
			pi&year..post91 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="91" &where_2  ))
			pi&year..post92 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="92" &where_2  ))
			pi&year..post93 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="93" &where_2  ))
			pi&year..post94 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="94" &where_2  ))
			pi&year..post95 (&rename_2 keep=&keep_2 DEPT WHERE=(DEPT="95" &where_2  ))

			po&year..post24 (&rename_2 keep=&keep_2 WHERE=(REGT="24" &where_2  )) 
			po&year..post27 (&rename_2 keep=&keep_2 WHERE=(REGT="27" &where_2  )) 
			po&year..post28 (&rename_2 keep=&keep_2 WHERE=(REGT="28" &where_2  )) 
			po&year..post32 (&rename_2 keep=&keep_2 WHERE=(REGT="32" &where_2  )) 
			po&year..post44 (&rename_2 keep=&keep_2 WHERE=(REGT="44" &where_2  )) 
			po&year..post52 (&rename_2 keep=&keep_2 WHERE=(REGT="52" &where_2  )) 
			po&year..post53 (&rename_2 keep=&keep_2 WHERE=(REGT="53" &where_2  )) 
			po&year..post75 (&rename_2 keep=&keep_2 WHERE=(REGT="75" &where_2  )) 
			po&year..post76 (&rename_2 keep=&keep_2 WHERE=(REGT="76" &where_2  )) 
			po&year..post84 (&rename_2 keep=&keep_2 WHERE=(REGT="84" &where_2  )) 
			po&year..post93 (&rename_2 keep=&keep_2 WHERE=(REGT="93" &where_2  ))
			po&year..post94 (&rename_2 keep=&keep_2 WHERE=(REGT="94" &where_2  ))
			po&year..post97 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("01","02","03","04","05","06","97","98") &where_2  ))
			po&year..post99 (&rename_2 keep=&keep_2 WHERE=(REGT IN ("00","99") &where_2  ))

			;
			year=&year;
			%common;
			
		RUN;

		
	%MEND;

	%MACRO m_1819(year,keep,where,rename);
		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;

		%let keep_2=SIREN NIC IDENT_S S_BRUT REGT &keep;
		%let where_2= AND S_BRUT>0 &where_p;
		%let rename_2=&rename_p; 

		data b&year; 
			set 
			po&year..post_1 (&rename_2 KEEP=&keep_2 WHERE=(REGT NOT IN ("") &where_2))
			po&year..post_2 (&rename_2 KEEP=&keep_2 WHERE=(REGT NOT IN ("") &where_2))
			po&year..post_3 (&rename_2 KEEP=&keep_2 WHERE=(REGT NOT IN ("") &where_2))
			po&year..post_4 (&rename_2 KEEP=&keep_2 WHERE=(REGT NOT IN ("") &where_2))
			;
			year=&year;
				%common;		 
			
		RUN;

		
	%MEND;

	%MACRO m_20(year,keep,where,rename);
		%if &where NE %then %let where_p=AND &where;
		%else %let where_p=;
		%if &rename NE %then %let rename_p=RENAME=(&rename);
		%else %let rename_p=;
		%let keep_2=SIREN NIC IDENT_S S_BRUT REGT &keep;
		%let where_2= AND S_BRUT>0 &where_p;
		%let rename_2=&rename_p; 

		data b&year; 
			set 
			po&year..post (&rename_2 KEEP=&keep_2 WHERE=(REGT NOT IN ("") &where_2))
			;
			year=&year;
				%common;		 
			
		RUN;

		
	%MEND;

	%MACRO common;
		if siren NOT in ("","0","000000000","00000000");
		if missing(IDENT_S)=0;
		%if &year<2002 %then %do;
				SIREN=compress(substr(SIREN,2,9));
				NIC=Compress(SUBSTR(NIC,2,6));
		%end;
	%MEND;

	%MACRO ident_all(b,seniority,foreign_born,citizen,stata);
		%if &b=b1994_1 %then %let year=1993.1;
		%else %if &b=b2002_1 %then %let year=2001.1;
		%else %if &b=b2009_1 %then %let year=2008.1;
		%else %let year=%substr(&b,2,4);

		%let year2=%substr(&year,3,2);
		

		* HOW TO GET FULL PANEL ID;
		%if &seniority=YES %then %do; 
			PROC sql; 
				create table dads_out.dads&year as select * from &b aa
					left join psid_sen.psid_sen_&year  as bb
					on aa.ident_s=bb.ident_s and aa.SIREN=bb.SIREN and aa.NIC=bb.NIC;
			quit;	
			PROC datasets LIBRARY=WORK; 
					DELETE &b ;
			RUN;

		%end;	
		%else %do;
			PROC sql; 
				create table &b.1  
				as select * from &b
				as aa
				left join psid.psid_&year (keep=ident_s ident_all)
				as bb
				on aa.ident_s=bb.ident_s;
			quit;

			data dads_out.dads&year; set &b.1;
					if Missing(ident_all) then do; 
						ident_all=ident_s*100+&year2;
					end;
					ident_all=compress(""!!ident_all!!"");
					drop IDENT_S;
			RUN;
			PROC datasets LIBRARY=WORK; 
					DELETE &b &b.1 ;
			RUN;
			%end;
			%if &foreign_born=YES %then %do; 
				PROC SQL; 
					CREATE TABLE dads_out.dads&year._2 (drop=minyear maxyear) AS SELECT * FROM dads_out.dads&year AS aa
					LEFT JOIN psid_fbo.psid_all_foreign_born 
								(keep=ident_all fborn_def domtom_def minyear maxyear 
								where=(minyear<=&&year and maxyear>=&year)) AS bb
					ON aa.IDENT_ALL=bb.IDENT_ALL; 
				QUIT;
				PROC DATASETS LIBRARY=dads_out; 
					DELETE dads&year ;
				RUN;
				DATA dads_out.dads&year; 
					SET dads_out.dads&year._2 ; 
					if domtom_def=. then domtom_def=0; 
					if fborn_def=. then fborn_def=0; 
				RUN;
				PROC DATASETS LIBRARY=dads_out; 
					DELETE dads&year._2;
				RUN;
			%end;
			%if &citizen=YES %then %do; 
				%if &year>2015 %then %let where_2=(minyear>2014);
				%else %let where_2=(minyear<=&year and maxyear>=&year);

				PROC SQL;
					CREATE TABLE dads_out.dads&year._2 (drop=minyear maxyear) AS SELECT * FROM dads&year AS aa
					LEFT JOIN psid_fbo.psid_all_citizen 
								(keep=ident_all gets_french_nat minyear EU_nat_origin foreign_nat_origin minyear maxyear 
								where=&where_2) AS bb
					ON aa.IDENT_ALL=bb.IDENT_ALL; 
				QUIT;
				PROC DATASETS LIBRARY=dads_out; 
					DELETE dads&year ;
				RUN;
				DATA dads_out.dads&year; 
					SET dads_out.dads&year._2 ; 
					foreign_def=(foreign_nat_origin=1 and (gets_french_nat=. or &year<gets_french_nat));
					year_entry=(ident_all-100*int(ident_all/100))+
							((ident_all-100*int(ident_all/100))>90)*1900+
							((ident_all-100*int(ident_all/100))<90)*2000;							
					if year_entry>2015 then foreign_def=9;
					if foreign_nat_origin=. then foreign_nat_origin=0; 
					if EU_nat_origin=. then EU_nat_origin=0; 
					DROP year_entry;
				RUN;
				PROC DATASETS LIBRARY=dads_out; 
					DELETE dads&year._2 ;
				RUN;
			%end;
			%if &stata=YES %then %do;
				PROC export data=dads_out.dads&year outfile="C:\Users\Public\Documents\Layoffs\pw_branch\data\external\godechot_dads\dads_out\dads&year..dta" replace;  RUN;
				PROC DATASETS LIBRARY=dads_out; 
					DELETE dads&year ;
				RUN;
			%end;
	%MEND;

	%MACRO psid_use(year,keep,where,rename,seniority,foreign_born,citizen,stata);

		%if &year<2002 %then %m_9401(year=&year,keep=&keep,where=&where,rename=&rename);
		%else %if &year<2009 %then %m_0208(year=&year,keep=&keep,where=&where,rename=&rename);
		%else %if &year=2009 %then %m_09(year=&year,keep=&keep,where=&where,rename=&rename);
		%else %if &year=2010 %then %m_10(year=&year,keep=&keep,where=&where,rename=&rename);
		%else %if &year=2011 %then %m_11(year=&year,keep=&keep,where=&where,rename=&rename);
		%else %if &year<2014 %then %m_1213(year=&year,keep=&keep,where=&where,rename=&rename);
		%else %if &year<2018 %then %m_1417(year=&year,keep=&keep,where=&where,rename=&rename);
		%else %if &year<2020 %then %m_1819(year=&year,keep=&keep,where=&where,rename=&rename);
		%else %if &year=2020 %then %m_20(year=&year,keep=&keep,where=&where,rename=&rename);

		%ident_all(b&year,
					seniority=&seniority,
					foreign_born=&foreign_born,
					citizen=&citizen,
					stata=&stata);
	%MEND;


******************************************************************************;
* 2. RUN THE MACROS WITH YOUR OWN PARAMETERS;
******************************************************************************;

	******************************************************************************;
	* 2.a. Libnames;
	******************************************************************************;
	%my_libnames(casd_project=%sysget(CASD_PROJECT));

	******************************************************************************;
	* 2.b. Output;
	******************************************************************************;

	* On fait tourner à partir de 2000. On ne garde que NBHEUR en variable supplémentaire. 

	*%psid_use(1994, keep=NBHEUR DUREE AGE SEXE APET CS2 CS4, rename=CS2=CS CS4=PCS, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	*%psid_use(1995, keep=NBHEUR DUREE AGE SEXE APET CS2 CS4, rename=CS2=CS CS4=PCS, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	*%psid_use(1996, keep=NBHEUR DUREE AGE SEXE APET CS2 CS4, rename=CS2=CS CS4=PCS, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	*%psid_use(1997, keep=NBHEUR DUREE AGE SEXE APET CS2 PCS, rename=CS2=CS, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	*%psid_use(1998, keep=NBHEUR DUREE AGE SEXE APET CS2 PCS, rename=CS2=CS, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	*%psid_use(1999, keep=NBHEUR DUREE AGE SEXE APET CS2 PCS, rename=CS2=CS, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2000, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2001, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2002, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2003, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2004, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2005, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2006, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2007, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2008, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2009, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2010, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2011, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2012, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2013, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2014, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2015, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2016, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2017, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2018, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2019, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);
	%psid_use(2020, keep=NBHEUR, rename=, where=, seniority=NO, foreign_born=NO, citizen=NO,stata=YES);

******************************************************************************;
* GOOD LUCK IN THE COMPLETION OF YOUR MANUSCRIPT ;
******************************************************************************;
