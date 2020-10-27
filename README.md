# The ALMA Keycloak implementation

The ALMA implementation of Keycloak is Docker-based.

The _Makefile_ sets up all configuratin information used by the _Dockerfile_,
which then builds the Keycloak container image. You may need to adapt the
Makefile to your local environment; the Dockerfile is very simple and is
hopefully general enough to require no modifications.

In addition to creating a container, several Docker commands were repackaged as `make` targets for convenience; see below.

## Makefile

### Basic usage

`make clean all` will stop and delete the current container and remove
any intermediate files, the rebuild the container.

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

Keycloak's configuration is stored in an Oracle database, as defined by the `archive.keycloak.xyz` properties in _archiveConfig.properties_.  
You can export that configuration from a server and import it into a different one.

Launch the Keycloak server with the configuration you want to copy,
then dump its configuration information to a set of JSON files:
```
make start
make dump-realms
```
This will produce three JSON files in the current directory, _adapt-realm.json_, _master-realm.json_ and _web-realm.json_. The most recent version of those files **should always be committed to Git** in this module.

Copy the dump JSON file where you created the destination server with
`make clean all` and make sure the `archive.keycloak.xyz` properties in
_$ACSDATA/config/_archiveConfig.properties_ point to the new server.
Assuming you haven't run this migration procedure before, you can simply start
the server and import all realm data into it:
```
make start
make configure
```

### Caveats

The following entities cannot be migrated automatically and must be re-instated manually:
* User providers (see User Federation)
* ???
