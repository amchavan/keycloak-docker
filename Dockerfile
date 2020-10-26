FROM jboss/keycloak

# Download and copy the Oracle JDBC driver, see https://hub.docker.com/r/jboss/keycloak
ADD  --chown=jboss:root \ 
     https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc10/19.8.0.0/ojdbc10-19.8.0.0.jar \
     /opt/jboss/keycloak/modules/system/layers/base/com/oracle/jdbc/main/driver/ojdbc.jar

# Create default admin/admin user
COPY ./keycloak-add-default-admin-user.json      /opt/jboss/keycloak/standalone/configuration/keycloak-add-user.json

# Add ALMA UI theme
COPY ./keycloak-alma-theme-11.0.2.jar            /opt/jboss/keycloak/standalone/deployments/

# Add ALMA/Oracle user storage provider module
COPY ./keycloak-user-storage-provider-11.0.2.ear /opt/jboss/keycloak/standalone/deployments/

# Oracle environment variables, with default values (ARG): pass actual values on the
# command line with the --build-arg option of docker build

ARG hostname=ora12c2.hq.eso.org
ARG username=alma_amchavan
ARG password='alma_amchavan$$dba'
ARG database=ALMA

ENV DB_VENDOR=oracle
ENV DB_PORT=1521
ENV DB_ADDR=$hostname
ENV DB_USER=$username
ENV DB_PASSWORD=$password
ENV DB_DATABASE=$database
