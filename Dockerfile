# Dockerfile for greennav.io/persistence-layer
# Created by Hemal Patil 10 June 2017

FROM	ubuntu:latest
LABEL	maintainer "Hemal Patil, GreenNav"

USER	root

# Developer tools
RUN		apt-get update -y && \
		apt-get install curl tar sudo ssh openssh-server openssh-client rsync -y

# Oracle Java 8 install
RUN		curl -LO http://download.oracle.com/otn-pub/java/jdk/8u131-b11/jdk-8u131-linux-x64.tar.gz -H 'Cookie: oraclelicense=accept-securebackup-cookie'
RUN		mkdir /usr/local/jdk && tar -zvf jdk-8u131-linux-x64.tar.gz -C /usr/local/jdk
RUN		update-alternatives --install /usr/bin/java java /usr/local/jdk/jdk1.8.0_131/bin/java 10
RUN		update-alternatives --install /usr/bin/javac javac /usr/local/jdk/jdk1.8.0_131/bin/javac 10
RUN		rm jdk-8u131-linux-x64.tar.gz

# Passwordless SSH for Hadoop
RUN		ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
		ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
		ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
		cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# Hadoop 2.7.3
# Mirror for India, change as per needs
RUN		curl -s http://mirror.fibergrid.in/apache/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz | tar -xz -C /usr/local
RUN		cd /usr/local && ln -s ./hadoop-2.7.3 hadoop

# Spark 2.1.0
# Mirror for India, change as per needs
RUN		curl -s http://redrockdigimark.com/apachemirror/spark/spark-2.1.1/spark-2.1.1-bin-hadoop2.7.tgz | tar -xz -C /usr/local
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
ENV		JAVA_HOME=/usr/local/jdk/jdk1.8.0_131 \
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
