# https://www.booleanworld.com/creating-linux-apps-run-anywhere-appimage/

project_dir=$1

if !(test -d "../bash"); then
  git clone https://github.com/ivan-yankov/bash.git
  mv bash ../
fi

source ../bash/load.sh
source $project_dir/app-image.sh

app_dir=AppDir
rm -rf $app_dir
mkdir $app_dir
mkdir $app_dir/jar

cp resources/AppRun $app_dir/AppRun
sed -i "s/###JVM_XMS###/$JVM_XMS/" $app_dir/AppRun
sed -i "s/###JVM_XMX###/$JVM_XMX/" $app_dir/AppRun
sed -i "s/###MAIN_CLASS###/$MAIN_CLASS/" $app_dir/AppRun
sed -i "s/###PARAMETERS###/$PARAMETERS/" $app_dir/AppRun
sed -i "s/###BEFORE###/$BEFORE/" $app_dir/AppRun
sed -i "s/###AFTER###/$AFTER/" $app_dir/AppRun

cp resources/template.desktop $app_dir/$APPLICATION_NAME.desktop
sed -i "s/###APPLICATION_NAME###/$APPLICATION_NAME/" $app_dir/$APPLICATION_NAME.desktop
sed -i "s/###IS_TERMINAL_APPLICATION###/$IS_TERMINAL_APPLICATION/" $app_dir/$APPLICATION_NAME.desktop

if [ -z "$ICON_FILE" ]; then
  cp resources/icon.png $app_dir/icon.png
else
  cp $project_dir/$ICON_FILE $app_dir/icon.png
fi

for f in ${JARS[@]}; do
  cp -r $project_dir/$f $app_dir/jar
done

# download jre if necessary
f=jre-$JVM_VERSION.tar.gz
if !(test -f "$f"); then
  java-download jre $JVM_VERSION
fi

untargz $f
mv $(targz-root $f) $app_dir/jre

# detect machine's architecture
export ARCH=$(uname -m)

# get the missing tools if necessary
if [ ! -x ./appimagetool-$ARCH.AppImage ]; then
  curl -L -o ./appimagetool-$ARCH.AppImage https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$ARCH.AppImage
  chmod a+x ./appimagetool-$ARCH.AppImage 
fi

# build app-image
./appimagetool-$ARCH.AppImage $app_dir

mv $APPLICATION_NAME-$ARCH.AppImage $project_dir/$APPLICATION_NAME.AppImage

rm -rf $app_dir
