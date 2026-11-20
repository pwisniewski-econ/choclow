CH: Downloaded on Dec. 13, 2022

*****************************************************************;
* SCRIPTS pseudo_id.zip     2022/10/10 (V1)                     *;
* Olivier Godechot                                              *;
* Email: Olivier.Godechot [at] sciencespo.fr                    *;
*****************************************************************;
* SET OF FILES FOR CREATING PSEUDO IDENTIFIER IN THE DADS FILES *; 
*****************************************************************;

The zip file pseudo_id.zip contains the following SAS scripts : 

  1. pseudo_id.sas 
    It is a program for the CASD platform which creates 
    a common identifier IDENT_ALL in the DADS files thanks to overlapping 
    information between year t-1 of yearfile y and year t of yearfile y-1.
    It enables to chain stayers and movers from 2002 to 2020 
    (provided movers reappear in the DADS perimeter in less than one year). 
     Before 2001, while we cannot chain movers (who change workplace), we can 
     still chain stayers.

  2. pseudo_id_seniority.sas 
      It calculates the year of entry in the firm and the establishment and enables to 
      calculate seniority.

  3. pseudo_id_foreign_born.sas 
      It corrects information on foreign and over-sea borns and citizenship which is obviously incorrect
      for some years.

  4. pseudo_id_use.sas
      If gives an example of creating a dads files with common identifiers and optionally adds information 
      on seniority and corrected location of birth.

Don't hesitate to ask questions or to comment.

Possible updates can be found here : http://olivier.godechot.free.fr/hopfichiers/pseudo_id.zip
