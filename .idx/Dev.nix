{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = [
    pkgs.unzip
    pkgs.openssh
    pkgs.git
    pkgs.qemu_kvm
    pkgs.sudo
    pkgs.cdrkit
    pkgs.cloud-utils
    pkgs.qemu
    pkgs.nodejs
    pkgs.firebase-tools
  ];

  env = {};

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = {};
      onStart = {};
    };

    previews = {
      enable = false;
    };
  };

  commands = {
    deploy = "firebase deploy";
  };
}
