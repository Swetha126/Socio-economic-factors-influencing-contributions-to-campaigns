/* Adapted from Graph.sas (upstream).
   Original reads raw FEC bulk contribution files via INFILE from a local
   folder ('/home/u63769577/New/*.txt') and two Census/ACS CSV exports via
   PROC IMPORT ('Educational attainment.csv', 'Urban popultaion percentage.csv').
   Those external files, and the original individual-level FEC layout, are
   replaced below with small fabricated DATALINES blocks matching the same
   column shapes so the script's own PROC SQL / PROC TRANSPOSE / PROC SGPLOT
   logic runs unmodified. All contributor names below are invented for this
   test bundle and do not correspond to any real donor or real FEC filing. */

/* Fabricated stand-in for the raw FEC individual-contribution extract that
   Graph.sas originally read via INFILE from '/home/u63769577/New/*.txt'.
   Column layout (ID/RecordType/.../ContributorName/.../Amount/...) mirrors
   the FEC bulk individual-contributions format the original script parsed. */
data work.imported_data;
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
    datalines;
SA01 SA 1A F3 C001 . IND Jordan_Ally Springfield CA 90001 SampleCo Analyst 03/14/2022 250 . T001 F001 . . S001
SA02 SA 1A F3 C002 . IND Morgan_Blake Riverton TX 73301 SampleCo Analyst 04/02/2022 500 . T002 F001 . . S002
SA03 SA 1A F3 C003 . IND Casey_River Lakeview NY 10001 SampleInc Engineer 05/19/2022 100 . T003 F001 . . S003
SA04 SA 1A F3 C004 . IND Drew_Hale Fairview OH 44101 SampleInc Engineer 02/11/2022 750 . T004 F001 . . S004
SA05 SA 1A F3 C005 . IND Avery_Kent Hillcrest FL 32003 SampleLLC Manager 06/07/2022 300 . T005 F001 . . S005
SA06 SA 1A F3 C006 . IND Reese_Vance Brookside WA 98001 SampleLLC Manager 07/23/2022 400 . T006 F001 . . S006
SA07 SA 1A F3 C007 . IND Skyler_Ford Elmwood CO 80001 SampleCo Analyst 01/29/2022 150 . T007 F001 . . S007
SA08 SA 1A F3 C008 . IND Quinn_Marsh Oakdale IL 60001 SampleInc Engineer 08/15/2022 600 . T008 F001 . . S008
;
run;

/* Creating a table containing the statewise total contributions */
proc sql;
    create table total_contributions_by_state as
    select State, sum(Amount) as total_contribution
    from imported_data
    group by State;
quit;

/* Create a mapping dataset with state abbreviations and full names
   (trimmed to the states present in the fabricated sample above). */
DATA state_mapping;
   INPUT contributor_state $ State $2.;
   DATALINES;
   California CA
   Texas TX
   New_York NY
   Ohio OH
   Florida FL
   Washington WA
   Colorado CO
   Illinois IL
   ;
RUN;

/* Changing the abbreviations of states into its full name */
proc sql;
    create table total_contributions as
    select a.total_contribution, b.contributor_state
    from total_contributions_by_state as a
    inner join state_mapping as b
    on a.State = b.State;
quit;

/* Fabricated stand-in for 'Educational attainment.csv' (originally read via
   PROC IMPORT). Same wide shape: a Label row plus one column per state. */
data work.edu_data;
    length Label $40;
    input Label $ California Texas New_York Ohio Florida Washington Colorado Illinois;
    datalines;
Percentage_of_educated_population 35.1 29.4 37.2 28.6 31.0 36.8 41.5 34.0
;
run;

/* Table for educational attainment data */
proc sql;
    create table edu_data1 as
    select Label, California, Texas, New_York, Ohio, Florida, Washington, Colorado, Illinois
    from work.edu_data
    where Label = 'Percentage_of_educated_population';
quit;

/* Transpose the table */
proc transpose data=edu_data1 out=education_data name=contributor_state;
    var California Texas New_York Ohio Florida Washington Colorado Illinois;
    id Label;
run;

/* Converting column into integer data type */
DATA updated_data;
   SET education_data;
   educated_percentage = INPUT(Percentage_of_educated_populatio, best32.);
   drop Percentage_of_educated_populatio;
RUN;

/* Fabricated stand-in for 'Urban popultaion percentage.csv' (originally read
   via PROC IMPORT). Same wide shape as the educational attainment extract. */
data work.urb_data;
    length Label $40;
    input Label $ California Texas New_York Ohio Florida Washington Colorado Illinois;
    datalines;
Percentage_of_urban_population 94.2 84.7 87.9 77.9 91.2 84.1 86.2 88.5
;
run;

/* Table for urban population data */
proc sql;
    create table urb_data1 as
    select Label, California, Texas, New_York, Ohio, Florida, Washington, Colorado, Illinois
    from work.urb_data
    where Label = 'Percentage_of_urban_population';
quit;

/* Transpose the table */
proc transpose data=urb_data1 out=urban_data name=contributor_state;
    var California Texas New_York Ohio Florida Washington Colorado Illinois;
    id Label;
run;

/* Converting column into integer data type */
DATA updated_data1;
   SET urban_data;
   urban_percentage = INPUT(Percentage_of_urban_population, best32.);
   drop Percentage_of_urban_population;
RUN;

/* Merging the data sets based on a common column */
proc sql;
   create table merged_data as
   select *
   from work.updated_data as t1
   inner join work.updated_data1 as t2
   on t1.contributor_state = t2.contributor_state
   inner join work.total_contributions as t3
   on t1.contributor_state = t3.contributor_state;
quit;

/* Graph plotting */
ods graphics / reset=all height=5in width=10in;
proc sgplot data=merged_data;
  vbar contributor_state / response=total_contribution stat=mean nostatlabel barwidth=0.5;
  vline contributor_state / response=educated_percentage stat=mean markerattrs=(symbol=TriangleFilled color=red) nostatlabel y2axis;
  vline contributor_state / response=urban_percentage stat=mean markerattrs=(symbol=TriangleFilled color=blue) nostatlabel y2axis;
  xaxis display=(nolabel);
  yaxis grid offsetmin=0;
  run;
ods graphics / reset;
