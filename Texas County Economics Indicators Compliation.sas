 *****************************************************;
* Clear the LOG window and reset LOG line numbering;
*****************************************************;
dm 'log' clear;
resetline;
*****************************************************;

*******************Texas_County_Unemployment & Data Validation ************************;

PROC IMPORT DATAFILE="C:\Users\bprom19\Desktop\ECON 673 HW Data\SAS Programming Project\Texas_County_Unemployment.csv" 
		OUT=UNEMPLOYMENT (RENAME=(geoname=County)) REPLACE DBMS=CSV;
	GETNAMES=YES;
	DATAROW=2;
	GUESSINGROWS=MAX;
RUN;

data unemployment;
	length county $26.;
	set unemployment;
	*if date <MDY(1,1,2017) then delete;
	county=upcase(county);
	County=substr(County, 1, find(county, "COUNTY")-1);
	format county $26.;
	format unemployment_rate 8.2;
run;

data unemploy_rate;
	set unemployment (where=(county='HARRIS' OR county='DALLAS' OR 
		COUNTY='TARRANT' OR COUNTY='BEXAR' OR COUNTY='TRAVIS' OR COUNTY='COLLIN' OR 
		COUNTY='DENTON' OR COUNTY='HIDALGO' OR COUNTY='EL PASO' OR 
		COUNTY='FORT BEND'));

	if date <MDY(1, 1, 2017) then
		delete;

	if date>MDY(8, 1, 2022) then
		delete;
run;

proc sort data=unemploy_rate;
	by county date;
run;

*******************Texas_County_SaleTax_Receipts & Data Validation ************************;

PROC IMPORT OUT=TAX DATAFILE="C:\Users\bprom19\Desktop\ECON 673 HW Data\SAS Programming Project\Texas_County_SalesTax_Receipts.csv" 
		DBMS=CSV REPLACE;
	GETNAMES=YES;
	DATAROW=2;
	GUESSINGROWS=MAX;
RUN;

data tax_1;
	set tax (rename=(sales_tax_receipts=sales_tax));
	sale_tax=input(sales_tax, comma12.2);
	length sale_tax 8.;
	format sale_tax dollar12.2;
	county=upcase(county);
	drop sales_tax;
run;

data Tax_Receipts;
	set tax_1(where=(county='HARRIS' OR county='DALLAS' OR COUNTY='TARRANT' OR 
		COUNTY='BEXAR' OR COUNTY='TRAVIS' OR COUNTY='COLLIN' OR COUNTY='DENTON' OR 
		COUNTY='HIDALGO' OR COUNTY='EL PASO' OR COUNTY='FORT BEND'));

	if date <MDY(1, 1, 2017) then
		delete;

	if date>MDY(8, 1, 2022) then
		delete;
run;

proc sort data=tax_receipts;
	by county date;
run;

******************* mix_beverage_receipts & Data Validation ************************;
libname project 
	"C:\Users\bprom19\Desktop\ECON 673 HW Data\SAS Programming Project";

data beverage(Keep=code Total_Receipts date year);
	set project.Mix_beverage_receipts (rename=(location_county=code));
	month=month(obligation_end_date);
	year=year(obligation_end_date);
	date=mdy(month, 1, year);
	*date=intnx('month',obligation_end_date,0);
	format date MMDDYY10.;
	format total_receipts dollar12.2;
	format code 3.;
run;

proc sort data=beverage;
	by code date;
run;

data beverage_aggr;
	set beverage;
	by code date;
	retain date;

	if first.date then
		total_Al_Sales=0;
	total_Al_sales+total_receipts;

	if last.date;
	format total_al_sales dollar12.2;
	drop total_receipts;
run;

************************* County_Codes & Data Validation ************************;

PROC IMPORT OUT=codes DATAFILE="C:\Users\bprom19\Desktop\ECON 673 HW Data\SAS Programming Project\County Codes.xlsx" 
		DBMS=XLSX REPLACE;
	GETNAMES=YES;
	SHEET="County";
RUN;

data codes;
	length county $26;
	set codes;
	format code 3.;
	format county $26.;
run;

******************** Texas_County_Population & Data Validation ************************;

PROC IMPORT out=population (rename=(ctyname=County year=Year)) DATAFILE="C:\Users\bprom19\Desktop\ECON 673 HW Data\SAS Programming Project\Texas_County_Population.csv" 
		DBMS=csv replace;
	GETNAMES=YES;
	DATAROW=2;
	GUESSINGROWS=MAX;
RUN;

data population;
	length county $26;
	set population;
	county=upcase(county);
	County=substr(County, 1, find(county, "COUNTY")-1);
	format county $26.;
	format TOT_POP 12.;
RUN;

data population_1;
	set population (where=(county='HARRIS' OR county='DALLAS' OR COUNTY='TARRANT' 
		OR COUNTY='BEXAR' OR COUNTY='TRAVIS' OR COUNTY='COLLIN' OR COUNTY='DENTON' OR 
		COUNTY='HIDALGO' OR COUNTY='EL PASO' OR COUNTY='FORT BEND'));
run;

proc sort data=population_1;
	by county year;
run;

************Calculating population for 2022**************;

data pop2014;
	set population_1(rename=(tot_pop=pop2014));
	by county year;
	where Year=2014;
run;

data pop2021;
	set population_1(rename=(tot_pop=pop2021));
	by county year;
	where Year=2021;
run;

data Pop2022;
	merge pop2014 pop2021;
	by county;
	acgr=(pop2021/pop2014)**(1/7);
	TOT_POP=acgr*pop2021;
	format TOT_pop 12.;
	year=2022;
	drop pop2014 pop2021 acgr;
run;

data population_1;
	set pop2022 population_1;
	by county;
run;

proc sort data=population_1;
	by county year;
run;

********************************Import CPI Data & Data Validation*****************************;

PROC IMPORT DATAFILE="C:\Users\bprom19\Desktop\ECON 673 HW Data\SAS Programming Project\us cpi.xlsx" 
		DBMS=xlsx out=work.cpi replace;
	sheet="CPI";
	GETNAMES=YES;
RUN;

data CPI_USE;
	set CPI;
	month=scan(period, 1, "M");
	month_1=input(month, 2.);
	date=mdy(month_1, 1, year);
	drop period;
	drop month;
	drop month_1;
	drop year;
	format date mmddyy10.;
run;

proc sort data=cpi_use;
	by date;
run;

*************************Merging mix beverage receipts with county code***********************;

proc sort data=beverage_aggr;
	by code;
run;

proc sort data=codes;
	by code;
run;

data beverage_new;
	merge beverage_aggr codes;
	by code;
run;

data beverage_interest;
	set beverage_new (where=(county='HARRIS' OR county='DALLAS' OR 
		COUNTY='TARRANT' OR COUNTY='BEXAR' OR COUNTY='TRAVIS' OR COUNTY='COLLIN' OR 
		COUNTY='DENTON' OR COUNTY='HIDALGO' OR COUNTY='EL PASO' OR 
		COUNTY='FORT BEND'));

	if date <MDY(1, 1, 2017) then
		delete;

	if date>MDY(8, 1, 2022) then
		delete;
run;

proc sort data=beverage_interest;
	by county year;
run;

************************Merging mix beverage receipts with population data sets****************;

data beverage_pop;
	merge beverage_interest population_1;
	by county year;

	if date <MDY(1, 1, 2017) then
		delete;

	if date>MDY(8, 1, 2022) then
		delete;
	drop year;
	drop code;
run;

proc sort data=beverage_pop;
	by date;
run;

***************************Beverage_Population Data with CIPI data*******************************;

data final_data;
	merge beverage_pop cpi_use;
	by date;
	drop series_id;
run;

data final_data;
	set final_data (where=(county='HARRIS' OR county='DALLAS' OR COUNTY='TARRANT' 
		OR COUNTY='BEXAR' OR COUNTY='TRAVIS' OR COUNTY='COLLIN' OR COUNTY='DENTON' OR 
		COUNTY='HIDALGO' OR COUNTY='EL PASO' OR COUNTY='FORT BEND'));

	if date <MDY(1, 1, 2017) then
		delete;

	if date>MDY(8, 1, 2022) then
		delete;
run;

proc sort data=final_data;
	by county date;
run;

***********Merging Final Data with Tax Sales Report and Unemployment*****************;

data final_data;
	merge final_data tax_receipts Unemploy_rate;
	by county date;
run;

************************Calculating Real Per Capita Alcohol Sales********************;

data Project_Report 
(keep=Date County_Name Unemployment_Rate RealPerCapita_Alcohol_Sales 
		RealPerCapita_Sales_Tax_Receipts);
	set final_data;
	rename county=County_Name unemployment_rate=Unemployment_Rate date=Date;
	PC_Alc=total_AL_Sales/TOT_POP;
	RealPerCapita_Alcohol_Sales=(PC_Alc/CPI_2020)*100;
	PC_tax=sale_tax/TOT_POP;
	RealPerCapita_Sales_Tax_Receipts=(PC_tax/CPI_2020)*100;
	format RealPerCapita_Alcohol_Sales 8.2;
	format RealPerCapita_Sales_Tax_Receipts 8.2;
run;

**************************************END OF CODE************************************;
