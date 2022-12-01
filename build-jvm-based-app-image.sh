# https://www.booleanworld.com/creating-linux-apps-run-anywhere-appimage
function build-jvm-based-app-image {
  is-defined $1 && is-defined $2 && is-defined $3 || return 1

  ini_file=$1
  resource_dir=$2
  cache_dir=$3

  project_dir=$(dirname $ini_file)

  app_dir=$cache_dir/AppDir

  mkdir -p $cache_dir
    
  jvm_version=$(get-ini-value JvmVersion $ini_file)
  jvm_xms=$(get-ini-value JvmXms $ini_file)
  jvm_xmx=$(get-ini-value JvmXmx $ini_file)
  application_jars=$(get-ini-value ApplicationJars $ini_file)
  main_class=$(get-ini-value MainClass $ini_file)
  application_name=$(get-ini-value ApplicationName $ini_file)
  parameters=$(get-ini-value Parameters $ini_file)
  is_terminal_application=$(get-ini-value IsTerminalApplication $ini_file)
  icon_file_ini=$(get-ini-value IconFile $ini_file)
  before=$(get-ini-value Before $ini_file)
  after=$(get-ini-value After $ini_file)

  icon_file=$resource_dir/icon.png
  is-defined $icon_file_ini && icon_file=$project_dir/$icon_file_ini

  rm -rf $app_dir
  mkdir $app_dir
  mkdir $app_dir/jar

  cp $resource_dir/AppRun $app_dir/AppRun
  sed -i "s/###JVM_XMS###/$jvm_xms/" $app_dir/AppRun
  sed -i "s/###JVM_XMX###/$jvm_xmx/" $app_dir/AppRun
  sed -i "s/###MAIN_CLASS###/$main_class/" $app_dir/AppRun
  sed -i "s/###PARAMETERS###/$parameters/" $app_dir/AppRun
  sed -i "s/###BEFORE###/$before/" $app_dir/AppRun
  sed -i "s/###AFTER###/$after/" $app_dir/AppRun
  
  cp $resource_dir/template.desktop $app_dir/$application_name.desktop
  sed -i "s/###APPLICATION_NAME###/$application_name/" $app_dir/$application_name.desktop
  sed -i "s/###IS_TERMINAL_APPLICATION###/$is_terminal_application/" $app_dir/$application_name.desktop
  
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
  
  mv $application_name-$arch.AppImage $project_dir/$application_name.AppImage
}
