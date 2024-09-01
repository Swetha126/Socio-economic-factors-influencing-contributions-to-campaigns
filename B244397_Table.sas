%macro combine_contributions;

/* Define macro variables for the names of the CSV files */
%let file1 = /home/u63769577/Wyoming/2017_contributions.csv;
%let file2 = /home/u63769577/Wyoming/2018_contributions.csv;
%let file3 = /home/u63769577/Wyoming/2019_contributions.csv;
%let file4 = /home/u63769577/Wyoming/2020_contributions.csv;
%let file5 = /home/u63769577/Wyoming/2021_contributions.csv;
%let file6 = /home/u63769577/Wyoming/2022_contributions.csv;

/* Create an empty master dataset to hold the combined data */
data contributions;
    length contribution_receipt_amount 8 report_year 4;
run;

/* Loop through each file, import, and append to the master dataset */
%do i = 1 %to 6;
    %let current_file = &&file&i;

    /* Import the current CSV file */
    proc import datafile="&&current_file" 
        out=contribution_data_&i
        dbms=csv
        replace;
        getnames=yes;
    run;

    /* Append the imported data to the master dataset, keeping only the desired columns */
    data contributions;
        set contributions contribution_data_&i (keep=contribution_receipt_amount report_year);
    run;
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

proc import datafile="/home/u63769577/Wyoming/Wyoming mean income.csv"
    out=income_data
    dbms=csv
    replace;
run;

/* Create a new dataset with only the 'Total' row */
data total_row_dataset;
   set income_data;
   if Label = 'mean_income'; /* Assuming _NAME_ holds the row categories after the transpose */
run;

proc transpose data=total_row_dataset out=transposed_data1 name=report_year;
    var _all_; /* Replace with the actual full column names */
    id Label;
run;



data without_first_row;
   set transposed_data1;
   if _N_ > 1; /* This condition excludes the first row */
run;

data new_dataset;
    set without_first_row;
    /* Assuming 'Total' is the character column you want to convert */
    year = input(report_year, best32.); /* Use an appropriate informat like best32. */
    drop report_year; /* Drop the original character column if no longer needed */
    rename year = report_year; /* Optional: rename the new numeric column to 'Total' */
run;

proc import datafile="/home/u63769577/Wyoming/Wyoming poverty status.csv"
    out=poverty_data
    dbms=csv
    replace;
run;


data total_row_dataset1;
   set poverty_data;
   if Label = 'Below_poverty_level'; 
run;

proc transpose data=total_row_dataset1 out=transposed_data2 name=report_year;
    var _all_; /* Replace with the actual full column names */
    id Label;
run;
data without_first_row1;
   set transposed_data2;
   if _N_ > 1; /* This condition excludes the first row */
run;

data new_dataset1;
    set without_first_row1;
    /* Assuming 'Total' is the character column you want to convert */
    year = input(report_year, best32.); /* Use an appropriate informat like best32. */
    drop report_year; /* Drop the original character column if no longer needed */
    rename year = report_year; /* Optional: rename the new numeric column to 'Total' */
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


