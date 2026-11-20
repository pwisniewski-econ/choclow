%let casd_project=%sysget(CASD_PROJECT);

%let varinterest = IDFHDA, an, SIR, NIC4, filtre, DEPR, COMR, sbr, DEBREMU, FINREMU, SX, annai, DIP_TOT, PCS4, cs2, nbsa_et, apet, apet2, nbheur, comt, dept;
%let varlist = idfhda, an, sir, nic4, filtre, depr, comr, sbr, debremu, finremu, sx, annai, dip_tot, pcs4, cs2, nbsa_et, apet, apet2, nbheur, comt, dept;
%let year1 = dads_inf2002;
%let year2 = dads_sup2002;

%macro select_DADS1(varlist);	
	libname templib "data/_tmp";
	libname fhdads "\\casd.fr\casdfs\Projets\&casd_project.\Data\FH-DADS_FH-DADS_2012";
	proc sql;
	create table templib.fh&year1. as
	select &varinterest
	from fhdads.&year1.
	;quit; run;
%mend;
%select_DADS1;
/* where filtre="1"; */

%macro select_DADS2(varlist);	
	libname templib "data/_tmp";
	libname fhdads "\\casd.fr\casdfs\Projets\&casd_project.\Data\FH-DADS_FH-DADS_2012";
	proc sql;
	create table templib.fh&year2. as
	select &varinterest
	from fhdads.&year2.
	;quit; run;
%mend;
%select_DADS2;
/* where filtre="1"; */

*Export append into dta;
%macro export1;
proc export data= templib.fh&year1.
	outfile = "data/external/sas_fhdads/extra_fh&year1..dta"
	replace
;run;

proc delete data= templib.fh&year1.
;run;
%mend;
%export1;


%macro export2;
proc export data= templib.fh&year2.
	outfile = "data/external/sas_fhdads/extra_fh&year2..dta"
	replace
;run;

proc delete data= templib.fh&year2.
;run;
%mend;
%export2;
