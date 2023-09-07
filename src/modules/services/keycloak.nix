{ config, lib, pkgs, ... }:

let
  cfg = config.services.keycloak;

  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkRenamedOptionModule
    escapeShellArg
    literalExpression
    types
    ;
in
{
  imports = [
    (mkRenamedOptionModule [ "keycloak" "enable" ] [ "services" "keycloak" "enable" ])
  ];

  options.services.keycloak = {
    enable = mkOption {
      description = "Whether to enable keycloak.";
      default = false;
      type = types.bool;
    };

    initialAdminPassword = mkOption {
      type = types.str;
      default = "changeme";
      description = mdDoc ''
        Initial password set for the `admin`
        user. The password is not stored safely and should be changed
        immediately in the admin panel.
      '';
    };

    package = mkOption {
      description = "Keycloak package to use.";
      default = pkgs.keycloak;
      defaultText = literalExpression "pkgs.keycloak";
      type = types.package;
    };
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    env.KC_DB = "dev-mem";

    env.KC_HOME_DIR = config.env.DEVENV_STATE + "/keycloak";
    env.KC_CONF_DIR = config.env.DEVENV_STATE + "/keycloak/conf";
    env.KC_TMP_DIR = config.env.DEVENV_STATE + "/keycloak/tmp";

    env.KEYCLOAK_ADMIN = "admin";
    env.KEYCLOAK_ADMIN_PASSWORD = "${escapeShellArg cfg.initialAdminPassword}";
    env.KC_HOSTNAME = "localhost";
    env.KC_LOG_LEVEL = "DEBUG";
    env.KC_LOG = "console";

    processes.keycloak = {
      exec = '' 
        mkdir -p "$KC_HOME_DIR"
        mkdir -p "$KC_HOME_DIR/providers"
        mkdir -p "$KC_HOME_DIR/conf"
        mkdir -p "$KC_HOME_DIR/tmp"

        ${cfg.package}/bin/kc.sh show-config
        ${cfg.package}/bin/kc.sh --verbose build 
      '';
    };
  };
}
