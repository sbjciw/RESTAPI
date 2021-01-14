
/* retrieve the report content object  from an existing report */
%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
FILENAME rContent TEMP ENCODING='UTF-8';
PROC HTTP METHOD="GET" oauth_bearer=sas_services OUT= rContent
    URL = "&BASE_URI/reports/reports/ffb113b7-9cfa-434b-99f1-9b3fe5a9f340/content";
    HEADERS "Accept" = "application/vnd.sas.report.content+json";
RUN;

/* create a new report object in a folder  */
FILENAME tReport TEMP ENCODING='UTF-8';
FILENAME hdrout TEMP ENCODING='UTF-8';
PROC HTTP METHOD = "POST" 
     URL = "&BASE_URI/reports/reports?parentFolderUri=/folders/folders/dbbc365c-69dc-4e3f-97c9-49818029fde1"
     OUT = tReport HEADEROUT=hdrout 
     OAUTH_BEARER = SAS_SERVICES
     IN = '{
                                     "name": "Report by API",
                                     "description": "Create Report from REST API"
            }' ;
      HEADERS "Accept" = "application/vnd.sas.report+json"
                    "Content-Type" = "application/vnd.sas.report+json" ;
RUN;

/* print the response header, and get the value of 'ETag' and 'Last-Modified' */
data  _null_;
         infile hdrout;
         input;
         put _infile_;
run;


/* save the report URI of the new created report into a macro variable rptid  */
proc sql ;
	select distinct value into :val
	from treport.alldata
	where p2="uri";
quit;
%LET rptid = %trim(&val);


/* save the retrieved report content object to the newly created report */
/* need to replace the IF-MATCH value with the value of ¡®ETag¡¯ from previous response header */
/* need to replace the IF-UNMODIFIED-SINCE value with the value of ¡®Last-Modified¡¯ from previous response header */
PROC HTTP METHOD = "PUT" 
     URL = "&BASE_URI.&rptid/content"
     OAUTH_BEARER = SAS_SERVICES 
     IN = rContent ;
     HEADERS "Accept" = "*/*"
                            "Content-Type" = "application/vnd.sas.report.content+json"
                            "IF-MATCH" = """kjv0va4n"""
                            "IF-UNMODIFIED-SINCE" = "Wed, 13 Jan 2021 06:07:37 GMT"
      ;
RUN;


/* Now you should be able to open the new report in VA   */
