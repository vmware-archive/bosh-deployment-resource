# BOSH Deployment Resource

An output only resource (at the moment) that will upload stemcells and releases
and then deploy them.

## Source Configuration

* `target`: *Required.* The address of the BOSH director which will be used for
  deployment.
* `username`: *Required.* The username for the BOSH director.
* `password`: *Required.* The password for the BOSH director.

## Behaviour

### `out`: Deploy a BOSH deployment

This will upload any given stemcells and releases, lock them down in the
deployment manifest and then deploy.

#### Parameters

* `manifest`: *Required.* Path to a BOSH deployment manifest file.
* `stemcells`: *Required.*  An array of globs that should point to where the
  stemcells used in the deployment can be found.
* `releases`: *Required.* An array of globs that should point to where the
  releases used in the deployment can be found.
* `rebase`: *Optional.* A boolean specifying whether or not the releases should
  be rebased upon upload.
