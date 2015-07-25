# BOSH Deployment Resource

An output only resource (at the moment) that will upload stemcells and releases
and then deploy them.

## Source Configuration

* `target`: *Required.* The address of the BOSH director which will be used for
  deployment.
* `username`: *Required.* The username for the BOSH director.
* `password`: *Required.* The password for the BOSH director.
* `deployment`: *Required.* The name of the deployment.

## Behaviour

### `out`: Deploy a BOSH deployment

This will upload any given stemcells and releases, lock them down in the
deployment manifest and then deploy.

If the manifest does not specify a `director_uuid`, it will be filled in with
the UUID returned by the targeted director.

#### Parameters

* `manifest`: *Required.* Path to a BOSH deployment manifest file.
* `stemcells`: *Required.*  An array of globs that should point to where the
  stemcells used in the deployment can be found.
* `releases`: *Required.* An array of globs that should point to where the
  releases used in the deployment can be found.
