%let casd_project=%sysget(CASD_PROJECT);
/* FH-DADS extracts. SYSPARM: matching | de | extra. */
%let extract=%scan(&sysparm.,1);

%macro select_extract(member, target, restriction=);
    libname templib "data/_tmp";
    libname fhdads "\\casd.fr\casdfs\Projets\&casd_project.\Data\FH-DADS_FH-DADS_2012";
    proc sql;
        create table templib.&target. as
        select &columns.
        from fhdads.&member.
        %if %length(&restriction.) %then %do;
            where &restriction.
        %end;
        ;
    quit; run;
%mend;

%macro export_extract(target, output);
    proc export data=templib.&target.
        outfile="data/external/sas_fhdads/&output..dta" replace;
    run;
    proc delete data=templib.&target.; run;
%mend;

%macro import_extract;
    %local columns;
    %if &extract.=matching %then %do;
        %let columns=IDFHDA, an, SIR, NIC4, entsir, entpan, dept, COMT, NBHEUR, debremu, FINREMU, contrat_travail, ANNAI, sbr, nbsa_ent;
        %select_extract(dads_inf2002,fhdads_inf2002,restriction=filtre="1");
        %select_extract(dads_sup2002,fhdads_sup2002,restriction=filtre="1");
        %export_extract(fhdads_inf2002,fhdads_inf2002);
        %export_extract(fhdads_sup2002,fhdads_sup2002);
    %end;
    %else %if &extract.=de %then %do;
        %let columns=IDFHDA, NDEM, DATINS, DATANN, MOTINS, MOTANN, SITPAR, DIPLOME;
        %select_extract(de,de);
        %export_extract(de,fh_de);
    %end;
    %else %if &extract.=extra %then %do;
        %include "scripts/00-CASD_IMPORT/compatibility/43_ExtractFH_DADS_extra.sas";
    %end;
%mend;
%import_extract;
