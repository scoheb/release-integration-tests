# Release Integration Tests

## General Setup

Some tests in this repository, require an Offline token in order to authenticate with the RHTAP Staging clusters
being targeted.

### Getting an offline token

* Obtain one by navigating to https://console.redhat.com/openshift/token
* Copy token and save to a file
* Export the path to the file in an environment variable
  * export OFFLINE_TOKEN_FILE=\<location\>

## Tests available

- [fbc](fbc/README.md)
- [fbc-stage-index](fbc-stage-index/README.md)
- [file-updates](file-updates/README.md)
