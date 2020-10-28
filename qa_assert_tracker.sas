/***************************************************************
PROGRAM: qa_assert_tracker.sas
PURPOSE: To perform and tabulate QA check results throughout 
         a program or process
AUTHOR : Maria Hudson
INPUTS : Various datasets and checks
OUTPUTS: macro variables, helpful printouts and log messages
***************************************************************
MODIFICATION:

**************************************************************/

******************************;
*   HOW TO USE THIS PROGRAM  *;
******************************;

* This program should be included in each step of your process.                 ;

* Before the first QA step, run the macro qa_assert_setup.  It does not have any;
* input macro variables.                                                        ;

* To run a contents check use the qa_cont macro.  This will run a proc contents ;
* and save the number of obs, number of vars, and any notes as macro variables. ;
* You can perform assertion checks for having 0 or at least one observation by  ;
* setting the value of OBSYESNONA. If this is set to YES then we expect some    ;
* observations and end SAS if not.  No means we expect an empty dataset. NA     ;
* means we do not want to perform an observation check.                         ;

* To run an assertion check outside of a data step, use qa_check_results macro. ;
* Input is a text description of the check performed.  The macro does expect a  ;
* dataset named CHECK that contains an indicator variable named RESULT.  Any    ;
* instance of result=0 will be a failed assertion and will end SAS.  All other  ;
* results will be stored as macro variables.                                    ;

* To run an assertion check inside a data step, use qa_assert macro. The input  ;
* to this macro is a line of code that can execute within the data step.  It    ;
* should be placed inside parentheses if there will be commas, equal signs, or  ;
* other characters that could be interpreted as part of the macro call itself.  ;
* The macro will evaluate that statement to see if it is true (1) or false (0). ;
* If false, it will print an error message to the lst file and then end sas. If ;
* true, it will store that information in macro variables.                      ;

* The qa_finish macro dumps the results of all assertion checks performed into  ;
* the log or lst file. If an assertion fails, it will print to the log file     ;
* (because the endsas statement will not allow the data step to complete and    ;
* print to the lst file). If all assertions pass, this will print to the lst    ;
* file to documentall checks performed. No input is necessary to run unless it  ;
* is being run outside of a data step.  Then set withinds=N.                    ;

* The qa_failprint macro will be called any time an assertion fails. It will put;
* a tailored message (failmsg) to the log file and then call the qa_finish macro;

*****************************;
** END PROGRAM DESCRIPTION **;
*****************************;


* This macro will set up a counter for use in creating QA prints of important   ;
* dataset contents and checks. Run this macro at the begining of each program.  ;
%macro qa_setup;

  * Create global macro variables to be updated throughout the program.;
  %global cnum checknum anum anum_previous prev_assertion;

  * Intialize counter variables to zero. Set previous assertion to blank.;
  %let cnum = 0;
  %let checknum = 0;
  %let anum = 0;
  %let anum_previous = 0;
  %let prev_assertion = ;

%mend qa_setup;


* This macro will be called if any assertion check fails.  It will dump all QA  ;
* assertion checks performed thus far into the log file.  This should also be   ;
* called at the end of the program to dispay final results when all checks pass.;
* INPUT MACRO VARIABLES:                                                        ;
*   WITHINDS-- Y/N indicated for whether the macro is called within a data step.;
*              Defaults to Y. Only needs to be set if you call the macro outside;
*              of a data step.                                                  ;
*   FAILMSG--  Gives a description of the assertion failure to put in the log.  ;
*              Note that these are automatically generated within the various   ;
*              assertion macros and will automatically populate if necessary.   ;
%macro qa_finish(withinds=Y,failmsg=);

  * If this is not called within a data step, then start of a null data step    ;
  * that will print to the lst file.                                            ;
  %if &withinds = N %then %do;

    data _null_;
      file print;

  %end;

  * Output the contents results, if any.                                        ;
  %if %eval(&cnum) > 0 %then %do;

    put "*********************************************************************************************";
    put "***                      Results of Dataset Contents Checks Performed                     ***";
    put "***                        There were &cnum such checks performed                  " @91 "***";
    put "*********************************************************************************************";
    put ;
    put @1 "Check " @9 "Dataset"  @47 "Assertion Check ";
    put @1 "Number" @9 " Name"    @47 "Results (if any)";
    put @1 "------" @9 "-------"  @47 "----------------";

    %do cc = 1 %to &cnum;

      put @1 "&cc" @9 "&&dsname&cc" @47 "&&cresults&cc";
      put ;
      put @5 "Additional Dataset Information:";
      put @5 "# Obs: "                @47 "&&obscount&cc"  ;;
      put @5 "# Vars: "               @47 "&&varcount&cc";
      put @5 "Creation Date/Times:"   @47 "&&dtime&cc";
      %if %eval(&cc)>1 %then %do;
        put @5 "Elapsed time since last dataset check: " @47 "&&elapsed_min_&cc minutes" ;
        put                                              @47 "&&elapsed_hrs_&cc hours";
      %end;
      put @5 "Dataset Notes: &&note&cc";
      put /;

    %end;

    put ;
    put "*********************************************************************************************";
    put ;
    
  %end;

  * Output the stand-alone assertion check results, if any                      ;
  %if %eval(&checknum) > 0 %then %do;

    put "*********************************************************************************************";
    put "***                    Results of Stand-alone Assertion Checks Performed                  ***";
    put "***                        There were &checknum such checks performed              " @91 "***";
    put "*********************************************************************************************";
    put ;
    put @1 "Check Number" @20 "Check Performed and Result" ;
    put @1 "------------" @20 "--------------------------" ;

    %do cc = 1 %to &checknum;

      put @1 "&cc" @20 "&&checkresult&cc";

    %end;

    put ;
    put "*********************************************************************************************";
    put ;
    
  %end;

  * Output the within-datastep assertion check results, if any                  ;
  %if %eval(&anum) > 0 %then %do;

    put "*********************************************************************************************";
    put "***                Results of Within-Data_Step Assertion Checks Performed                 ***";
    put "***                        There were &anum such checks performed                  " @91 "***";
    put "***  Check below this print to make sure there are no failures masked by the fact that a  ***";
    put "***  data step did not complete due to the assertion failure.  The fail message will be   ***";
    put "***  printed both above and below this section.                                           ***";
    put "*********************************************************************************************";
    put ;
    put @1 "Check Number" @20 "Check Performed" @75 "Result";
    put @1 "------------" @20 "---------------" @75 "------";

    %do cc = 1 %to &anum;

      put @1 "&cc" @20 "&&assertion&cc" @75 "&&aresult&cc";

    %end;

    put ;
    put "*********************************************************************************************";
    put ;

  %end;

  * To be sure that we do no miss an assertion failure, print the fail message, ;
  * if any, four times below the list of sucessful tests.  The within-datastep  ;
  * failures will not be updated from pass to fail due to to the abort cancel   ;
  * that runs directly after them.  Data step changes only happen when the data ;
  * step completes.  Thus the need to make extra sure these failures are highly ;
  * visible.                                                                    ;
  put "*********************************************************************************************";
  put ;
  put " &failmsg ";
  put " &failmsg ";
  put " &failmsg ";
  put " &failmsg ";
  put ;
  put "*********************************************************************************************";

  %if &withinds = N %then %do;
    run;
  %end;

%mend qa_finish;

* This macro will be called anytime an assertion check fails.  It will print    ;
* the specific failure to the top of the log and then run the qa-print macro to ;
* output previously checked assertions to the log.                              ;
* INPUT MACRO VARIABLES:                                                        ;
*   FAILMSG--  Gives a description of the assertion failure to put in the log.  ;
*              Note that these are automatically generated within the various   ;
*              assertion macros and will automatically populate if necessary.   ;
* NOTE-- This macro assumes that it is being called within a data step. Since it;
*        is only called within the assertion macros, there is no need to update.;
%macro qa_failprint(failmsg=);

  put "*********************************************************************************************";
  put "***    ASSERTION FAILURE!  ASSERTION FAILURE!  ASSERTION FAILURE!  ASSERTION FAILURE!     ***";
  put "*** Previously run successful checks (if any) will print below. Must fix and rerun!" @91 "***";
  put "*********************************************************************************************";
  put ;
  put "&failmsg";
  put "&failmsg";
  put "&failmsg";
  put "&failmsg";
  put ;
  put "*********************************************************************************************";

  %qa_finish(failmsg=&failmsg);


%mend qa_failprint;


* This macro quickly looks at contents of important datasets, keeping only the  ;
* name, obs count, and var count and storing them as macro variables. It also   ;
* stores notes provided in the macro call and runs an assertion check.          ;
* INPUT MACRO VARIABLES:                                                        ;
*   DSNAME--   Name of the dataset we are running the contents and/or assertion ;
*              check against.                                                   ;
*   OBSYESNONA-Indicates if we are running and assertion check on the contents. ;
*              YES if we are checking that the dataset has observation          ;
*              NO if we are checking that the dataset has no observations       ;
*              NA if we are no performing any observation checks                ;
*   NOTE--     Any note regarding the dataset you want printed to the lst file. ;
%macro qa_cont(dsname=,obsyesnona=,note=);

  * Increment the count of datasets that we have performed a contents check on. ;
  * This is used to keep track and to make the final printout easier.           ;
  %let cnum = %eval(&cnum + 1);

  * Upcase the obs-check indicator for consistency.                             ;
  %let obsyesnona = %upcase(&obsyesnona);

  * Create global macro variables that contain the information for this run of  ;
  * the contents checker. We will use this if/when we run the qa_finish macro.  ;
  %global dsname&cnum note&cnum obscount&cnum varcount&cnum dtime&cnum 
          cresults&cnum elapsed_min_&cnum elapsed_hrs_&cnum;
  %let dsname&cnum = &dsname;
  %let note&cnum = &note;

  * Delete the temp dataset as a precaution.                                    ;
  proc datasets lib=work nolist;
    delete contents_temp;
  run;

  * Run contents procedure on the dataset, keeping only the information we need ;
  proc contents data=&dsname noprint 
                 out=contents_temp (keep=nobs libname memname varnum crdate);
  run;

  * Sort by descending varnum so that the last variable in the dataset will be  ;
  * displayed in the first observation, giving us the variable count.           ;
  proc sort data=contents_temp; 
    by descending varnum;
  run;

  * Look at the variable and observation count. Test assersions for the dataset.;
  * Create global observation and variable counts.                              ;
  data testcr;
    set contents_temp(obs=1);

    * Output contents info to global macro variables                            ;
    call symput("obscount&cnum",left(trim(nobs)));
    call symput("varcount&cnum",left(trim(varnum)));
    call symput("dtime&cnum",put(crdate,datetime16.));

    * Create flags for pass/fail on this test                                   ;
    obsyesnona = "&obsyesnona";
    obsyesnona = upcase(compress(obsyesnona));
    if obsyesnona = "YES" then do;
      if nobs > 0 then call symput("cresults&cnum","PASSED-- Dataset &dsname Has Observations, as expected");
      else call symput("cresults&cnum","FAILED-- &dsname Has No Observation but should");
    end;
    else if obsyesnona = "NO" then do;
      if nobs = 0 then call symput("cresults&cnum","PASSED-- &dsname Has No Observations, as expected");
      else call symput("cresults&cnum","FAILED-- Dataset &dsname Has Observation but should not");
    end;
    else if obsyesnona = "NA" then do;
      call symput("cresults&cnum","N/A-- No Contents Assertion Performed for Dataset &dsname");
    end;

    * If this is not the first contents check then calculate elapsed time.      ;
    %if %eval(&cnum) > 1 %then %do;
      %let tempnum = %eval(&cnum - 1);
      format prevdate datetime16.;
      prevdate = input("&&dtime&tempnum",datetime16.);
      elapsed_time_minutes = (crdate - prevdate) / 60;
      elapsed_time_hours = elapsed_time_minutes / 60;
      call symput("elapsed_min_&cnum",left(trim(round(elapsed_time_minutes,.001))));
      call symput("elapsed_hrs_&cnum",left(trim(round(elapsed_time_hours,.001))));
    %end;

  run;

  * Look at the results generated and populate macro variables accordingly.     ;
  %if %qsubstr(%nrbquote(&&cresults&cnum),1,4)=FAIL %then %do;
    data _null_;
      %qa_failprint(failmsg=&&cresults&cnum);
      abort cancel;
    run;
  %end;


%mend qa_cont;

* This macro will perform an assertion check.  It expects there to be a dataset ;
* named check that has a variable named result.  The result variable should be a;
* binary variable indicating that an assertion is true (pass) or false (fail).  ;
* If there are any instance of result = 0 the program will end and a message    ;
* will be put into the log file.  Otherwise, the positive result will be saved  ;
* in a macro variable.                                                          ;
* INPUT MACRO VARIABLES:                                                        ;
*   CHECKDESC- A description of the assertion/check to be performed             ;
%macro qa_check_results(checkdesc);

  * Increment the count of data checks that we have performed.                  ;
  * This is used to keep checknum and to make the final printout easier.        ;
  %let checknum = %eval(&checknum + 1);

  * Create a global macro variables to hold the check description and result.   ;
  %global checkresult&checknum;

  * Delete the temp dataset as a precaution                                     ;
  proc datasets lib=work nolist;
    delete check_temp;
  run;

  * Initialize the result to be passing.                                        ;
  %let checkresult&checknum = PASSED-- &checkdesc -- TRUE;

  * Bring in one observation from the dataset where the result is failing.      ;
  data _null_;
    set check (where=(result=0) obs=1);

    * If the check failed then dump all checks prior to this point into the lst ;
    * file and end SAS.                                                         ;
    if result = 0 then do;
      %qa_failprint(failmsg=STAND-ALONE ASSERTION CHECK &checknum FAILED-- &checkdesc -- NOT TRUE);
      abort cancel;
    end;

  run;

%mend qa_check_results;

* This macro is used to test an assertion within a data step.  If the condition ;
* is met, SAS will stop and a message will be displayed in the print file.  If  ;
* the condition is not met, SAS will continue and we will store the value of the;
* assertion in a macro variable so we can update the overall assertion dataset  ;
* when we run the qa_finish macro.                                              ;
* INPUT MACRO VARIABLES:                                                        ;
*   ASSERTION- A statement, preferably within parentheses that will execute in  ;
*              a data step and result in either a 0 or a 1.                     ;
%macro qa_assert(assertion);

    * Check to see if this is a new assertion by comparing to the previous value;
    * of the macro variable prev_assertion (which is global).  If they are      ;
    * different then this is a new assertion.                                   ;
    * This is important because otherwise each observation in a dataset will be ;
    * taken as a new assertion.                                                 ;
    %if %upcase("&assertion.") ne %upcase("&prev_assertion.") %then %do;

      * Increment the assertion count number.;
      %let anum = %eval(&anum + 1);

      * Create a macro variable that contains the value of assertion associated ;
      * with this value of anum.  We will use this to create the final list of  ;
      * assertion checks.                                                       ;
      %global assertion&anum. aresult&anum;
      %let assertion&anum = &assertion;

      * Because this runs within a data step, we have to default the result to  ;
      * be PASSED. Data steps that end early do not fully execute.              ;
      %let aresult&anum = PASSED;

      * Reset the value of prev_assertion so we can check against it the next   ;
      * time the assertion macro runs.                                          ;
      %let prev_assertion = &assertion;

    %end;

    * If the assertion is not true, then run the failprint macro and end the sas;
    * session.  Otherwise, do nothing and allow the data step to continue.      ;
    if &assertion. = 0 then do;
      %qa_failprint(failmsg=(WITHIN DATASET ASSERTION CHECK FAILED-- &assertion -- NOT TRUE));
      abort cancel;
    end;

%mend qa_assert;

