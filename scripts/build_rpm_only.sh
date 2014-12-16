#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

giraph_spec="$curr_dir/giraph.spec"

mock_cfg="$curr_dir/altiscale-giraph-centos-6-x86_64.cfg"
mock_cfg_name=$(basename "$mock_cfg")
mock_cfg_runtime=`echo $mock_cfg_name | sed "s/.cfg/.runtime.cfg/"`
build_timeout=14400

maven_settings="$HOME/.m2/settings.xml"
maven_settings_spec="$curr_dir/alti-maven-settings.spec"

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
  # source "$curr_dir/setup_env.sh"
  . "$curr_dir/setup_env.sh"
  set +a
fi

if [ "x${BUILD_TIMEOUT}" = "x" ] ; then
  build_timeout=14400
else
  build_timeout=$BUILD_TIMEOUT
fi

if [ "x${WORKSPACE}" = "x" ] ; then
  WORKSPACE="$curr_dir/../"
fi

if [ ! -f "$maven_settings" ]; then
  echo "fatal - $maven_settings DOES NOT EXIST!!!! YOU MAY PULLING IN UNTRUSTED artifact and BREACH SECURITY!!!!!!"
  exit -9
fi

if [ ! -e "$giraph_spec" ] ; then
  echo "fail - missing $giraph_spec file, can't continue, exiting"
  exit -9
fi

cleanup_secrets()
{
  echo hello
  # Erase our track for any sensitive credentials if necessary
  #rm -f $WORKSPACE/rpmbuild/RPMS/noarch/alti-maven-settings*.rpm
  #rm -f $WORKSPACE/rpmbuild/RPMS/noarch/alti-maven-settings*.src.rpm
  #rm -f $WORKSPACE/rpmbuild/SRPMS/alti-maven-settings*.src.rpm
  #rm -rf $WORKSPACE/rpmbuild/SOURCES/alti-maven-settings*
}

env | sort
# should switch to WORKSPACE, current folder will be in WORKSPACE/giraph due to 
# hadoop_ecosystem_component_build.rb => this script will change directory into your submodule dir
# WORKSPACE is the default path when jenkin launches e.g. /mnt/ebs1/jenkins/workspace/giraph_build_test-alee
# If not, you will be in the $WORKSPACE/giraph folder already, just go ahead and work on the submodule
# The path in the following is all relative, if the parent jenkin config is changed, things may break here.
pushd `pwd`
cd $WORKSPACE/giraph
if [ "x${BRANCH_NAME}" = "x" ] ; then
  echo "error - BRANCH_NAME is not defined. Please specify the BRANCH_NAME explicitly. Exiting!"
  exit -9
fi
  echo "ok - switching to impaala branch $BRANCH_NAME and refetch the files"
  git checkout $BRANCH_NAME
  git fetch --all
  git pull
popd

echo "ok - tar zip source file, preparing for build/compile by rpmbuild"
mkdir -p $WORKSPACE/rpmbuild/{BUILD,BUILDROOT,RPMS,SPECS,SOURCES,SRPMS}/
cp -f "$giraph_spec" $WORKSPACE/rpmbuild/SPECS/giraph.spec
pushd $WORKSPACE
tar --exclude .git --exclude .gitignore -cf $WORKSPACE/rpmbuild/SOURCES/giraph.tar giraph test_giraph
popd

pushd "$WORKSPACE/rpmbuild/SOURCES/"
tar -xf giraph.tar
if [ -d alti-giraph ] ; then
  rm -rf alti-giraph
fi
mv giraph alti-giraph
cp -rp test_giraph alti-giraph/
tar --exclude .git --exclude .gitignore -cpzf alti-giraph.tar.gz alti-giraph
stat alti-giraph.tar.gz

if [ -f "$maven_settings" ] ; then
  mkdir -p  alti-maven-settings
  cp "$maven_settings" alti-maven-settings/
  tar -cvzf alti-maven-settings.tar.gz alti-maven-settings
  cp "$maven_settings_spec" $WORKSPACE/rpmbuild/SPECS/
fi
# 
# Explicitly define GIRAPH_HOME here for build purpose
export GIRAPH_HOME=$WORKSPACE/rpmbuild/BUILD/alti-giraph
echo "ok - applying version number $GIRAPH_VERSION and release number $BUILD_TIME, the pattern delimiter is / here"
sed -i "s/GIRAPH_VERSION_REPLACE/$GIRAPH_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/giraph.spec"
sed -i "s/HADOOP_VERSION_REPLACE/$HADOOP_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/giraph.spec"
sed -i "s/HIVE_VERSION_REPLACE/$HIVE_VERSION/g" "$WORKSPACE/rpmbuild/SPECS/giraph.spec"
sed -i "s/GIRAPH_USER/$GIRAPH_USER/g" "$WORKSPACE/rpmbuild/SPECS/giraph.spec"
sed -i "s/GIRAPH_GID/$GIRAPH_GID/g" "$WORKSPACE/rpmbuild/SPECS/giraph.spec"
sed -i "s/GIRAPH_UID/$GIRAPH_UID/g" "$WORKSPACE/rpmbuild/SPECS/giraph.spec"
sed -i "s/BUILD_TIME/$BUILD_TIME/g" "$WORKSPACE/rpmbuild/SPECS/giraph.spec"
sed -i "s/ALTISCALE_RELEASE/$ALTISCALE_RELEASE/g" "$WORKSPACE/rpmbuild/SPECS/giraph.spec"

rpmbuild -vvv -ba --define "_topdir $WORKSPACE/rpmbuild" --buildroot $WORKSPACE/rpmbuild/BUILDROOT/ $WORKSPACE/rpmbuild/SPECS/giraph.spec
if [ $? -ne "0" ] ; then
  echo "fail - rpmbuild -ba RPM build failed"
  exit -96
fi

rpmbuild -vvv -bi --short-circuit --define "_topdir $WORKSPACE/rpmbuild" --buildroot $WORKSPACE/rpmbuild/BUILDROOT/ $WORKSPACE/rpmbuild/SPECS/giraph.spec
if [ $? -ne "0" ] ; then
  echo "fail - rpmbuild -bi --short-circuit RPM build failed"
  exit -97
fi

exit 0












