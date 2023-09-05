# Release Integration Tests


## 1. FBC Test (happy path):
The purpose of this release test (FBC) is to verify the functionality and stability of feature in RHTAP.
Test is a "happy-path" test and it's running on the internal RHTAP stage cluster.


### Steps
- Create an application from the build repo [fbc-sample-pro](https://github.com/redhat-appstudio-qe/fbc-sample-repo) in the dev workspace.
- We expect to witness a build pipeline starting and after a while we expect it to succeed.
- After the build pipeline a release pipeline should be triggered, once all tasks are done we expect it succeeded.


### Expected Results
We are expecting the application to pass successfully and release as the images are created.