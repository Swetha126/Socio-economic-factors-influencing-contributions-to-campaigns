/* Assign a libname to the folder containing the text files */
libname mydata '/home/u63769577/New';

/* Import the dataset */
data work.imported_data;
    infile '/home/u63769577/New/*.txt' dlm='|' missover dsd lrecl=32767;
    length
        ID $10
        RecordType $1
        FilingType $2
        FormType $1
        FECID $20
        AmendmentIndicator $2
        EntityType $3
        ContributorName $50
        City $20
        State $2
        Zip $10
        Employer $50
        Occupation $50
        Date $8
        Amount 8
        OtherID $20
        TranID $20
        FileNum $8
        MemoCode $1
        MemoText $50
        SubID $20;
    format Date mmddyy10.;
    input
        ID $
        RecordType $
        FilingType $
        FormType $
        FECID $
        AmendmentIndicator $
        EntityType $
        ContributorName $
        City $
        State $
        Zip $
        Employer $
        Occupation $
        Date mmddyy10.
        Amount 
        OtherID $
        TranID $
        FileNum $
        MemoCode $
        MemoText $
        SubID $;
run;

/*Creating a table containing the statewise total contributions*/
proc sql;
    create table total_contributions_by_state as
    select State, sum(Amount) as total_contribution
    from imported_data
    group by State;
quit;

/* Create a mapping dataset with state abbreviations and full names */
DATA state_mapping;
   INPUT contributor_state $ State $2.;
   DATALINES;
   Alabama AL	
   Kentucky KY
   Ohio OH
   Alaska AK	
   Louisiana LA
   Oklahoma OK
   Arizona AZ	
   Maine ME	
   Oregon OR
   Arkansas AR
   Maryland MD	
   Pennsylvania PA
   American_Samoa AS	
   Massachusetts MA
   Puerto_Rico PR
   California CA
   Michigan MI	
   Rhode_Island RI
   Colorado CO	
   Minnesota MN	
   South_Carolina SC
   Connecticut CT
   Mississippi MS
   South_Dakota SD
   Delaware DE
   Missouri MO
   Tennessee TN
   District_of_Columbia DC
   Montana MT
   Texas TX
   Florida FL
   Nebraska NE
   Trust_Territories TT
   Georgia GA
   Nevada NV
   Utah UT
   Guam GU
   New_Hampshire NH
   Vermont VT
   Hawaii HI
   New_Jersey NJ
   Virginia VA
   Idaho ID
   New_Mexico NM
   Virgin_Islands VI
   Illinois IL
   New_York NY
   Washington WA
   Indiana IN
   North_Carolina NC
   West_Virginia WV
   Iowa IA
   North_Dakota ND
   Wisconsin WI
   Kansas KS
   Northern_Mariana_Islands MP
   Wyoming WY
   ;
RUN;

/* Changing the abbreviations of states into its full name*/

proc sql;
    create table total_contributions as
    select a.total_contribution, b.contributor_state
    from total_contributions_by_state as a
    inner join state_mapping as b
    on a.State = b.State;
quit;

proc import datafile="/home/u63769577/Educational attainment.csv"
    out=edu_data
    dbms=csv
    replace;
run;

/* Table for educational attainment data*/
proc sql;
    create table edu_data1 as
    select Label, Alabama, Alaska, Arizona, Arkansas, Californ, Colorado, Connecti, Delaware, District, Florida, Georgia, Hawaii, Idaho, Illinois, Indiana, Iowa, Kansas, Kentucky, Louisian, Maine, Maryland, Massachu, Michigan, Minnesot, Mississi, Missouri, Montana, Nebraska, Nevada, New_Hamp, New_Jers, New_Mexi, New_York, North_Ca, North_Da, Ohio, Oklahoma, Oregon, Pennsylv, Rhode_Island, South_Carolina, South_Da, Tennessee, Texas, Utah, Vermont, Virginia, Washingt, West_Vir, Wisconsi, Wyoming, Puerto_Rico
    from work.edu_data
    where Label = 'Percentage_of_educated_population';
quit;
/* Transpose the table*/
proc transpose data=edu_data1 out=education_data name=contributor_state;
    var Alabama Alaska Arizona Arkansas Californ Colorado Connecti Delaware District Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisian Maine Maryland Massachu Michigan Minnesot Mississi Missouri Montana Nebraska Nevada New_Hamp New_Jers New_Mexi New_York North_Ca North_Da Ohio Oklahoma Oregon Pennsylv Rhode_Island South_Carolina South_Da Tennessee Texas Utah Vermont Virginia Washingt West_Vir Wisconsi Wyoming Puerto_Rico; /* Replace with the actual full column names */
    id Label;
run;
/* Converting column into integer data type*/
DATA updated_data;
   SET education_data;
   educated_percentage = INPUT(Percentage_of_educated_populatio, best32.);
   drop Percentage_of_educated_populatio;
RUN;


proc import datafile="/home/u63769577/Urban popultaion percentage.csv"
    out=urb_data
    dbms=csv
    replace;
run;
/* Table for urban population data*/
proc sql;
    create table urb_data1 as
    select Label, Alabama, Alaska, Arizona, Arkansas, Californ, Colorado, Connecti, Delaware, District, Florida, Georgia, Hawaii, Idaho, Illinois, Indiana, Iowa, Kansas, Kentucky, Louisian, Maine, Maryland, Massachu, Michigan, Minnesot, Mississi, Missouri, Montana, Nebraska, Nevada, New_Hamp, New_Jers, New_Mexi, New_York, North_Ca, North_Da, Ohio, Oklahoma, Oregon, Pennsylv, Rhode_Island, South_Carolina, South_Da, Tennessee, Texas, Utah, Vermont, Virginia, Washingt, West_Vir, Wisconsi, Wyoming, Puerto_Rico
    from work.urb_data
    where Label = 'Percentage_of_urban_population';
quit;
/* Transpose the table*/
proc transpose data=urb_data1 out=urban_data name=contributor_state;
    var Alabama Alaska Arizona Arkansas Californ Colorado Connecti Delaware District Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisian Maine Maryland Massachu Michigan Minnesot Mississi Missouri Montana Nebraska Nevada New_Hamp New_Jers New_Mexi New_York North_Ca North_Da Ohio Oklahoma Oregon Pennsylv Rhode_Island South_Carolina South_Da Tennessee Texas Utah Vermont Virginia Washingt West_Vir Wisconsi Wyoming Puerto_Rico; /* Replace with the actual full column names */
    id Label;
run;
/* Converting column into integer data type*/
DATA updated_data1;
   SET urban_data;
   urban_percentage = INPUT(Percentage_of_urban_population, best32.);
   drop Percentage_of_urban_population;
RUN;


/*Merging the data sets based on a common column*/
proc sql;
   create table merged_data as
   select *
   from work.updated_data as t1
   inner join work.updated_data1 as t2
   on t1.contributor_state = t2.contributor_state
   inner join work.total_contributions as t3
   on t1.contributor_state = t3.contributor_state;
quit;

/*Graph plotting*/
ods graphics / reset=all height=5in width=10in;
proc sgplot data=merged_data;
  vbar contributor_state / response=total_contribution stat=mean nostatlabel barwidth=0.5;
  vline contributor_state / response=educated_percentage stat=mean markerattrs=(symbol=TriangleFilled color=red) nostatlabel y2axis;
  vline contributor_state / response=urban_percentage stat=mean markerattrs=(symbol=TriangleFilled color=blue) nostatlabel y2axis;
  xaxis display=(nolabel);
  yaxis grid offsetmin=0;
  run;
ods graphics / reset;

  