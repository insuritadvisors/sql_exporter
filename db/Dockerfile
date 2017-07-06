FROM insurit/payara
MAINTAINER Vasilis Stergioulis
ADD ojdbc7.jar ${PAYARA_HOME}/domains/${DOMAIN_NAME}/lib/ext
ENV PAYARA_JDBC_NAME jdbc/somedb
ENV PAYARA_DB_URL "user=hr:password=hr:url='jdbc:oracle:thin:@localhost:1521:XE'"
RUN asadmin start-domain ${DOMAIN_NAME} && \
asadmin create-jdbc-connection-pool \
--datasourceclassname=oracle.jdbc.pool.OracleDataSource \
--restype=javax.sql.DataSource \
--poolresize 1 \
--validationmethod auto-commit \
--failconnection=true \
--leakreclaim=true \
--leaktimeout 60 \
--statementleakreclaim=true \
--statementleaktimeout 60 \
--statementtimeout 60 \
--steadypoolsize 2 \
--idletimeout 30 \
--isconnectvalidatereq=true \
--property=${PAYARA_DB_URL} \
mydbpool && \
asadmin create-jdbc-resource --connectionpoolid mydbpool ${PAYARA_JDBC_NAME} && asadmin stop-domain ${DOMAIN_NAME}
