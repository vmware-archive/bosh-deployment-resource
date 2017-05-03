# BOSH Deployment Resource

An output only resource (at the moment) that will upload stemcells and releases
and then deploy them.

## Source Configuration

* `deployment`: *Required.* The name of the deployment.
* `target`: *Optional.* The address of the BOSH director which will be used for
  the deployment. If omitted, `target_file` must be specified via `out`
  parameters, as documented below.

When using BOSH with default authentication:
* `username`: *Required.* The username for the BOSH director.
* `password`: *Required.* The password for the BOSH director.

When using BOSH with [UAA authentication](https://bosh.io/docs/director-users-uaa.html#client-login):
* `client_id`: *Required.* The UAA client ID for the BOSH director.
* `client_secret`: *Required.* The UAA client secret for the BOSH director.

* `ca_cert`: *Optional.* CA certificate used to validate SSL connections to Director and UAA.

### Example

``` yaml
- name: staging
  type: bosh-deployment
  source:
    target: https://bosh.example.com:25555
    username: admin
    password: admin
    deployment: staging-deployment-name
```

``` yaml
- put: staging
  params:
    manifest: path/to/manifest.yml
    stemcells:
    - path/to/stemcells-*.tgz
    - other/path/to/stemcells-*.tgz
    releases:
    - path/to/releases-*.tgz
    - other/path/to/releases-*.tgz
```

## Behaviour

### `out`: Deploy a BOSH deployment

This will upload any given stemcells and releases, lock them down in the
deployment manifest and then deploy.

If the manifest does not specify a `director_uuid`, it will be filled in with
the UUID returned by the targeted director.

#### Parameters

* `manifest`: *Required.* Path to a BOSH deployment manifest file.

* `stemcells`: *Required.* An array of globs that should point to where the
  stemcells used in the deployment can be found. Stemcell entries in the
  manifest with version 'latest' will be updated to the actual provided
  stemcell versions.

* `releases`: *Required.* An array of globs that should point to where the
  releases used in the deployment can be found. Release entries in the
  manifest will be updated to the actual provided release versions.

* `no_version_update`: *Optional* This flag avoids that the manifest is modified to use the stemcell or bosh releases provided as blobs.  Defaults set to false.

* `cleanup`: *Optional* An boolean that specifies if a bosh cleanup should be
  run before deployment. Defaults to false.
* `no_redact`: *Optional* Removes redacted from Bosh output. Defaults to false.
* `target_file`: *Optional.* Path to a file containing a BOSH director address.
  This allows the target to be determined at runtime, e.g. by acquiring a BOSH
  lite instance using the [Pool
  resource](https://github.com/concourse/pool-resource).

  If both `target_file` and `target` are specified, `target_file` takes
  precedence.
