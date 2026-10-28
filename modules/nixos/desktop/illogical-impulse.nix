# Системная поддержка QS. Сам интерфейс подключается через Home Manager.
{ pkgs, ... }:
{
  fonts.packages = [ pkgs.inter pkgs.material-symbols ];
  services.upower.enable = true;
  # Штатная проверка пароля пользователя для экрана блокировки QS.
  # Автоблокировка при запуске не включена: сначала проверить вручную.
  security.pam.services.quickshell = { };
}
