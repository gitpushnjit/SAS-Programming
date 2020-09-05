/**************************************************
Author : Pushkar Gadgil
Date Created : September 05, 2020
Time : 09:51 AM IST
SAS Studio
 **************************************************/

/*Removing Years 1995 to 2013 and creating columns Country_Name and Tourism_Type*/
data cleanead_tourism;
	length Country_Name $300 Tourism_Type $20;
	retain Country_Name "" Tourism_Type "";
	set cr.tourism (drop=_1995-_2013);

	if A ne . then
		Country_Name=Country;

	if lowcase(Country)="inbound tourism" then
		Tourism_Type="Inbound tourism";
	else if lowcase(Country)="outbound tourism" then
		Tourism_Type="Outbound tourism";

	if Country_Name ne Country and Country ne Tourism_Type;

/*Converting Series column to uppercase, determine the conversion type and make changes to data not available in _2014*/
	series=upcase(series);

	if series=".." then
		Series="";
	ConversionType=scan(country, -1, " ");

	if _2014=".." then
		_2014=".";

/*Create a Y2014 column by explicitly converting the character values multiplying them by the Conversion Type*/
	if ConversionType='Mn' then
		do;

			if _2014 ne "." then
				Y2014=input(_2014, 16.)*1000000;
			else
				Y2014=.;

/*Create a new column Category to change the required values*/
			Category=cat(scan(country, 1, '-', 'r'), ' -US$');
		end;
	else if ConversionType='Thousands' then
		do;

			if _2014 ne "." then
				Y2014=input(_2014, 16.)*1000;
			else
				Y2014=.;

/*Create a new column Category to change the required values*/
			Category=scan(country, 1, '-', 'r');
		end;

/*Permanently format Y2014*/
	format Y2014 comma25.;
	drop A ConversionType Country _2014;
run;

/*Cross Verification*/
proc freq data=cleanead_tourism;
	tables Country_Name Tourism_Type Series ConversionType;
run;

proc freq data=cleanead_tourism;
	tables country category;
run;

proc freq data=cleanead_tourism;
	tables Category Tourism_Type Series;
run;

/*Validation*/
proc means data=cleanead_tourism min mean max n maxdec=0;
	var Y2014;
run;

/*Creatinng some Custom Formats*/
proc format;
	value contIDs 1="North America" 2="South America" 3="Europe" 4="Africa" 
		5="Asia" 6="Oceania" 7="Antartica";
run;

/*Merge the matching rows by sorting*/
proc sort data=cr.country_info(rename=(Country=Country_Name)) 
		out=country_sorted;
	by country_name;
run;

/*Creating final tourism table and nocountryfound table*/
data final_tourism NoCountryFound(keep=Country_Name);
	merge cleanead_tourism(in=t) country_sorted(in=s);
	by country_name;

	if (t=1 and s=1) then
		output final_tourism;

	if (t=1 and s=0) and first.country_name=1 then
		output NoCountryFound;
	format continent contIDs.;
run;

/*Checking the final tourism table*/
proc freq data=final_tourism nlevels;
	tables category series Tourism_Type Continent / nocum nopercent;
run;

/*Validating Y2014 table*/
proc means data=final_tourism min mean max maxdec=0;
	var Y2014;
run;