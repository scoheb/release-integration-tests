## FBC happy path e2e-test ##

 This section provides instructions on running the FBC e2e test with the provided script

   ## Test Steps and Expected Result

   1. **Pre-Running Test:** The following setup actions need to be completed before running the test script.
      
      The test is running against RHTAP-Stage, so a user who wants to monitor the test running through the UI or the CLI
      will need access to the cluster and the workspaces *dev-release-team* and *managed-release-team*. 
      
      The test expects to run in the workspaces mentioned above. It is expected that the dev-release-team-tenant and managed-release-team-tenant namespaces exist with the EnterpriseContractPolicy, ServiceAccount and secrets already deployed in them.

      Since this test runs against RHTAP stage, it requires the user executing it to be logged into the SSO service. Otherwise, the SSO login web page will pop up.
      

   2. **Running the Test:**
      The test script sets up resources, waits for pipeline runs to complete, checks release status, and reports the result.


   3. **Expected Result:**

      a. `We expect that a Build PipelineRun in dev workspace started and succeeded.`

      b. `A PipelineRun is executed in the managed workspace using the fbc-release pipelineRef and it succeeds.`

      c. `Release CR is expected to be updated with Released after Release PipelineRun completes and succeeds.`
   ## How to Run the Test

   To run the test script, follow these steps:

   1. **Navigate to the Script Directory:** Use the `cd` command to navigate to the directory containing the script.

         ```sh
      cd fbc
   2. **Run the script:** Execute the script using the command:

      ```sh
      ./fbc-test.sh
   3. **Monitor the Test Output:** The script will provide output indicating the progress of the test, including setup actions, waiting for pipeline runs, and checking the release status. One can also monitor the RHTAP-Stage Console.




