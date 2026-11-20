%LET project_name = %sysget(CASD_PROJECT);
%LET year = 15;

%macro import_acco(start, end); 

	%DO year = &start %TO &end;

		LIBNAME sas_acco "//casd.fr/casdfs/Projets/&project_name./Data/Accords d'entreprise_D@ccord_2005-20&year./";

		DATA work.acco; 
			SET sas_acco.casd_05_&year.consol;
		run;

		PROC EXPORT DATA = work.acco
			OUTFILE = "./data/interim/acco_ent/2005_20&year..dta"
			DBMS = STATA
			REPLACE;
		RUN;	
	%END;

%mend import_acco;

%import_acco(15,15)
