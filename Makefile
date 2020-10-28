# amchavan, 23-Oct-2020
# --------------------------------------------------------

SHELL := /bin/bash

# The name of our ALMA/Keycloak container
ALMAKC = alma-keycloak

# Execution path to the kcadm.sh script, from outside the container
KCADM = sudo docker exec -u 0 -it `cat $(CIDFILE)` /opt/jboss/keycloak/bin/kcadm.sh

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
CIDFILE = $(ALMAKC).cid

# Where Docker writes the image ID upon commit
IIDFILE = $(ALMAKC).iid

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

# Build the container
build:
	sudo docker build \
		--build-arg hostname=$(HOSTNAME) \
		--build-arg port_num=$(PORT_NUM) \
		--build-arg username=$(USERNAME) \
		--build-arg password='$(PASSWORD)' \
		--build-arg database=$(DATABASE) \
		-t $(ALMAKC) .

# KEEP THIS
#	-v $(LOCAL_DATA_DIR):/opt/jboss/keycloak/standalone/data 

start: $(LOCAL_SHARED_DIR) $(LOCAL_DATA_DIR)
	sudo docker run --detach \
		-p $(PORT):8080 \
		-v $(LOCAL_SHARED_DIR):$(CONTAINER_SHARED_DIR) \
		--cidfile="$(CIDFILE)" \
		$(ALMAKC)

stop:
	- sudo docker stop `cat $(CIDFILE)` 2> /dev/null
	rm -f $(CIDFILE)

# Show container logs on the console
logs:
	sudo docker logs `cat $(CIDFILE)` -f

# Open a bash session in the container
bash:
	sudo docker exec -u 0 -it `cat $(CIDFILE)` bash

# Save a running container as an image to a disk file. The image will be called $(ALMAKC)
# and will be tagged as 'latest', as well as with the current datetime; for instance, 
# alma-keycloak:2020-10-28T09-31-51
# It will be tagged as 'latest' as well.
# The risulting file will be in tar+gzip format and include the 'latest' tag.
DATETIME_TAG := $(shell date -u +%FT%T | tr : -)
image:
	sudo docker commit --author $$USER `cat $(CIDFILE)` $(ALMAKC):latest | cut -d: -f2 > $(IIDFILE)
	sudo docker tag `cat $(IIDFILE)` $(ALMAKC):$(DATETIME_TAG)
	sudo docker save $(ALMAKC):latest $(ALMAKC):$(DATETIME_TAG) | gzip > $(ALMAKC)-$(DATETIME_TAG).tar.gz

# -------------------------------------------------------------------------
# Migrate the Keycloak database
# -------------------------------------------------------------------------

authenticate:
	$(KCADM) config credentials \
		--server   http://localhost:8080/auth \
		--realm    master \
		--user     $(ADMIN_USERNAME) \
		--password $(ADMIN_PASSWORD)

create-realms: authenticate
	$(KCADM) create realms -s realm=web   -s enabled=true
	$(KCADM) create realms -s realm=adapt -s enabled=true

update-realms: authenticate
	cp -p ./web-realm.json ./adapt-realm.json ./master-realm.json $(LOCAL_SHARED_DIR)
	$(KCADM) update realms/master -f $(CONTAINER_SHARED_DIR)/master-realm.json
	$(KCADM) update realms/web	  -f $(CONTAINER_SHARED_DIR)/web-realm.json
	$(KCADM) update realms/adapt  -f $(CONTAINER_SHARED_DIR)/adapt-realm.json

# Update the default realm definitions with the current contents of the Keycloak DB
# Use as: make dump-realm REALM=<realm>
DUMPFILE := ./$(REALM)-realm.json
dump-realm: authenticate
	$(KCADM) get realms/$(REALM) > $(DUMPFILE)

dump-realms:
	make dump-realm REALM=master
	make dump-realm REALM=adapt
	make dump-realm REALM=web

wait:
	sleep 30

# Configure a running image with the default contents
configure: stop start wait authenticate create-realms update-realms

test:
	echo $(PORT_NUM) $(HOSTNAME) $(DATABASE) $(USERNAME) '$(PASSWORD)' $(DATABASE)
