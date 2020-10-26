FROM jboss/keycloak

# Download and copy the Oracle JDBC driver, see https://hub.docker.com/r/jboss/keycloak
ADD  --chown=jboss:root \ 
     https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc10/19.8.0.0/ojdbc10-19.8.0.0.jar \
     /opt/jboss/keycloak/modules/system/layers/base/com/oracle/jdbc/main/driver/ojdbc.jar

# COPY  standalone.xml                             /opt/jboss/keycloak/standalone/configuration
COPY ./keycloak-add-default-admin-user.json      /opt/jboss/keycloak/standalone/configuration/keycloak-add-user.json
COPY ./keycloak-alma-theme-11.0.2.jar            /opt/jboss/keycloak/standalone/deployments/
COPY ./keycloak-user-storage-provider-11.0.2.ear /opt/jboss/keycloak/standalone/deployments/
# ADD  --chown=jboss ./keycloak-data.tgz           /opt/jboss/keycloak/standalone/