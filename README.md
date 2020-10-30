# The ALMA Keycloak implementation

The ALMA implementation of Keycloak is Docker-based.

The _Makefile_ sets up all configuratin information used by the _Dockerfile_,
which then builds the Keycloak container image. You may need to adapt the
Makefile to your local environment; the Dockerfile is very simple and is
hopefully general enough to require no modifications.

In addition to creating a container, several Docker commands were repackaged as `make` targets for convenience; see below.

## Databases

This Keycloak container connects to two Oracle databases, one for storing its
configuration information and one for retrieving user data. Connection data is
copied _at container build time_ from the _archiveConfig.properties_ file on 
the build host to the container. 

That means, the build host must be configured to connect to those two databases,
even though no connection actually takes place during the container build phase.

* Keycloak's configuration is stored the database defined by properties 
  `archive.keycloak.connection`,  `archive.keycloak.user` and 
  `archive.keycloak.passwd`. The database does not contain much data but it
  includes 90+ tables, and it's highly recommended to make it a dedicated
  database. (See [here](https://htmlpreview.github.io/?https://gist.githubusercontent.com/thomasdarimont/b1c19da5e8df747b8596e6ddcda7e36f/raw/29309467f4ea07519cf614fd74943272e7d939f4/keycloak_db_overview_4.0.0.CR1-SNAPSHOT.svg) for a UML schema of that database).

* ALMA account data is read using the conventional  `archive.relational...` 
  properties.

See below for migrating Keycloak's config data from an Oracle server to another one.

## Makefile

### Basic usage

* `make clean all` will stop and delete the current container, remove 
  any intermediate files, then rebuild the container

* `make start` and `make stop` can be used to start and stop the container
  
* `make restart` stops the currently running container (if any) and starts a new one

* `make logs` will stream to the console the logs produced by a container launched with `make start`

Typical usage is `make restart logs`.

### Special cases

* `make bash` will open a bash session as user _root_ inside a container launched with `make start`

* `make image` will create a Docker image called _alma-keycloak_ from a running container 
  and save it to the current directory
  as a tar+gz file. The image will be tagged as _latest_ as well as with a timestamp, for instance
  _2020-10-28T10-18-47_. The file, called _alma-keycloak-&lt;hostname&gt;-&lt;timestamp&gt;.tar.gz_ can be copied
  elsewhere and the image can imported into Docker and run as a container. For instance:
  ```
  sudo docker load -i alma-keycloak-ma024088.ads.eso.org-2020-10-28T10-18-47.tar.gz
  sudo docker run -d -p 8080:8080 alma-keycloak
  ```
  **IMPORTANT** Images can only be saved form a running container: make sure Keycloak fully completes
  its startup process before you attempt saving the image. If not, your image may not work properly.

* `make configure` resterts the current container, then creates and populates the ALMA realm.  
  **NOTE** This can be performed only once because it expects an empty configuration database. If needed,
  the database can be emptied, see _Undoing a migration_ below.

### Customization

* You may want/need to change the definition of _LOCAL\_SHARED\_DIR_,
a local directory shared with the container. The directory must exist
before you launch the container.

* By default, Keycloak will be available on port 8080, change
variable _PORT_ if needed.

* If your local Maven repository is in a non-standard location you will need
to change the definition of _M2_.

* If you plan tp push container images to DockerHub you'll need to change
the definition of _DOCKERHUB\_USERNAME_.

## Migrating the configuration

Keycloak's configuration is stored in an Oracle database, as explained above.
You can export that configuration from a server and import it into a different one.

Launch the fully configured Keycloak server and dump its configuration 
information to a set of JSON files:
```
make start
make dump-realms
```
This will produce two JSON files in the current directory, _master-realm.json_ and _ALMA-realm.json_. The new version of those files **should always be committed to Git**.

Move the dump JSON files where you created the destination Keycloak server
(after making sure the `archive.keycloak` properties in
_$ACSDATA/config/_archiveConfig.properties_ point to the second Oracle server).
Assuming you haven't run this migration procedure before, you can simply start
the server and import all realm data into it:
```
make start
make configure
```
**NOTE** The following entities cannot be migrated automatically and must be re-instated manually:
* User providers (see User Federation)
  * Add _alma-user-provider_ to the list and make sure to set its _Cache Policy_ to 
    _NO_CACHE_ in _Cache Settings_

* **TBD**

### Undoing a migration

To undo a configuration migration you can simply delete all Keycloak's tables from the
destination database. Script _blast-keycloak-tables.sql_ in this module can help with
that.
