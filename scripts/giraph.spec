%global apache_name            GIRAPH_USER
%global giraph_uid             GIRAPH_UID
%global giraph_gid             GIRAPH_GID

%define altiscale_release_ver  ALTISCALE_RELEASE
%define rpm_package_name       alti-giraph
%define giraph_version         GIRAPH_VERSION_REPLACE
%define hadoop_version         HADOOP_VERSION_REPLACE
%define hive_version           HIVE_VERSION_REPLACE
%define build_service_name     alti-giraph
%define giraph_folder_name     %{rpm_package_name}-%{giraph_version}
%define giraph_testsuite_name  %{giraph_folder_name}
%define install_giraph_dest    /opt/%{giraph_folder_name}
%define install_giraph_conf    /etc/%{giraph_folder_name}
%define install_giraph_logs    /var/log/%{apache_name}
%define install_giraph_test    /opt/%{giraph_testsuite_name}/test_giraph
%define build_release          BUILD_TIME

Name: %{rpm_package_name}-%{giraph_version}
Summary: %{giraph_folder_name} RPM Installer AE-927, cluster mode restricted with warnings
Version: %{giraph_version}
Release: %{altiscale_release_ver}.%{build_release}%{?dist}
License: ASL 2.0
Group: Development/Libraries
Source: %{_sourcedir}/%{build_service_name}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{release}-root-%{build_service_name}
Requires(pre): shadow-utils
# Requires: %{rpm_package_name}-%{giraph_version}-test
BuildRequires: apache-maven >= 3.2.1
BuildRequires: jdk >= 1.7.0.51
Url: http://giraph.apache.org/
%description
Build from https://github.com/Altiscale/giraph/tree/altiscale-release-1.1 with 
build script https://github.com/Altiscale/giraphbuild/tree/altiscale-release-1.1 
Origin source form https://github.com/apache/giraph/tree/release-1.1
%{giraph_folder_name} is a re-compiled and packaged giraph distro that is compiled against Altiscale's 
Hadoop 2.4.x with YARN 2.4.x enabled. This package should work with Altiscale Hadoop 2.4.1 (vcc-hadoop-2.4.1).

%package test
Summary: The test package for Giraph
Group: Development/Libraries

%description test
The test directory to test Giraph libraries after installing giraph.

%pre
# Soft creation for giraph user if it doesn't exist. This behavior is idempotence to Chef deployment.
# Should be harmless. MAKE SURE UID and GID is correct FIRST!!!!!!
getent group %{apache_name} >/dev/null || groupadd -f -g %{giraph_gid} -r %{apache_name}
if ! getent passwd %{apache_name} >/dev/null ; then
    if ! getent passwd %{giraph_uid} >/dev/null ; then
      useradd -r -u %{giraph_uid} -g %{apache_name} -c "Soft creation of user and group of giraph for manual deployment" %{apache_name}
    else
      useradd -r -g %{apache_name} -c "Soft adding user giraph to group giraph for manual deployment" %{apache_name}
    fi
fi

%prep
# copying files into BUILD/giraph/ e.g. BUILD/giraph/* 
# echo "ok - copying files from %{_sourcedir} to folder  %{_builddir}/%{build_service_name}"
# cp -r %{_sourcedir}/%{build_service_name} %{_builddir}/

# %patch1 -p0

%setup -q -n %{build_service_name}

%build
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"

echo "build - giraph core in %{_builddir}"
pushd `pwd`
cd %{_builddir}/%{build_service_name}/

if [ "x%{hadoop_version}" = "x" ] ; then
  echo "fatal - HADOOP_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export GIRAPH_HADOOP_VERSION=%{hadoop_version}
  echo "ok - applying customized hadoop version $GIRAPH_HADOOP_VERSION"
fi

if [ "x%{hive_version}" = "x" ] ; then
  echo "fatal - HIVE_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export GIRAPH_HIVE_VERSION=%{hive_version}
  echo "ok - applying customized hive version $GIRAPH_HIVE_VERSION"
fi

env | sort

echo "ok - building giraph"
########################
# BUILD ENTIRE PACKAGE #
########################
# This will build the overall JARs we need in each folder
# and install them locally for further reference. We assume the build
# environment is clean, so we don't need to delete ~/.ivy2 and ~/.m2
if [ -f /etc/alti-maven-settings/settings.xml ] ; then
  echo "ok - applying local maven repo settings.xml for first priority"
  if [[ $GIRAPH_HADOOP_VERSION == 2.2.* ]] ; then
    mvn -U -X -Phadoop_yarn --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -Dhadoop.version=$GIRAPH_HADOOP_VERSION -Dyarn.version=$GIRAPH_HADOOP_VERSION -Dhive.version=$GIRAPH_HIVE_VERSION -DskipTests compile
  elif [[ $GIRAPH_HADOOP_VERSION == 2.4.* ]] ; then
    mvn -U -X -Phadoop_yarn --settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml -Dhadoop.version=$GIRAPH_HADOOP_VERSION -Dyarn.version=$GIRAPH_HADOOP_VERSION -Dhive.version=$GIRAPH_HIVE_VERSION -DskipTests compile
  else
    echo "fatal - Unrecognize hadoop version $GIRAPH_HADOOP_VERSION, can't continue, exiting, no cleanup"
    exit -9
  fi
else
  echo "ok - applying default repository form pom.xml"
  if [[ $GIRAPH_HADOOP_VERSION == 2.2.* ]] ; then
    mvn -U -X -Phadoop_yarn -Dhadoop.version=$GIRAPH_HADOOP_VERSION -Dyarn.version=$GIRAPH_HADOOP_VERSION -Dhive.version=$GIRAPH_HIVE_VERSION -DskipTests compile
  elif [[ $GIRAPH_HADOOP_VERSION == 2.4.* ]] ; then
    mvn -U -X -Phadoop_yarn -Dhadoop.version=$GIRAPH_HADOOP_VERSION -Dyarn.version=$GIRAPH_HADOOP_VERSION -Dhive.version=$GIRAPH_HIVE_VERSION -DskipTests compile
  else
    echo "fatal - Unrecognize hadoop version $GIRAPH_HADOOP_VERSION, can't continue, exiting, no cleanup"
    exit -9
  fi
fi

popd
echo "Build Completed successfully!"

%install
# manual cleanup for compatibility, and to be safe if the %clean isn't implemented
rm -rf %{buildroot}%{install_giraph_dest}
# re-create installed dest folders
mkdir -p %{buildroot}%{install_giraph_dest}
echo "compiled/built folder is (not the same as buildroot) RPM_BUILD_DIR = %{_builddir}"
echo "test installtion folder (aka buildroot) is RPM_BUILD_ROOT = %{buildroot}"
echo "test install giraph dest = %{buildroot}/%{install_giraph_dest}"
echo "test install giraph label giraph_folder_name = %{giraph_folder_name}"
%{__mkdir} -p %{buildroot}%{install_giraph_dest}/
%{__mkdir} -p %{buildroot}/etc/%{install_giraph_dest}/
%{__mkdir} -p %{buildroot}%{install_giraph_logs}
%{__mkdir} -p %{buildroot}%{install_giraph_test}
# copy all necessary jars

# test deploy the config folder
cp -rp %{_builddir}/%{build_service_name}/conf %{buildroot}/%{install_giraph_conf}

# Inherit license, readme, etc
cp -p %{_builddir}/%{build_service_name}/README.md %{buildroot}/%{install_giraph_dest}
cp -p %{_builddir}/%{build_service_name}/LICENSE %{buildroot}/%{install_giraph_dest}
cp -p %{_builddir}/%{build_service_name}/NOTICE %{buildroot}/%{install_giraph_dest}

# deploy test suite and scripts
cp -rp %{_builddir}/%{build_service_name}/test_giraph/* %{buildroot}/%{install_giraph_test}

%clean
echo "ok - cleaning up temporary files, deleting %{buildroot}%{install_giraph_dest}"
rm -rf %{buildroot}%{install_giraph_dest}

%files
%defattr(0755,giraph,giraph,0755)
%{install_giraph_dest}
%dir %{install_giraph_conf}
%attr(0755,giraph,giraph) %{install_giraph_conf}
%attr(0775,giraph,giraph) %{install_giraph_logs}
%config(noreplace) %{install_giraph_conf}

%files test
%defattr(0755,giraph,giraph,0755)
%{install_giraph_test}

%post
if [ "$1" = "1" ]; then
  echo "ok - performing fresh installation"
elif [ "$1" = "2" ]; then
  echo "ok - upgrading system"
fi
rm -vf /opt/%{apache_name}/logs
rm -vf /opt/%{apache_name}/conf
rm -vf /opt/%{apache_name}/test_giraph
rm -vf /opt/%{apache_name}
rm -vf /etc/%{apache_name}
ln -vsf %{install_giraph_dest} /opt/%{apache_name}
ln -vsf %{install_giraph_conf} /etc/%{apache_name}
ln -vsf %{install_giraph_conf} /opt/%{apache_name}/conf
ln -vsf %{install_giraph_logs} /opt/%{apache_name}/logs
mkdir -p /home/giraph/logs
chmod -R 1777 /home/giraph/logs
chown %{giraph_uid}:%{giraph_gid} /home/giraph/
chown %{giraph_uid}:%{giraph_gid} /home/giraph/logs

%postun
if [ "$1" = "0" ]; then
  ret=$(rpm -qa | grep alti-giraph- | wc -l)
  if [ "x${ret}" != "x0" ] ; then
    echo "ok - detected other giraph version, no need to clean up symbolic links"
    echo "ok - cleaning up version specific directories only regarding this uninstallation"
    rm -vrf %{install_giraph_dest}
    rm -vrf %{install_giraph_conf}
  else
    echo "ok - uninstalling %{rpm_package_name} on system, removing symbolic links"
    rm -vf /opt/%{apache_name}/logs
    rm -vf /opt/%{apache_name}/conf
    rm -vf /opt/%{apache_name}
    rm -vf /etc/%{apache_name}
    rm -vrf %{install_giraph_dest}
    rm -vrf %{install_giraph_conf}
  fi
fi
# Don't delete the users after uninstallation.

%changelog
* Tue Dec 16 2014 Andrew Lee 20141216
- Initial Creation of spec file for Giraph 1.1


