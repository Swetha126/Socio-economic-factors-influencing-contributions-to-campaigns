/* Adapted from Table.sas (upstream).
   Original defines %combine_contributions, a %do-loop macro that imports
   six yearly CSV extracts ('/home/u63769577/Wyoming/2017_contributions.csv'
   ... '2022_contributions.csv') via PROC IMPORT and appends the
   contribution_receipt_amount / report_year columns into one dataset, then
   joins that against two more CSV imports (mean income, poverty status).
   Those six external files plus the two Census-style CSVs are replaced below
   with fabricated inline DATALINES of the same shape so the macro itself,
   and the PROC SQL / PROC TRANSPOSE / PROC SORT logic that follows, run
   unmodified against sample data. All figures are invented for this test
   bundle. */

%macro combine_contributions;

/* Fabricated stand-ins for the six yearly CSV extracts the original macro
   imported via PROC IMPORT inside its %do i = 1 %to 6 loop. Each mimics one
   year's contribution_receipt_amount / report_year columns. */
%do i = 1 %to 6;
    %let yr = %eval(2016 + &i);

    data contribution_data_&i;
        length report_year 4 contribution_receipt_amount 8;
        report_year = &yr;
        input contribution_receipt_amount @@;
        datalines;
120 340 275 90 610 430 205
;
    run;

    /* Append the imported data to the master dataset, keeping only the
       desired columns */
    %if &i = 1 %then %do;
        data contributions;
            set contribution_data_&i (keep=contribution_receipt_amount report_year);
        run;
    %end;
    %else %do;
        data contributions;
            set contributions contribution_data_&i (keep=contribution_receipt_amount report_year);
        run;
    %end;
%end;

%mend combine_contributions;

/* Execute the macro */
%combine_contributions;

proc sql;
    create table total_contributions_by_year as
    select report_year, sum(contribution_receipt_amount) as total_contribution, count(contribution_receipt_amount) as number_contribution
    from contributions
    group by report_year;
quit;

/* Remove the empty rows */
data total_contributions_by_year;
    set total_contributions_by_year;
    if n(of _ALL_); /* Keeps the row if any variable in the row is non-missing */
run;

/* Fabricated stand-in for 'Wyoming mean income.csv' (originally read via
   PROC IMPORT): a Label row plus one column per report year. */
data income_data;
    length Label $20;
    input Label $ y2017 y2018 y2019 y2020 y2021 y2022;
    datalines;
mean_income 54200 55600 57100 58300 60250 62800
;
run;

/* Create a new dataset with only the 'mean_income' row */
data total_row_dataset;
   set income_data;
   if Label = 'mean_income';
run;

proc transpose data=total_row_dataset out=transposed_data1 name=report_year;
    var _all_;
    id Label;
run;

data without_first_row;
   set transposed_data1;
   if _N_ > 1; /* This condition excludes the first row */
run;

data new_dataset;
    set without_first_row;
    /* report_year comes back from PROC TRANSPOSE as the y2017.. column
       labels; strip the leading "y" and convert to numeric */
    year = input(compress(report_year, , 'kd'), best32.);
    drop report_year;
    rename year = report_year;
run;

/* Fabricated stand-in for 'Wyoming poverty status.csv' (originally read via
   PROC IMPORT), same shape as the income extract above. */
data poverty_data;
    length Label $20;
    input Label $ y2017 y2018 y2019 y2020 y2021 y2022;
    datalines;
Below_poverty_level 11.2 10.9 10.5 11.8 11.1 10.2
;
run;

data total_row_dataset1;
   set poverty_data;
   if Label = 'Below_poverty_level';
run;

proc transpose data=total_row_dataset1 out=transposed_data2 name=report_year;
    var _all_;
    id Label;
run;

data without_first_row1;
   set transposed_data2;
   if _N_ > 1; /* This condition excludes the first row */
run;

data new_dataset1;
    set without_first_row1;
    year = input(compress(report_year, , 'kd'), best32.);
    drop report_year;
    rename year = report_year;
run;

proc sql;
   create table joined_data1 as
   select *
   from work.total_contributions_by_year as t1
   inner join work.new_dataset as t2
   on t1.report_year = t2.report_year
   inner join work.new_dataset1 as t3
   on t1.report_year = t3.report_year;
quit;

proc sort data=joined_data1;
  by number_contribution;
run;

proc print data=joined_data1 noobs;
run;
