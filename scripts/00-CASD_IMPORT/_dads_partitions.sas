%let casd_project=%sysget(CASD_PROJECT);
/* Year-specific CASD source partitions. */
%macro dads_partitions(full_year);
    %global year yy regions paris_regions source_dir paris_dir;
    %let year=%sysfunc(mod(&full_year.,100));
    %let yy=%sysfunc(putn(&year.,z2.));
    %let regions=11 21 22 23 24 25 26 31 41 42 43 52 53 54 72 73 74 82 83 91 93 94;
    %let paris_regions=;
    %let source_dir=\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_DADS Postes_&full_year.;
    %let paris_dir=;
    %if &full_year.=2009 %then
        %let regions=11aa 11bb 11cc 11dd 21 22 23 24 25 26 31 41 42 43 52 53 54 72 73 74 82 83 91 93 94;
    %if &full_year.=2010 %then
        %let regions=11aa 11bb 11cc 11dd 21 22 23 24 25 26 31 41 42 43 52 53 54 72 73 74 82a 82b 83 91 93 94;
    %if &full_year.>=2012 %then %do;
        %let regions=21 22 23 24 25 26 31 41 42 43 52 53 54 72 73 74 82 83 91 93 94;
        %let paris_regions=75 77 78 91 92 93 94 95;
        %let paris_dir=&source_dir.\Ile de France;
    %end;
    %if &full_year.>=2014 %then %do;
        %let regions=24 27 28 32 44 52 53 75 76 84 93 94 97 99;
        %let paris_dir=&source_dir.\Départements;
        %let source_dir=&source_dir.\Régions;
    %end;
%mend;
