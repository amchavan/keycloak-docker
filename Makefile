# amchavan, 23-Oct-2020
# --------------------------------------------------------

# The name of our ALMA/Keycloak container
ALMAKC = alma-keycloak

# Execution path to the kcadm.sh script from outside the container
KCADM = docker exec -u 0 -it `cat $(CIDFILE)` /opt/jboss/keycloak/bin/kcadm.sh

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
CIDFILE = /tmp/$(ALMAKC).cid

# Local Maven repository
M2 = $(HOME)/.m2

# Keycloak will be accessible on this port
PORT = 8080

# For pushing images to Docker Hub
DOCKERHUB_USERNAME=amchavan


clean: stop
	rm -f ./keycloak-alma-theme*.jar ./keycloak-user-storage-provider*.ear 

all: add-modules build

add-modules:
	cp -p $(M2)/repository/alma/obops/keycloak/keycloak-alma-theme/11.0.2/keycloak-alma-theme-11.0.2.jar \
	      $(M2)/repository/alma/obops/keycloak/keycloak-user-storage-provider/11.0.2/keycloak-user-storage-provider-11.0.2.ear \
		  .

build:
	docker build -t $(ALMAKC) .


# KEEP THIS
#	-v $(LOCAL_DATA_DIR):/opt/jboss/keycloak/standalone/data 

start: $(LOCAL_SHARED_DIR) $(LOCAL_DATA_DIR)
	docker run --detach \
		-p $(PORT):8080 \
		-v $(LOCAL_SHARED_DIR):$(CONTAINER_SHARED_DIR) \
		--cidfile="$(CIDFILE)" \
		$(ALMAKC)

stop:
	- docker stop `cat $(CIDFILE)` 2> /dev/null
	rm -f $(CIDFILE)


# -------------------------------------------------------------------------
# Docker stuff follows
# -------------------------------------------------------------------------

# Tag an image and push it to Docker hub
# Use as:
#    echo <dockerhub-password> | make push OLDTAG=1.0 NEWTAG=1.1
TAG = 0.1
push:
	docker login --username $(DOCKERHUB_USERNAME) --password-stdin
	docker tag $(DOCKERHUB_USERNAME)/$(ALMAKC):$(OLDTAG) $(DOCKERHUB_USERNAME)/$(ALMAKC):$(NEWTAG)
	docker push $(DOCKERHUB_USERNAME)/$(ALMAKC):$(NEWTAG)

# -------------------------------------------------------------------------
# Experimental stuff follows
# -------------------------------------------------------------------------

authenticate:
	$(KCADM) config credentials \
		--server   http://localhost:8080/auth \
		--realm    master \
		--user     $(ADMIN_USERNAME) \
		--password $(ADMIN_PASSWORD)
	
create-realms: authenticate
	$(KCADM) create realms -s realm=ALMA       -s enabled=true
	$(KCADM) create realms -s realm=ALMA-ADAPT -s enabled=true
	
update-realms: create-realms
	cp -p ./ALMA-realm.json ./ALMA-ADAPT-realm.json ./master-realm.json $(LOCAL_SHARED_DIR)
	$(KCADM) update realms/master 	  -f $(CONTAINER_SHARED_DIR)/master-realm.json
	$(KCADM) update realms/ALMA 	  -f $(CONTAINER_SHARED_DIR)/ALMA-realm.json
	$(KCADM) update realms/ALMA-ADAPT -f $(CONTAINER_SHARED_DIR)/ALMA-ADAPT-realm.json

DUMPFILE = ./$(REALM)-realm.json.DUMP
dump-realm:
	$(KCADM) get realms/$(REALM) > $(DUMPFILE)

wait:
	sleep 30

# An alternative way to configure a running image
alt-configure: stop start wait authenticate create-realms update-realms

# 