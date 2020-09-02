/**************************************************
Author : Pushkar Gadgil
Date Created : September 02, 2020 
Time : 11:14 AM IST
SAS Studio
 **************************************************/


/**************************************************
Setting up a Library Path
 **************************************************/
%let path=/home/data;
libname tsa"&path";
options validvarname=v7;

/*Importing the Data File*/
proc import datafile="&path/TSAClaims2002_2017.csv" dbms=csv 
		out=tsa.ClaimsImport replace;
	guessingrows=max;
run;

/**************************************************
Exploring Data
 **************************************************/
proc print data=tsa.ClaimsImport(obs=10);
run;

proc contents data=tsa.ClaimsImport varnum;
run;

proc freq data=tsa.ClaimsImport;
	tables claim_site disposition claim_type incident_date / nocum nopercent;
	format incident_date date_received year4.;
run;

proc print data=tsa.ClaimsImport;
	where date_received < incident_date;
	format date_received incident_date date9.;
run;

/**************************************************
Preparing Data
 **************************************************/
/*Remove Duplicates*/
proc sort data=tsa.ClaimsImport out=tsa.Claims_NoDups noduprecs;
	by _all_;
run;

/*Ascending ordered Incident_Date*/
proc sort data=tsa.Claims_NoDups;
	by Incident_Date;
run;

/*Clean Claim_Site column*/
data tsa.claims_cleaned;
	set tsa.claims_nodups;

	if Claim_Site in ('-', '') then
		Claim_Site="Unknown";

	/*Clean Disposition column*/
	if Disposition in ('-', '') then
		Disposition="Unknown";
	else if Dispostion='losed: Contractor Claim' then
		Dispostion='Closed:Contractor Claim';
	else if Dispostion='Closed: Canceled' then
		Dispostion='Closed:Canceled';

	/*Clean Claim_Type column*/
	if Claim_Type in ('-', '') then
		Claim_Type="Unknown";
	else if Claim_Type='Passenger Property Loss/Personal Injur' then
		Claim_Type='Passenger Property Loss';
	else if Claim_Type='Passenger Property Loss/Personal Injury' then
		Claim_Type='Passenger Property Loss';
	else if Claim_Type='Property Damage/Personal Injur' then
		Claim_Type='Property Damage';

	/*State Values to Upper Case and State Names to Proper Case*/
	State=upcase(state);
	StateName=propcase(StateName);

	/*Date Issues Column*/
	if(Incident_Date > Date_Received or Date_Received=. or Incident_Date=. or 
		year(Incident_Date)<2002 or year(Incident_Date)>2017 or 
		year(Date_Received)<2002 or year(Date_Received)>2017) then
			Date_Issues="Needs Review";

	/*Making a few changes to the format and creating permanent labels*/
	format Incident_Date Date_Received date9. Close_Amount dollar20.2;
	label Airport_Code="Airport Code" Airport_Name="Airport Name" 
		Claim_Number="Claim Number" Claim_Site="Claim Site" Claim_Type="Claim Type" 
		Close_Amount="Close Amount" Date_Issues="Date Issues" 
		Date_Received="Date Received" Incident_Date="Incident Date" 
		Item_Category="Item Category";

	/*Drop counnty and city*/
	drop county city;
run;

proc freq data=tsa.Claims_Cleaned order=freq;
	tables Claim_Site Disposition Claim_Type Date_Issues / nopercent nocum;
run;

/**************************************************
Analyzing Data
 **************************************************/
/*Dynamically Changing the State Name*/
%let StateName=Hawaii;

/*Exporting the Output File*/
%let outpath=/home/output;
ods pdf file="&outpath/TSAClaimsReport.pdf" style=Plateau pdftoc=1;
ods noproctitle;

/*Date Issues in the Data*/
ods proclabel "Overall Date Issues";
title "Overall Date Issues in the Data";

proc freq data=tsa.Claims_Cleaned;
	table Date_Issues / missing nocum nopercent;
run;

title;

/*Claims per year for Incident Date*/
ods graphics on;
ods proclabel "Overall Claims by Year";
title "Overall Claims by Year";

proc freq data=tsa.Claims_Cleaned;
	table Incident_Date / nocum nopercent plots=freqplot;
	format Incident_Date year4.;
	where Date_Issues is null;
run;

title;

/*Specific State Anlaysis*/
ods proclabel "&StateName Claims Overview";
title "&StateName Claim Types, Claim Sites and Disposition";

proc freq data=tsa.Claims_Cleaned order=freq;
	table Claim_Type Claim_Site Disposition / nocum nopercent;
	where StateName="&StateName" and Date_Issues is null;
run;

title;

/*Mean, Min, Max and Sum of Close Amount fro California State*/
ods proclabel "&StateName Close Amount Statistics";
title "Close Amount Statistics for &StateName";

proc means data=tsa.Claims_Cleaned mean min max sum maxdec=0;
	var Close_Amount;
	where StateName="&StateName" and Date_Issues is null;
run;

title;
ods pdf close;
