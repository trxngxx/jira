# Base image
FROM ubuntu:22.04

LABEL maintainer="vinataba <ngo.tran@seta-international.vn>" version="9.17.2"

ARG JIRA_VERSION=9.12.12
ARG JIRA_PRODUCT=jira-software
ARG AGENT_VERSION=1.3.3
ARG MYSQL_DRIVER_VERSION=8.0.22

ENV JIRA_USER=jira \
    JIRA_GROUP=jira \
    JIRA_HOME=/var/jira \
    JIRA_INSTALL=/opt/jira \
    JVM_MINIMUM_MEMORY=2g \
    JVM_MAXIMUM_MEMORY=16g \
    JVM_CODE_CACHE_ARGS="-XX:InitialCodeCacheSize=2g -XX:ReservedCodeCacheSize=4g" \
    AGENT_PATH=/var/agent \
    AGENT_FILENAME=atlassian-agent.jar

ENV JAVA_OPTS="-javaagent:${AGENT_PATH}/${AGENT_FILENAME} ${JAVA_OPTS}"

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${JIRA_INSTALL}" "${JIRA_HOME}" "${AGENT_PATH}" \
    && curl -o "${AGENT_PATH}/${AGENT_FILENAME}" "https://github.com/haxqer/jira/releases/download/v${AGENT_VERSION}/atlassian-agent.jar" -L \
    && curl -o /tmp/atlassian.tar.gz "https://product-downloads.atlassian.com/software/jira/downloads/atlassian-${JIRA_PRODUCT}-${JIRA_VERSION}.tar.gz" -L \
    && tar xzf /tmp/atlassian.tar.gz -C "${JIRA_INSTALL}/" --strip-components 1 \
    && rm -f /tmp/atlassian.tar.gz \
    && curl -o "${JIRA_INSTALL}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}.jar" "https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}.jar" -L \
    && echo "jira.home = ${JIRA_HOME}" > "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties"

RUN export CONTAINER_USER="$JIRA_USER" \
    && export CONTAINER_GROUP="$JIRA_GROUP" \
    && groupadd -r "$JIRA_GROUP" && useradd -r -g "$JIRA_GROUP" "$JIRA_USER" \
    && chown -R "$JIRA_USER:$JIRA_GROUP" "${JIRA_INSTALL}" "${JIRA_HOME}" "${AGENT_PATH}"

VOLUME "$JIRA_HOME"
USER "$JIRA_USER"
WORKDIR "$JIRA_INSTALL"
EXPOSE 8080

ENTRYPOINT ["/opt/jira/bin/start-jira.sh", "-fg"]
