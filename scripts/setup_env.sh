#!/bin/bash

# TBD: honor system pre-defined property/variable files from 
# /etc/hadoop/ and other /etc config for giraph, hdfs, hadoop, etc

if [ "x${JAVA_HOME}" = "x" ] ; then
  export JAVA_HOME=/usr/java/default
fi
if [ "x${ANT_HOME}" = "x" ] ; then
  export ANT_HOME=/opt/apache-ant
fi
if [ "x${MAVEN_HOME}" = "x" ] ; then
  export MAVEN_HOME=/opt/apache-maven
fi
if [ "x${M2_HOME}" = "x" ] ; then
  export M2_HOME=/opt/apache-maven
fi
if [ "x${MAVEN_OPTS}" = "x" ] ; then
  export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"
fi
if [ "x${HADOOP_VERSION}" = "x" ] ; then
  export HADOOP_VERSION=2.4.1
fi
if [ "x${HIVE_VERSION}" = "x" ] ; then
  export HIVE_VERSION=0.13.1
fi

export PATH=$PATH:$M2_HOME/bin:$SCALA_HOME/bin:$ANT_HOME/bin:$JAVA_HOME/bin

# Define defau;t giraph uid:gid and build version
if [ "x${GIRAPH_USER}" = "x" ] ; then
  export GIRAPH_USER=giraph
fi
if [ "x${GIRAPH_VERSION}" = "x" ] ; then
  export GIRAPH_VERSION=1.1.0
fi
if [ "x${GIRAPH_PLAINVERSION}" = "x" ] ; then
  export GIRAPH_PLAINVERSION=$GIRAPH_VERSION
fi

if [ "x${HADOOP_VERSION}" = "x2.2.0" ] ; then
  export GIRAPH_VERSION="$GIRAPH_VERSION.hadoop22"
elif [ "x${HADOOP_VERSION}" = "x2.4.0" ] ; then
  export GIRAPH_VERSION="$GIRAPH_VERSION.hadoop24"
elif [ "x${HADOOP_VERSION}" = "x2.4.1" ] ; then
  export GIRAPH_VERSION="$GIRAPH_VERSION.hadoop24"
else
  echo "error - can't recognize altiscale's HADOOP_VERSION=$HADOOP_VERSION"
fi

if [ "x${HIVE_VERSION}" = "x0.12.0" ] ; then
  export GIRAPH_VERSION="$GIRAPH_VERSION.hive12"
elif [ "x${HIVE_VERSION}" = "x0.13.0" ] ; then
  export GIRAPH_VERSION="$GIRAPH_VERSION.hive13"
elif [ "x${HIVE_VERSION}" = "x0.13.1" ] ; then
  export GIRAPH_VERSION="$GIRAPH_VERSION.hive13"
else
  echo "error - can't recognize altiscale's HIVE_VERSION=$HIVE_VERSION"
fi

if [ "x${ALTISCALE_RELEASE}" = "x" ] ; then
  if [ "x${HADOOP_VERSION}" = "x2.2.0" ] ; then
    export ALTISCALE_RELEASE=2.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.4.0" ] ; then
    export ALTISCALE_RELEASE=3.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.4.1" ] ; then
    export ALTISCALE_RELEASE=3.0.0
  else
    echo "error - can't recognize altiscale's HADOOP_VERSION=$HADOOP_VERSION for ALTISCALE_RELEASE"
  fi 
else
  export ALTISCALE_RELEASE
fi 

if [ "x${BRANCH_NAME}" = "x" ] ; then
  export BRANCH_NAME=altiscale-${ALTISCALE_RELEASE}-release-1.1
fi

if [ "x${BUILD_TIMEOUT}" = "x" ] ; then
  export BUILD_TIMEOUT=14400
fi

BUILD_TIME=$(date +%Y%m%d%H%M)
export BUILD_TIME

# Customize build OPTS for MVN
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"




