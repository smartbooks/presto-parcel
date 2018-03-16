#!/bin/sh

cd ${project.build.directory}

parcel_name="${project.build.finalName}"
mkdir $parcel_name

decompressed_dir="extract"
presto_download_name="presto.tar.gz"

#presto_download_url="https://repo1.maven.org/maven2/com/facebook/presto/presto-server/${presto.version}/presto-server-${presto.version}.tar.gz"
#presto_cli_download_url="https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/${presto.version}/presto-cli-${presto.version}-executable.jar"
presto_download_url="http://localhost/presto/presto-server-${presto.version}.tar.gz"
presto_cli_download_url="http://localhost/presto/presto-cli-${presto.version}-executable.jar"

#download presto release packages.
curl -L -o $presto_download_name $presto_download_url
mkdir $decompressed_dir
tar xzf $presto_download_name -C $decompressed_dir

#move oracle plugin to presto.
mv classes/presto.${presto.version}.plugin.oracle $decompressed_dir/presto-server-${presto.version}/plugin/oracle

#move presto to parcel dir.
presto_dir=`\ls $decompressed_dir`
for file in `\ls $decompressed_dir/$presto_dir`; do
  mv $decompressed_dir/$presto_dir/$file $parcel_name
done
rm -rf $decompressed_dir

#download presto cli.
curl -L -O $presto_cli_download_url
mv presto-cli-${presto.version}-executable.jar ${parcel_name}/bin/
chmod +x ${parcel_name}/bin/presto-cli-${presto.version}-executable.jar

#generte cli boot file.
cat <<"EOF" > ${parcel_name}/bin/presto
#!/usr/bin/env python

import os
import sys
import subprocess
from os.path import realpath, dirname

path = dirname(realpath(sys.argv[0]))
arg = ' '.join(sys.argv[1:])
cmd = "env PATH=\"%s/../jdk/bin:$PATH\" %s/presto-cli-${presto.version}-executable.jar %s" % (path, path, arg)

subprocess.call(cmd, shell=True)
EOF
chmod +x ${parcel_name}/bin/presto

#tar parcel package
cp -a ${project.build.outputDirectory}/meta ${parcel_name}
tar zcf ${parcel_name}.parcel ${parcel_name}/ --owner=root --group=root

#make repository dir.
mkdir repository
for i in el6 el7; do
  cp ${parcel_name}.parcel repository/${parcel_name}-${i}.parcel
done

#generte manifest file.
cd repository
curl https://raw.githubusercontent.com/cloudera/cm_ext/master/make_manifest/make_manifest.py | python


