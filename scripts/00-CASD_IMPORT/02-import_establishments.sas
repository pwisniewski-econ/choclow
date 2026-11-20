/* Establishment counts, hours and FTEs. SYSPARM: first_year last_year mode. */
%include "scripts/00-CASD_IMPORT/_dads_partitions.sas";
libname templib "data/_tmp/sas_etablissements";
%let first_year=%scan(&sysparm.,1);
%let last_year=%scan(&sysparm.,2);
%let mode=%scan(&sysparm.,3);

%macro collapse_partition(reg, full_year, paris=0);
    %local varinterest groupvars sortvars member temp_name where_clause;
    %if &full_year.<=2001 %then %do;
        %let groupvars=DEP, COM, SIREN, NIC;
        %let sortvars=dep com siren nic;
        %if &mode.=exh %then
            %let varinterest=SIREN, NIC, REG, DEP, COM, FILT, APET, CATJUR, NBRSA31D, EQTC, NBHEUR;
        %else
            %let varinterest=SIREN, NIC, REG, DEP, COM, FILT, APET, CATJUR, NBRSA31D, EQTC, FINREMU;
        %let where_clause=FILT="1" & REG="&reg.";
        /* EXH 2000-2001 really has this date restriction in the originals. */
        %if &mode.=nov or &full_year.>=2000 %then
            %let where_clause=&where_clause. & FINREMU>=330;
    %end;
    %else %do;
        %let groupvars=DEPT, COMT, SIREN, NIC;
        %let sortvars=dept comt siren nic;
        %if &full_year.=2010 %then
            %let varinterest=SIREN, NIC, REGT, DEPT, COMT, FILT, APET, CATJUR, EFF_3112_ET, NBHEUR, ETP, DATFIN;
        %else %if &mode.=exh %then
            %let varinterest=SIREN, NIC, REGT, DEPT, COMT, FILT, APET, CATJUR, EFF_3112_ET, ETP, NBHEUR;
        %else
            %let varinterest=SIREN, NIC, REGT, DEPT, COMT, FILT, APET, CATJUR, EFF_3112_ET, ETP, DATFIN;

        %if &paris.=1 %then
            %let where_clause=FILT="1" & REGT="11" & DEPT="&reg.";
        %else %if &full_year.<=2008 %then
            %let where_clause=FILT="1" & REGT="&reg.";
        %else
            %let where_clause=FILT="1" & REGT=substr("&reg.",1,2);
        /* EXH 2012-2015: date filter only outside Paris, as supplied. */
        %if &mode.=nov or (&full_year.>=2012 and &paris.=0) %then
            %let where_clause=&where_clause. & DATFIN>=330;
    %end;

    %let member=post&reg.;
    %if &full_year.<=2008 %then %let member=post&reg.&yy.;
    %let temp_name=temp_collap_&reg.&year.;
    %if &paris.=1 %then %do;
        libname dads "&paris_dir.";
        %let temp_name=temp_collap75_&reg.&year.;
    %end;
    %else %do;
        libname dads "&source_dir.";
    %end;

    proc sql;
        create table templib.&temp_name. as
        select &varinterest.,
            sum(filt="1") as total,
            %if &mode.=exh %then %do;
                sum(nbheur) as total_h,
            %end;
            %else %do;
                sum(filt="1" & nbheur>0) as total_pos,
            %end;
            %if &full_year.<=2001 %then %do;
                sum(eqtc) as total_eqtc
            %end;
            %else %do;
                sum(etp) as total_eqtc
            %end;
        from dads.&member.
        where &where_clause.
        group by &groupvars.;
    quit;
    proc sort data=templib.&temp_name. nodupkey;
        by &sortvars.;
    run;
%mend;

%macro append_partitions(partitions, prefix, varlist);
    %local i reg;
    %do i=1 %to %sysfunc(countw(&partitions.));
        %let reg=%scan(&partitions.,&i.);
        proc append base=templib.temp_append&year.
            data=templib.&prefix.&reg.&year. (keep=&varlist.);
        run;
        proc delete data=templib.&prefix.&reg.&year.; run;
    %end;
%mend;

%macro import_establishments;
    %local full_year i reg varlist;
    %do full_year=&first_year. %to &last_year.;
        %dads_partitions(&full_year.);
        %if &full_year.<=2001 %then
            %let varlist=reg dep com siren nic apet catjur nbrsa31d total;
        %else
            %let varlist=regt dept comt siren nic apet catjur eff_3112_et total;
        %if &mode.=exh %then %let varlist=&varlist. total_h total_eqtc;
        %else %let varlist=&varlist. total_pos total_eqtc;

        %do i=1 %to %sysfunc(countw(&regions.));
            %let reg=%scan(&regions.,&i.);
            %collapse_partition(&reg.,&full_year.);
        %end;
        %if &full_year.>=2012 %then %do;
            %do i=1 %to %sysfunc(countw(&paris_regions.));
                %let reg=%scan(&paris_regions.,&i.);
                %collapse_partition(&reg.,&full_year.,paris=1);
            %end;
        %end;
        %append_partitions(&regions.,temp_collap_,&varlist.);
        %if &full_year.>=2012 %then
            %append_partitions(&paris_regions.,temp_collap75_,&varlist.);

        proc export data=templib.temp_append&year.
            outfile="data/external/sas_etablissements/DADS&full_year._&mode..dta" replace;
        run;
        proc delete data=templib.temp_append&year.; run;
    %end;
%mend;
%import_establishments;
