%let casd_project=%sysget(CASD_PROJECT);

%let varinterest = SIREN, NIC, DEP, COM, FILT, APET, CATJUR, NBRSA31D, NBHEUR, FINREMU;
%let varlist= dep com siren nic apet catjur nbrsa31d total total_pos total_nbheur;
%let base=sain;
%let liste_regions = %str(21,22,23,24,25,26,31,41,42,43,52,53,54,72,73,74,82,83,91,93,94);
%let year=93;

*This collapse input data by "group", and save temp_collap_reg;
*I keep only filt=1 (nonanex jobs) and reg=reg (i.e. information at work place, not residence);
%macro collapse_DADS(reg, base, year, varlist);
	libname templib "data/_tmp/sas_etablissements";
	libname dads "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_19&year.\r&reg.";
	proc sql;
	create table templib.temp_collap_&reg.&year. as
	select &varinterest,
		sum(filt="1") as total,
		sum(filt="1" & nbheur>0) as total_pos,
		sum(nbheur) as total_nbheur
	from dads.&base.&reg.&year.
	where FILT="1" & FINREMU>=330
	group by DEP, COM, SIREN, NIC
	;quit;
	proc sort data=templib.temp_collap_&reg.&year. nodupkey ; by dep com siren nic ; run;
%mend;

*I loop over the region and run the collapse defined above;
%macro reg;
%do i=1 %to %sysfunc(countw(&liste_regions)) ;
%let reg=%scan(&liste_regions,&i);
%collapse_DADS(&reg, &base, &year, &varlist);
%end ;
%mend;

%reg;

*This appends all temp_collap_reg files in loop over dep, and delete temp;
%macro append_DADS;
%do i=1 %to %sysfunc(countw(&liste_regions)) ;
%let reg=%scan(&liste_regions,&i);
	proc append base= templib.temp_append&year.  data= templib.temp_collap_&reg.&year. (keep = &varlist) ; run;
	proc delete data= templib.temp_collap_&reg.&year.
	;run;
%END;
%mend;
%append_DADS;

*Paris region;
%let liste_paris=%str(1a,1b);
%macro collapse_Paris(base, regk, year, varlist);
	libname templib "data/_tmp/sas_etablissements";
	libname dads "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_19&year.\r&regk.";
	proc sql;
	create table templib.temp_collap75_&regk. as
	select &varinterest,
		sum(filt="1") as total,
		sum(filt="1" & nbheur>0) as total_pos,
		sum(nbheur) as total_nbheur
	from dads.&base.&regk.&year.
	where FILT="1" & FINREMU>=330
	group by DEP, COM, SIREN, NIC
	;quit;
	proc sort data=templib.temp_collap75_&regk. nodupkey ; by dep com siren nic ; run;
%mend;

%macro paris;
%do k=1 %to %sysfunc(countw(&liste_paris)) ;
%let regk=%scan(&liste_paris,&k);
%collapse_Paris(&base, &regk, &year, &varlist);
%end ;
%mend;

%macro append_Paris;
%do i=1 %to %sysfunc(countw(&liste_paris)) ;
%let regk=%scan(&liste_paris,&i);
	proc append base= templib.temp_append&year.  data= templib.temp_collap75_&regk. (keep = &varlist) ; run;
	proc delete data= templib.temp_collap75_&regk.
	;run;
%END;
%mend;


%paris;
%append_Paris;




*Export append into dta;
proc export data= templib.temp_append&year.
	outfile = "data/external/sas_etablissements/DADS19&year._nov.dta"
	replace
;run;

*Delete temp_append;
proc delete data= templib.temp_append&year.
;run;




