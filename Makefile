# --------------------------------------------------------
# amchavan, 23-Oct-2020
# --------------------------------------------------------

SHELL := /bin/bash

# The name of our ALMA/Keycloak container
ALMAKC = alma-keycloak

# Execution path to the kcadm.sh script, from outside the container
KCADM = sudo docker exec -u 0 -it $$(cat $(CIDFILE)) /opt/jboss/keycloak/bin/kcadm.sh

# Admin user credentials -- for installation only
# Values should match the contents of keycloak-add-default-admin-user.json
# Change the password when deploying in production! (Use the Web admin UI)
ADMIN_USERNAME = admin
ADMIN_PASSWORD = admin

# KEEP THIS
# This local directory will be mapped to the container's data directory, where
# all the server's data (realms, users, etc.) is persisted.  
# It must be created before launching the container
LOCAL_DATA_DIR = /tmp/keycloak/data

# These directories will be mapped to each other, allowing
# us to exchange files with the Keycloak instance inside the container.
# LOCAL_SHARED_DIR must be created before launching the container
LOCAL_SHARED_DIR = /tmp/keycloak/shared
CONTAINER_SHARED_DIR = /shared

# Used to dump a realm's data to a JSON file, defaults to 'ALMA'
# Use as:
#    make dump-realm REALM=<realm-name> 
REALM = ALMA

# Where Docker writes the Container ID upon startup
CIDFILE = $(LOCAL_SHARED_DIR)/$(ALMAKC).cid

# Where Docker writes the image ID upon commit
IIDFILE = $(LOCAL_SHARED_DIR)/$(ALMAKC).iid

# Local Maven repository
M2 = $(HOME)/.m2

# Keycloak will be accessible on this port
PORT = 8080

# For pushing images to Docker Hub
DOCKERHUB_USERNAME=amchavan

# Trick!
# We need to extract Oracle connection information from the standard
# ALMA Archive configuration properties file and pass them to 'docker build':
# We use a bash script to parse that file and write a set of Make assignement
# statements in a temp file, which we then include here
TEMP_INCLUDE_FILE=./parse-archive-config.mk
IGNORE := $(shell bash -c "./parse-archive-config.sh > $(TEMP_INCLUDE_FILE)")                         
include $(TEMP_INCLUDE_FILE)

clean: stop
	rm -f ./keycloak-alma-theme*.jar ./keycloak-user-storage-provider*.ear \
		$(TEMP_INCLUDE_FILE) $(ALMAKC)-*.tar.gz $(CIDFILE) $(IIDFILE) \
		archiveConfig.properties

all: add-external-files build

add-external-files:
	cp -p $(M2)/repository/alma/obops/keycloak/keycloak-alma-theme/11.0.2/keycloak-alma-theme-11.0.2.jar \
	      $(M2)/repository/alma/obops/keycloak/keycloak-user-storage-provider/11.0.2/keycloak-user-storage-provider-11.0.2.ear \
		  $(ACSDATA)/config/archiveConfig.properties \
		  .

# Build the containers: the regular one and the more limited one for importing and 
# exporting of the database
build:
	sudo docker build \
		--build-arg hostname=$(HOSTNAME) \
		--build-arg port_num=$(PORT_NUM) \
		--build-arg username=$(USERNAME) \
		--build-arg password='$(PASSWORD)' \
		--build-arg database=$(DATABASE) \
		-t $(ALMAKC) .
	sudo docker build -f Dockerfile.import-export \
		--build-arg hostname=$(HOSTNAME) \
		--build-arg port_num=$(PORT_NUM) \
		--build-arg username=$(USERNAME) \
		--build-arg password='$(PASSWORD)' \
		--build-arg database=$(DATABASE) \
		-t $(ALMAKC)-import-export .

restart: stop start

# KEEP THIS
#	-v $(LOCAL_DATA_DIR):/opt/jboss/keycloak/standalone/data 

start: $(LOCAL_SHARED_DIR)
	sudo docker run --detach \
		-p $(PORT):8080 \
		-v $(LOCAL_SHARED_DIR):$(CONTAINER_SHARED_DIR) \
		$(ALMAKC) \
		> $(CIDFILE)

stop: 
	@if [ -e $(CIDFILE) ] ; then \
		sudo docker stop $$(cat $(CIDFILE)) > /dev/null ; \
		rm -f $(CIDFILE); \
	fi
	

# Show container logs on the console
logs:
	sudo docker logs $$(cat $(CIDFILE)) -f

# Open a bash session in the container
bash:
	sudo docker exec -u 0 -it $$(cat $(CIDFILE)) bash

# Save a running container as an image to a disk file. The image will be called $(ALMAKC)
# and will be tagged as 'latest', as well as with the current datetime; for instance, 
# alma-keycloak:2020-10-28T09-31-51
# It will be tagged as 'latest' as well.
# The risulting file will be in tar+gzip format and include the 'latest' tag.
DATETIME_TAG := $(shell date -u +%FT%T | tr : -)
HOST := $(shell hostname)
image:
	sudo docker commit --author $$USER $$(cat $(CIDFILE)) $(ALMAKC):latest | cut -d: -f2 > $(IIDFILE)
	sudo docker tag `cat $(IIDFILE)` $(ALMAKC):$(DATETIME_TAG)
	sudo docker save $(ALMAKC):latest $(ALMAKC):$(DATETIME_TAG) | gzip > $(ALMAKC)-$(HOST)-$(DATETIME_TAG).tar.gz

# -------------------------------------------------------------------------
# Migrate the Keycloak database
# -------------------------------------------------------------------------

authenticate:
	$(KCADM) config credentials \
		--server   http://localhost:8080/auth \
		--realm    master \
		--user     $(ADMIN_USERNAME) \
		--password $(ADMIN_PASSWORD)

# # Update the default realm definitions with the current contents of the Keycloak DB
# # Use as: make dump-realm REALM=<realm>
# DUMPFILE := ./realm-$(REALM).json
# dump-realm: authenticate
# 	$(KCADM) get realms/$(REALM) > $(DUMPFILE)

# dump-realms:
# 	make dump-realm REALM=master
# 	make dump-realm REALM=ALMA

database-export-internal:
	sudo docker run --detach \
		-v $(PWD):$(CONTAINER_SHARED_DIR) \
		$(ALMAKC)-import-export \
		-Dkeycloak.migration.action=export \
		-Dkeycloak.migration.provider=singleFile \
		-Dkeycloak.migration.file=$(CONTAINER_SHARED_DIR)/keycloak-db-dump.json \
		-Dkeycloak.migration.usersExportStrategy=SKIP \
		> $(CIDFILE)

database-export: stop database-export-internal 
	sleep 120
	make stop

database-import-internal:
	sudo docker run --detach \
		-v $(PWD):$(CONTAINER_SHARED_DIR) \
		$(ALMAKC)-import-export \
		-Dkeycloak.migration.action=import \
		-Dkeycloak.migration.provider=singleFile \
		-Dkeycloak.migration.file=$(CONTAINER_SHARED_DIR)/keycloak-db-dump.json \
		-Dkeycloak.migration.strategy=OVERWRITE_EXISTING \
		> $(CIDFILE)

database-import: stop database-import-internal 
	sleep 120
	make stop