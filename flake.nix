{
  description = "Dev shell with zsh, VSCode, and ready to use for dev";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      templates = {
        default = {
          path = ./.;
          description = "A template for a development shell with zsh and VSCode";
        };
      };
    in
      flake-utils.lib.eachDefaultSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        lib = nixpkgs.lib;
        projectLanguages = []; # e.g., [ "python" "java" ]

      # Base VSCode extensions
        defaultExtensions = with pkgs.vscode-extensions; [
        # AI
          github.copilot
          github.copilot-chat

        # Nix
          jnoortheen.nix-ide

        # Misc
          ms-azuretools.vscode-docker
          codezombiech.gitignore
          esbenp.prettier-vscode
          bradlc.vscode-tailwindcss
          dbaeumer.vscode-eslint
          yoavbls.pretty-ts-errors
          ms-vscode.live-server
          ms-vscode-remote.remote-ssh

        # Data
          zainchen.json
          oderwat.indent-rainbow
          mechatroner.rainbow-csv
        ];

      # Per-language settings
        languageSettings = {
          java = {
            extension = with pkgs.vscode-extensions; [
              redhat.java
              vscjava.vscode-java-pack
              vscjava.vscode-maven
              vscjava.vscode-java-debug
              vscjava.vscode-java-test
              vscjava.vscode-java-dependency
            ];
            pkgs = with pkgs; [
              jdk
              maven
            ];
          };
          python = {
            extension = with pkgs.vscode-extensions; [
              ms-python.python
              ms-python.vscode-pylance
              ms-toolsai.jupyter
            ];
            pkgs = with pkgs; [
              python3
              python3Packages.pip
              python3Packages.virtualenv
            ];
          };
        };

      # Collect extensions and packages for all chosen languages
        extensions =
          defaultExtensions
          ++ lib.concatMap (lang: languageSettings.${lang}.extension or [])
               projectLanguages;

        languagesPkgs =
          lib.concatMap (lang: languageSettings.${lang}.pkgs or [])
               projectLanguages;

      # VSCode with extensions baked in
        vscode-dev = pkgs.vscode-with-extensions.override {
          vscode = pkgs.vscode;
          vscodeExtensions = extensions;
        };

      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            zsh
            vscode-dev
          ] ++ languagesPkgs;

          shellHook = ''
            export SHELL=${pkgs.zsh}/bin/zsh
          '';
        };
      })
    // { inherit templates; };
}
