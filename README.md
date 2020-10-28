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
  database.

* ALMA account data is read using the conventional  `archive.relational...` 
  properties.

See below for migrating Keycloak's config data from an Oracle server to another one.

## Makefile

### Basic usage

`make clean all` will stop and delete the current container, remove
any intermediate files, then rebuild the container.

`make start` and `make stop` can be used to start and stop the container.

### Special cases

* ??? `make push OLDTAG=... NEWTAG=...` will push the image to DockerHub with a new tag;
see _DOCKERHUB\_USERNAME_ below for more info.

* `make bash` will open a bash session as user _root_ inside a container launched with `make start`

* `make logs` will stream to the console the logs produced by a container launched with `make start`

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
This will produce three JSON files in the current directory, _adapt-realm.json_, _master-realm.json_ and _web-realm.json_. The most recent version of those files **should always be committed to Git** in this module.

Move the dump JSON files where you created the destination Keycloak server
(after making sure the `archive.keycloak` properties in
_$ACSDATA/config/_archiveConfig.properties_ point to the second Oracle server).
Assuming you haven't run this migration procedure before, you can simply start
the server and import all realm data into it:
```
make start
make configure
```
See below for undoing a migration.

### Caveats

The following entities cannot be migrated automatically and must be re-instated manually:
* User providers (see User Federation): set that to _alma-user-provider_
* **TBD**

### Undoing a migration

To undo a configuration migration you can simply delete all Keycloak's tables from the
destination database. Script _blast-keycloak-tables.sql_ in this module can help with
that.
