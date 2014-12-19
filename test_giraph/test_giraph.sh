#!/bin/bash -x

GIRAPH_HOME=/opt/giraph/
giraph_version=1.1.0
user_name=alti-test-01
test_hdfs_dir=/user/$user_name/test_giraph/

hadoop_classpath=$HADOOP_CLASSPATH

for j in `find $GIRAPH_HOME -type f -name "*.jar" | sort`
do
  hadoop_classpath=$hadoop_classpath:$j
done

for j in `find $GIRAPH_HOME -type f -name "*.jar" | sort`
do
  hadoop_libjars=$hadoop_libjars,$j
done

hdfs dfs -mkdir -p $test_hdfs_dir/test0/
hdfs dfs -put $GIRAPH_HOME/test_giraph/tiny_graph.txt $test_hdfs_dir/test0/

echo $hadoop_classpath
tmp_hadoop_classpath=$HADOOP_CLASSPATH
export HADOOP_CLASSPATH=$hadoop_classpath

# Test Case 0

# $HADOOP_HOME/bin/hadoop jar $GIRAPH_HOME/giraph-core-${giraph_version}.jar org.apache.giraph.GiraphRunner -libjars $hadoop_libjars org.apache.giraph.examples.SimpleShortestPathsComputation -vif org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat -vip $test_hdfs_dir/test0/tiny_graph.txt -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat -op $test_hdfs_dir/test0/shortestpaths -yj $hadoop_libjars -w 1
$GIRAPH_HOME/bin/giraph $GIRAPH_HOME/giraph-examples-${giraph_version}.jar org.apache.giraph.examples.SimpleShortestPathsComputation -vif org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat -vip $test_hdfs_dir/test0/tiny_graph.txt -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat  -op $test_hdfs_dir/test0/shortestpaths -yj $hadoop_libjars -w 1

# Add other test case if applicable

export HADOOP_CLASSPATH=$tmp_hadoop_classpath
