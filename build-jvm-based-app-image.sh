# https://www.booleanworld.com/creating-linux-apps-run-anywhere-appimage
function build-jvm-based-app-image {
  is-defined $1 && is-defined $2 && is-defined $3 && is-defined $4 || return 1

  ini_file=$1
  resource_dir=$2
  cache_dir=$3
  app_image=$4

  project_dir=$(dirname $ini_file)

  app_dir=$cache_dir/AppDir

  mkdir -p $cache_dir
    
  jvm_version=$(text-get-ini-value JvmVersion $ini_file)
  jvm_xms=$(text-get-ini-value JvmXms $ini_file)
  jvm_xmx=$(text-get-ini-value JvmXmx $ini_file)
  application_jars=$(text-get-ini-value ApplicationJars $ini_file)
  main_class=$(text-get-ini-value MainClass $ini_file)
  parameters=$(text-get-ini-value Parameters $ini_file)
  application_name=$(text-get-ini-value ApplicationName $ini_file)
  is_terminal_application=$(text-get-ini-value IsTerminalApplication $ini_file)
  icon_file_ini=$(text-get-ini-value IconFile $ini_file)
  before=$(text-get-ini-value Before $ini_file)
  after=$(text-get-ini-value After $ini_file)

  icon_file=$resource_dir/icon.png
  (is-defined $icon_file_ini > /dev/null) && icon_file=$project_dir/$icon_file_ini

  rm -rf $app_dir
  mkdir $app_dir
  mkdir $app_dir/jar

  local app_run=$app_dir/AppRun
  echo '#!/bin/sh' > $app_run
  echo 'cd "$(dirname "$0")"' >> $app_run
  echo "$before" >> $app_run
  echo "./jre/bin/java -Xms$jvm_xms -Xmx$jvm_xmx -Dfile.encoding=UTF-8 -classpath \"jar/*\" $main_class $parameters" '"$@"' >> $app_run
  echo "$after" >> $app_run
  sudo chmod +x $app_run

  local desktop=$app_dir/$application_name.desktop
  echo "[Desktop Entry]" > $desktop
  echo "Type=Application" >> $desktop
  echo "Name=$application_name" >> $desktop
  echo "Icon=icon" >> $desktop
  echo "Categories=Utility" >> $desktop
  echo "Terminal=$is_terminal_application" >> $desktop
  echo "X-AppImage-Version=0.1.09" >> $desktop

  cp $icon_file $app_dir/icon.png
  
  cp $project_dir/$application_jars $app_dir/jar
  
  # download jre if necessary
  local jre_archive=$cache_dir/jre-$jvm_version.tar.gz
  if [ ! -f $jre_archive ]; then
    java-download jre $jvm_version $cache_dir
  fi

  java-extract $jre_archive  
  mv $cache_dir/jre-$jvm_version $app_dir/jre
  
  # detect machine's architecture
  arch=$(uname -m)
  
  # get the missing tools if necessary
  if [ ! -f $cache_dir/appimagetool-$arch.AppImage ]; then
    curl -L -o $cache_dir/appimagetool-$arch.AppImage https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$arch.AppImage
    chmod a+x $cache_dir/appimagetool-$arch.AppImage 
  fi
  
  # build app-image
  $cache_dir/appimagetool-$arch.AppImage $app_dir

  sudo mv $project_dir/$application_name-$arch.AppImage $app_image
}
