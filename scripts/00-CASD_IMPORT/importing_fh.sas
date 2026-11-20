%let casd_project=%sysget(CASD_PROJECT);
libname aa "\\casd.fr\casdfs\Projets\&casd_project.\Data\FH-DADS_FH-DADS_2012";

proc export data = aa.dads_inf2002 (where=(AN>1995 & AN<2002))
	OUTFILE = "data/external/fhdads/fhdads_19962001.dta"
	replace
	dbms = stata;
run;

%macro loop_years; 
	%do year = 2002 %to 2012; 
		proc export data = aa.dads_sup2002 (where=(AN=&year))
			OUTFILE = "data/external/fhdads/fhdads_&year"
			replace
			dbms = stata;
		run;
	%end;
%mend;

%loop_years
