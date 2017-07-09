FROM insurit/payara-confdb
ADD ./target/sql_exporter.war ${DEPLOYMENT_DIR}
