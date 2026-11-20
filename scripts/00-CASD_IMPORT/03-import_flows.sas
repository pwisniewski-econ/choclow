/* Worker-flow records. SYSPARM: first_year last_year. */
%include "scripts/00-CASD_IMPORT/_dads_partitions.sas";
libname templib "data/_tmp/sas_flux";
%let first_year=%scan(&sysparm.,1);
%let last_year=%scan(&sysparm.,2);
%let varinterest=SIREN, NIC, IDENT_S, COMT, COMT_1, FILT, FILT_1, NBHEUR, NBHEUR_1, DATDEB, DATDEB_1, DATFIN, DATFIN_1;
%let varlist=siren nic ident_s comt comt_1 filt filt_1 datdeb datdeb_1 datfin datfin_1 nbheur nbheur_1;

%macro select_partition(reg, full_year, paris=0);
    %local member temp_name where_clause sortvars selectvars;
    %let selectvars=&varinterest.;
    %if &full_year.>=2009 %then %let selectvars=&varinterest., DEPT;
    %let member=post&reg.;
    %let temp_name=temp_siren_&reg.&year.;
    %let sortvars=dept comt siren nic ident_s;
    %if &full_year.<=2008 %then %do;
        %let member=post&reg.&yy.;
        %let sortvars=comt siren nic ident_s;
        %let where_clause=(FILT="1" or FILT_1="1") & (REGT="&reg." or REGT_1="&reg.");
    %end;
    %else %if &full_year.<=2010 %then
        %let where_clause=(REGT=substr("&reg.",1,2) or REGT_1=substr("&reg.",1,2)) & (FILT="1" or FILT_1="1");
    %else
        %let where_clause=(FILT="1" or FILT_1="1") & (REGT=substr("&reg.",1,2) or REGT_1=substr("&reg.",1,2));

    %if &paris.=1 %then %do;
        libname dads "&paris_dir.";
        %let temp_name=temp_siren75_&reg.&year.;
        %let where_clause=(FILT="1" or FILT_1="1") & (REGT="11" or REGT_1="11") & (DEPT="&reg." or DEPT_1="&reg.");
        %if &full_year.>=2014 %then %let sortvars=dept comt siren nic;
    %end;
    %else %do;
        libname dads "&source_dir.";
    %end;
    proc sql;
        create table templib.&temp_name. as
        select &selectvars.
        from dads.&member.
        where &where_clause.;
    quit;
    proc sort data=templib.&temp_name. nodupkey;
        by &sortvars.;
    run;
%mend;

%macro append_partitions(partitions, prefix);
    %local i reg;
    %do i=1 %to %sysfunc(countw(&partitions.));
        %let reg=%scan(&partitions.,&i.);
        proc append base=templib.&append_name.
            data=templib.&prefix.&reg.&year. (keep=&varlist.);
        run;
        proc delete data=templib.&prefix.&reg.&year.; run;
    %end;
%mend;

%macro import_flows;
    %local full_year i reg append_name;
    %do full_year=&first_year. %to &last_year.;
        %dads_partitions(&full_year.);
        %let append_name=temp_app_sir&year.;
        %if &full_year.>=2012 %then %let append_name=temp_append&year.;
        %do i=1 %to %sysfunc(countw(&regions.));
            %let reg=%scan(&regions.,&i.);
            %select_partition(&reg.,&full_year.);
        %end;
        %if &full_year.>=2012 %then %do;
            %do i=1 %to %sysfunc(countw(&paris_regions.));
                %let reg=%scan(&paris_regions.,&i.);
                %select_partition(&reg.,&full_year.,paris=1);
            %end;
        %end;
        %append_partitions(&regions.,temp_siren_);
        %if &full_year.>=2012 %then
            %append_partitions(&paris_regions.,temp_siren75_);
        proc export data=templib.&append_name.
            outfile="data/external/sas_flux/DADS&full_year._pic.dta" replace;
        run;
        proc delete data=templib.&append_name.; run;
    %end;
%mend;
%import_flows;
