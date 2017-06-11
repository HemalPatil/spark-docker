# Dockerfile for greennav.io/persistence-layer
# Created by Hemal Patil 10 June 2017

FROM	ubuntu:latest
LABEL	maintainer "Hemal Patil, GreenNav"

USER	root

# Developer tools
RUN		apt-get update -y && \
		apt-get install software-properties-common curl tar sudo ssh openssh-server openssh-client rsync -y && \
		add-apt-repository ppa:webupd8team/java -y && \
		apt-get update -y

# Oracle Java 8 install
RUN		echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
		apt-get install -y oracle-java8-installer && \
		apt-get clean

# Passwordless SSH for Hadoop
RUN		ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
		ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
		ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
		cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# Hadoop 2.7.3
RUN		curl -s http://www-eu.apache.org/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz | tar -xz -C /usr/local
RUN		cd /usr/local && ln -s ./hadoop-2.7.3 hadoop

# Spark 2.1.0
RUN		curl -s http://www-eu.apache.org/dist/spark/common/spark-2.1.0/spark-2.1.0-bin-hadoop2.7.tgz | tar -xz -C /usr/local
RUN		cd /usr/local && ln -s ./spark-2.1.1-bin-hadoop2.7 spark

# Hadoop 2.7.3 native libraries for Ubuntu 16.04 LTS 64-bit
RUN		mkdir /tmp/native
RUN		curl -L https://github.com/HemalPatil/persistence-layer/releases/download/v2.7.3/hadoop2.7.3_ubuntu16_amd64_native.tar.gz | tar -xz -C /tmp/native
RUN		rm -rf /usr/local/hadoop/lib/native
RUN		mv /tmp/native /usr/local/hadoop/lib

# Psuedo distributed mode
ADD		core-site.xml /usr/local/hadoop/etc/hadoop/core-site.xml
ADD		hdfs-site.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml
ADD		yarn-site.xml /usr/local/hadoop/etc/hadoop/yarn-site.xml
ADD		mapred-site.xml /usr/local/hadoop/etc/hadoop/mapred-site.xml

# Enviroment variables
ENV		JAVA_HOME=/usr/lib/jvm/java-8-oracle \
		HADOOP_HOME=/usr/local/hadoop \
		HADOOP_COMMON_HOME=/usr/local/hadoop \
		HADOOP_HDFS_HOME=/usr/local/hadoop \
		HADOOP_MAPRED_HOME=/usr/local/hadoop \
		HADOOP_YARN_HOME=/usr/local/hadoop \
		HADOOP_PREFIX=/usr/local/hadoop \
		HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop \
		HADOOP_OPTS=-Djava.library.path=/usr/local/hadoop/lib/native \
		HADOOP_COMMON_LIB_NATIVE_DIR=/usr/local/hadoop/lib/native \
		YARN_CONF_DIR=/usr/local/hadoop/etc/hadoop \
		SPARK_HOME=/usr/local/spark \
		CLASSPATH=/usr/local/hadoop/share/hadoop/*:/usr/local/spark/jars/* \
		LD_LIBRARY_PATH=/usr/local/hadoop/lib/native

ENV		PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin

# Format HDFS namenode
RUN		service sshd start && \
		hdfs namenode -format

# Hadoop ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Spark ports
EXPOSE 4040
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
