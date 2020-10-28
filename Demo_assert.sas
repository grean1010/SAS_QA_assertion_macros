/*********************************************************************/
/* Program    :  Demo_assert.sas                                     */
/* Description:  Demonstrate macros and tricks as outlined in the    */
/*               Data Quality presentation given on xx/xx/2018       */
/* Input      :  DQ macros, dummy data                               */
/* Output     :  Lst file with helpful information                   */
/* Note       :                                                      */
/*                                                                   */
/*********************************************************************/
options mlogic mprint symbolgen;

* Libnames for use in demo;
libname testdata "C:\Users\mhudson\marias_projects\SAS_QA_assertion_macros";

%include "C:\Users\mhudson\marias_projects\SAS_QA_assertion_macros\qa_assert_tracker.sas";

%qa_setup;


data states us (keep=state_code state_total_obs) probs;
  set testdata.states;
  if state_code = 'US' then output us;
  else if state_code = "XX" then output probs;
  else output states;
run;

* Check the contents of these datasets;
%qa_cont(dsname=states,obsyesnona=YES,note=States data without total);
%qa_cont(dsname=us,obsyesnona=YES,note=Total Only);
%qa_cont(dsname=probs,obsyesnona=NO,note=Total Only);

* This contents check is designed to fail. Comment in to demonstrate ;
* a contents assertion failure.;
*%qa_cont(dsname=us,obsyesnona=NO,note=Total Only);

data check;
  set states;
  if state_code = "US" then result = 0;
  else result = 1;
run;

%qa_check_results(No US Total included in states dataset);

* This check is designed to fail;
data check;
  set states;
  if state_code = "US" then result = 1;
  else result = 0;
run;
%qa_check_results(US Total included in states dataset);


proc sort data=states nodupkey;  by state_code; run;

%qa_cont(dsname=states,obsyesnona=YES,note=States data de-duplicated);
%qa_cont(dsname=states,obsyesnona=NA,note=States data de-duplicated);

data total_comp (keep=state_code total);
  set states end=lastobs;
  if _n_ = 1 then total = 0;
  retain total;
  total = total + state_total_obs;
  if lastobs then do;
    state_code = "US";
    output;
  end;
run;

%qa_cont(dsname=total_comp,obsyesnona=YES,note=States collapsed to total only);

data compare_them;
  merge total_comp us;
  by state_code;
  %qa_assert(1);
  %qa_assert((1=1));
  %qa_assert((round(total,.01) = round(state_total_obs,.01)));

  * this one is designed to fail;
  *%qa_assert((1=0));


run;

%qa_cont(dsname=compare_them,obsyesnona=YES,note=Comparison dataset);

%qa_finish(withinds=N);
