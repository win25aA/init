# Тема SDDM из папки simple-sddm-2 в корне репозитория.
{ runCommand }:

runCommand "simple-sddm-2-theme" { } ''
  mkdir -p $out/share/sddm/themes/simple-sddm-2
  cp -r ${../simple-sddm-2}/* $out/share/sddm/themes/simple-sddm-2/
  ln -s /var/lib/sddm-wallpaper/colors.conf $out/share/sddm/themes/simple-sddm-2/theme.conf.user
''
