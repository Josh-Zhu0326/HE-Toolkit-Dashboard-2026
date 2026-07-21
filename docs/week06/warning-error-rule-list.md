# Warning and Error Rule List for Client Review

**Date:** 2026-07-02\
**Purpose:** This document summarises the key validation and
error-handling rules that require client confirmation before further
dashboard development. It focuses on the expected user experience rather
than implementation details.

------------------------------------------------------------------------

# 1. Severity Definitions

  -----------------------------------------------------------------------
  Severity                Meaning                 Continue Workflow?
  ----------------------- ----------------------- -----------------------
  **Error**               A required input or     ❌ No
                          prerequisite is         
                          missing.                

  **Warning**             The workflow can        ✅ Yes
                          continue, but outputs   
                          may be incomplete.      

  **Info**                Confirmation or         ✅ Yes
                          guidance for the next   
                          step.                   
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 2. Design Principles

The dashboard follows four principles:

-   **Biology + Flow** form the required workflow.
-   **WQ** and **RHS** are optional datasets that enrich the analysis.
-   Missing optional datasets should **not** prevent the core workflow.
-   Users should always see clear messages instead of raw R/Shiny
    errors.

------------------------------------------------------------------------

# 3. Validation Rules by Workflow

## A. Metadata

  -----------------------------------------------------------------------
  Situation         Severity          User Message      Client
                                                        Confirmation
  ----------------- ----------------- ----------------- -----------------
  Missing metadata, Error             Please provide    Confirm required
  required columns                    valid site        metadata fields.
  or invalid                          metadata before   
  `flow_input`                        importing data.   

  Site IDs are not  Warning           Site IDs should   Should IDs always
  stored as text                      be stored as      be converted
                                      text. The app     automatically?
                                      will attempt      
                                      automatic         
                                      conversion.       
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## B. Biology Workflow

  -----------------------------------------------------------------------
  Situation         Severity          User Message      Client
                                                        Confirmation
  ----------------- ----------------- ----------------- -----------------
  Biology data has  Error             Please import     Confirm wording.
  not been imported                   biology data      
                                      before            
                                      continuing.       

  RICT predictions  Error             Please complete   Confirm workflow
  or O:E ratios                       the previous      order.
  requested before                    biology           
  previous steps                      processing step   
                                      first.            
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## C. Water Quality (WQ)

  -----------------------------------------------------------------------
  Situation         Severity          User Message      Client
                                                        Confirmation
  ----------------- ----------------- ----------------- -----------------
  Missing or        Error             Please provide    Confirm accepted
  invalid WQ                          valid WQ site IDs ID fields.
  mapping                             before importing  
  (`wq_site_id`)                      water quality     
                                      data.             

  Import completed  Warning           WQ data was       Should modelling
  with missing                        imported, but     continue with
  determinands or                     some results may  warnings?
  partial data                        be incomplete.    
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## D. River Habitat Survey (RHS)

  -----------------------------------------------------------------------
  Situation         Severity          User Message      Client
                                                        Confirmation
  ----------------- ----------------- ----------------- -----------------
  Missing RHS       Error             Please provide a  Confirm required
  mapping or                          valid RHS survey  identifiers.
  invalid upload                      ID and upload a   
                                      valid RHS file.   

  RHS imported but  Warning           RHS data was      Warning or Error?
  no matching                         imported but no   
  records found                       matching records  
                                      were found.       
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## E. Flow Processing

  -----------------------------------------------------------------------
  Situation         Severity          User Message      Client
                                                        Confirmation
  ----------------- ----------------- ----------------- -----------------
  Missing flow      Error             Please provide    Confirm wording.
  metadata                            valid flow        
                                      metadata before   
                                      importing flow    
                                      data.             

  Invalid donor     Error             Donor mapping is  Confirm
  mapping                             incomplete or     validation rules.
                                      invalid. Please   
                                      review the donor  
                                      mapping table.    

  Required donor    Error             Please import the Confirm workflow.
  stations have not                   required donor    
  been imported                       stations before   
                                      flow processing.  

  Flow statistics   Error             Flow processing   Confirm
  or imputation                       failed. Please    behaviour.
  failed                              check the         
                                      imported flow     
                                      data and donor    
                                      information.      

  Duplicate flow    Warning           Duplicate flow    Confirm handling
  metadata detected                   records were      strategy.
                                      ignored during    
                                      processing.       
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## F. Data Joining

  -----------------------------------------------------------------------
  Situation         Severity          User Message      Client
                                                        Confirmation
  ----------------- ----------------- ----------------- -----------------
  Required          Error             Please complete   Confirm workflow.
  prerequisites                       all required      
  (Flow Statistics                    processing before 
  or O:E) missing                     joining datasets. 

  Join produced no  Warning           No matching       Warning or Error?
  matching records                    records were      
                                      found for the     
                                      selected join     
                                      settings.         

  Optional WQ/RHS   Warning           Some optional     Confirm join
  data could not be                   WQ/RHS data could strategy.
  joined                              not be be joined  
                                      successfully.     
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## G. HEV Visualisation

  -----------------------------------------------------------------------
  Situation         Severity          User Message      Client
                                                        Confirmation
  ----------------- ----------------- ----------------- -----------------
  Joined dataset    Error             Please create the Confirm wording.
  unavailable                         joined dataset    
                                      before generating 
                                      HEV plots.        

  No records        Warning           No records are    Confirm expected
  available for                       available for the behaviour.
  selected filters                    selected options. 
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## H. Modelling (Future MVP)

  -----------------------------------------------------------------------
  Situation         Severity          User Message      Client
                                                        Confirmation
  ----------------- ----------------- ----------------- -----------------
  Required data or  Error             Please complete   Confirm workflow.
  variables are                       previous steps    
  missing                             and select valid  
                                      variables before  
                                      modelling.        

  Rows containing   Warning           Rows with missing Confirm expected
  missing values                      values have been  behaviour.
  are removed                         excluded from the 
                                      analysis.         
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 4. Key Issues Observed During Local Testing

The following issues were observed during local testing and should be
prioritised:

-   Invalid donor mapping prevented flow processing.
-   Required donor stations were missing during imputation.
-   Flow imputation failed when only one station was available.
-   Joining failed because Flow Statistics had not been calculated.
-   HEV plots could not be generated before datasets were joined.
-   WQ import completed with missing determinands but remained usable.

------------------------------------------------------------------------

# 5. Recommended Implementation Priority

**High Priority** - Metadata validation - Flow validation - Join
prerequisites - HEV prerequisites

**Medium Priority** - WQ/RHS validation - Join quality warnings -
Optional dataset integration

**Low Priority** - Modelling improvements - Additional guidance messages

------------------------------------------------------------------------

# 6. Questions for Client

1.  Should WQ and RHS remain optional datasets?
2.  Should `TBC` values be treated as warnings or errors?
3.  Should duplicate flow records be ignored automatically?
4.  Should unmatched WQ/RHS records prevent downstream analysis?
5.  Is the current WQ/RHS summary approach acceptable?

------------------------------------------------------------------------

# 7. Overall Recommendation

The dashboard should distinguish clearly between **blocking errors** and
**non-blocking warnings**.

The standard **Biology → Flow → Join → HEV** workflow should always
remain available. Optional WQ and RHS datasets should improve the
analysis without preventing users from completing the core workflow
whenever possible.

This document is intended to support discussion with the client rather
than define final implementation details.
