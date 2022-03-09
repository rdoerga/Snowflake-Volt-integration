# Snowflake-Volt-integration
assets required to load data into Snowflake using Kafka

publishing into Snowflake using Kafka requires a few components to be setup:
1. kafka (create the connector properties file for Snowflake, download the Snowflake kafka connector jar file)
2. a stored procedure in Volt that publishes data onto the Kafka queue
3. a database and schema in Snowflake that hold the data
4. a role and user ID that allow kafka to connect to snowflake


step 1:
set up kafka and download the connector jar here: https://mvnrepository.com/artifact/org.bouncycastle/bc-fips/1.0.1
copy the jar file into the directory $KAFKA_HOME/libs

start zookeeper and kafka
start the standalone kafka connect, here is an example of a connector properties file:
name=voltkafkaconnectsnowflake
connector.class=com.snowflake.kafka.connector.SnowflakeSinkConnector
tasks.max=8
topics=voltdbexportVOLTTOPIC
buffer.count.records=10000
buffer.flush.time=60
buffer.size.bytes=5000000
snowflake.url.name=https://ts92461.eu-central-1.snowflakecomputing.com
snowflake.user.name=VOLTUSER
snowflake.private.key=<your key goes here>
snowflake.private.key.passphrase=<your passphrase goes here>
snowflake.database.name=VOLTACTIVEDATA
snowflake.schema.name=VOLTSCHEMA
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.storage.StringConverter
zookeeper.connect=localhost


step2:
create a stored procedure on the Volt side that will publish data onto the kafka queue

Couple of things to keep in mind:
the deployment.xml for Volt needs to contain something like:
   <export>
        <configuration target="test" enabled="true" type="kafka">
            <property name="bootstrap.servers">localhost:9092</property>
            <property name="topic.key">volttopic1.test</property>
            <property name="skipinternals">true</property>
        </configuration>
    </export>

create a stored procedure to publish from Volt onto the queue, like this for example:

create stream volttopic export to target test (
  name varchar(100) not null,
  telephone varchar(30) not null,
  email varchar(100)
);
this will publish onto the queue. The topicname for the example will show up as: voltdbexportVOLTTOPIC
this name must be referenced from the Kafka connector properties file (property: topics=voltdbexportVOLTTOPIC).


create procedure pub_personalia as insert into volttopic values ?,?,?;



the topic will show up on the kafka queue as: voltdbexportVOLTTOPIC

Step 3 and 4:
the commands to create a user, database and schema to receive and store data on the snowflake side:
--as SYSADMIN
create database VOLTACTIVEDATA;
use database VOLTACTIVEDATA;
create schema VOLTSCHEMA;

use role securityadmin;
grant usage on database VOLTACTIVEDATA to role kafka_connector_volt;
grant usage on schema VOLTACTIVEDATA.VOLTSCHEMA to role kafka_connector_volt;
grant create table on schema VOLTACTIVEDATA.VOLTSCHEMA to role kafka_connector_volt;
grant create stage on schema VOLTACTIVEDATA.VOLTSCHEMA to role kafka_connector_volt;
grant create pipe on schema VOLTACTIVEDATA.VOLTSCHEMA to role kafka_connector_volt;


grant role kafka_connector_volt to user VOLTUSER;

--as account admin
grant ownership on user VOLTUSER to role useradmin;
alter user VOLTUSER set default_role = kafka_connector_volt;

-- as security admin
grant all on warehouse COMPUTE_WH to role KAFKA_CONNECTOR_VOLT;
