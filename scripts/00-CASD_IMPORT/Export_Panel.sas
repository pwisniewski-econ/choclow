%let casd_project=%sysget(CASD_PROJECT);

libname dadsfh "\\casd.fr\casdfs\Projets\&casd_project.\Data\DADS_Panel tous salariés_2019";

%MACRO getlist(libraryname);
	PROC CONTENTS data = &libraryname.._all_ noprint out = &libraryname.cont (keep = memname ); RUN;
	PROC SORT data = &libraryname.cont nodupkey; by memname; RUN;
%MEND;
	
%MACRO exp_all(libraryname,vlist);
	DATA _null_; 
		set &libraryname.cont end = last; 
		by memname; 
		i+1; 
		call symputx('name'||trim(left(put(i,8.))), memname);
		if last then call symputx('count',i);
	RUN; 

	%DO i = 1 %TO &COUNT;
		PROC EXPORT data = &libraryname..&&name&i 
			(keep = &vlist )
			OUTFILE = "data/external/sas_paneldads/&&name&i...dta"
			replace
			dbms = stata; 
		RUN; 
	%END; 
%MEND;

%getlist(dadsfh);
%exp_all(dadsfh, _all_);

