FROM jboss/keycloak

COPY ./keycloak-add-default-admin-user.json      /opt/jboss/keycloak/standalone/configuration/keycloak-add-user.json
COPY ./keycloak-alma-theme-11.0.2.jar            /opt/jboss/keycloak/standalone/deployments/
COPY ./keycloak-user-storage-provider-11.0.2.ear /opt/jboss/keycloak/standalone/deployments/
ADD  --chown=jboss ./keycloak-data.tgz           /opt/jboss/keycloak/standalone/