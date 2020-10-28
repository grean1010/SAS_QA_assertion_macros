# SAS_QA_assertion_macros
A set of macros to run and check QA assertions in your SAS code

## Motivation
For long-running programs, we want a way to check key issues as the program runs and to kill the program if there is any of these pre-defined issues is determined to be a problem.  For example, if you had a program that takes 2 days to run, you would not want to find out only at the end of those 2 days that one of your key variables was missing and that the entire run is invalid.  Running assertion checks at key junctures in your code can give you valuable information and save precious processing time if a problem is found mid-run.

I wrote a series of macros to set up an assertion-tracking dataset, run key assertion types, create useful fail messages when assertions fail, and print a useful summary of all assertions run clean. There is also a simple SAS program to demostrate how these assertions and trackers might be used.

## Contents of this repo
* **qa_assert_tracker.sas**:  This is the SAS program that contains assertion and results-tracking SAS macros described in this document.
* **Demo_assert.sas**: This is simple SAS code to demonstrate how the macros can be used. It is provided for demonstration purposes.  Note that log and lst files are also provided to show how the log/lst messages look when assertions fail and when they are sucessful.
* **states.sas7bdat**: This is a simple SAS dataset containing state abbreviations and a count variables. It is provided for demonstration purposes. 

## How to use the program
* This program should be included early in your SAS program.  If you have a multi-program system, you should include it in each program.
* Before the first QA step, run the macro qa_assert_setup.  This will prepare the assertion tracking datasets and macro variables.
* Run assertions checks (described below) throughout your code where needed.
* Run the qa_finish macro to dump the results of all assertion checks into the log/lst files.

## Description of individual macros and usage

# qa_setup
* This macro sets up the global macros that count checks and store the description of any previously run assertion check
* The counts will be initialized to zero.  The text initiaizes to blank.

# qa_finish
* This macro will be called if any assertion check fails.  It will dump all QA assertion checks performed thus far into the log file.  This should also be called at the end of the program to dispay final results when all checks pass.
* INPUT MACRO VARIABLES:
    * WITHINDS-- Y/N indicated for whether the macro is called within a data step. Defaults to Y. Only needs to be set if you call the macro outside of a data step.                                                  
    * FAILMSG--  Gives a description of the assertion failure to put in the log. Note that these are automatically generated within the various assertion macros and will automatically populate if necessary. 

# qa_failprint
* This macro will be called anytime an assertion check fails.  It will print the specific failure to the top of the log and then run the qa-print macro to output previously checked assertions to the log. 
* The message is designed to be big and obnoxious so you cannot miss how and why your assertion failed.
* INPUT MACRO VARIABLES:                                                        
    * FAILMSG--  Gives a description of the assertion failure to put in the log.  Note that these are automatically generated within the various assertion macros and will automatically populate if necessary.   
* NOTE-- This macro assumes that it is being called within a data step. Since it is only called within the assertion macros, there is no need to update.

# qa_cont
* This macro quickly looks at contents of important datasets, keeping only the name, obs count, and var count and storing them as macro variables. It also stores notes provided in the macro call and runs an assertion check.
* If requested, this macro will also perform an assertion check.  See the input macro variables for more information.
* INPUT MACRO VARIABLES: 
    * DSNAME--   Name of the dataset we are running the contents and/or assertion check against.                                                   
    * OBSYESNONA-Indicates if we are running and assertion check on the contents. 
        * YES if we are checking that the dataset has observation
        * NO if we are checking that the dataset has no observations
        * NA if we are no performing any observation checks
    * NOTE-- Any note regarding the dataset you want printed to the lst file. 

# qa_check_results
* This macro will perform an assertion check.  It expects there to be a dataset named "check" that has a variable named "result".  The result variable should be a binary variable indicating that an assertion is true (pass) or false (fail).  
* If there are any instance of result = 0 the program will end and a message will be put into the log file.  Otherwise, the positive result will be saved in a macro variable.                                                          
* INPUT MACRO VARIABLES:                                                        
    * CHECKDESC- A description of the assertion/check to be performed             

# qa_assert
* This macro is used to test an assertion within a data step.  If the condition is met, SAS will stop and a message will be displayed in the print file.  If the condition is not met, SAS will continue and we will store the value of the assertion in a macro variable so we can update the overall assertion dataset when we run the qa_finish macro.
* INPUT MACRO VARIABLES:                                                        
    * ASSERTION- A statement, preferably within parentheses that will execute in a data step and result in either a 0 or a 1. 
               
