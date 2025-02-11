{
  description = "Add laziness to your favourite plugin manager!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    lze = {
      url = "github:BirdeeHub/lze";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks";
      inputs.neorocks.follows = "neorocks";
      inputs.gen-luarc.follows = "gen-luarc";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
    };

    neorocks.url = "github:nvim-neorocks/neorocks";

    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    pre-commit-hooks,
    neorocks,
    gen-luarc,
    lze,
    ...
  }: let
    name = "lzextras";

    pkg-overlay = import ./nix/pkg-overlay.nix {
      inherit name self;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
        ci-overlay = import ./nix/ci-overlay.nix {
          inherit self;
          plugin-name = name;
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            gen-luarc.overlays.default
            neorocks.overlays.default
            lze.overlays.default
            ci-overlay
            pkg-overlay
          ];
        };

        luarc = pkgs.mk-luarc {
          nvim = pkgs.neovim-nightly;
          plugins = [pkgs.vimPlugins.lze];
        };
        luarccurrent = pkgs.mk-luarc {
          nvim = pkgs.neovim;
          plugins = [pkgs.vimPlugins.lze];
        };

        type-check-nightly = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            lua-ls = {
              enable = true;
              settings.configuration = luarc;
            };
          };
        };

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            stylua.enable = true;
            luacheck = {
              enable = true;
            };
            lua-ls = {
              enable = true;
              settings.configuration = luarccurrent;
            };
            editorconfig-checker.enable = true;
            markdownlint = {
              enable = true;
              excludes = [
                "CHANGELOG.md"
              ];
            };
            lemmy-docgen = let
              lemmyscript = pkgs.writeShellScript "lemmy-helper" ''
                gitroot="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
                if [ -z "$gitroot" ]; then
                  echo "Error: Unable to determine Git root."
                  exit 1
                fi
                maindoc="$(realpath "$gitroot/doc/lzextras.txt")"
                luamain="$(realpath "$gitroot/lua/lzextras/init.lua")"
                mkdir -p "$(dirname "$maindoc")"
                export DOCOUT=$(mktemp)
                ${pkgs.lemmy-help}/bin/lemmy-help "$luamain" > "$maindoc"
              '';
            in {
              enable = true;
              name = "lemmy-docgen";
              entry = "${lemmyscript}";
            };
          };
        };

        devShell = let
          test_lpath =
            pkgs.lib.pipe [
              pkgs.vimPlugins.lze
            ] [
              (map (v: "${v}/lua/?.lua;${v}/lua/?/init.lua"))
              (builtins.concatStringsSep ";")
            ];
        in
          pkgs.mkShell {
            name = "lzextras devShell";
            DEVSHELL = 0;
            shellHook = ''
              ${pre-commit-check.shellHook}
              ln -fs ${pkgs.luarc-to-json luarc} .luarc.json
              export TEST_LPATH="${test_lpath}"
            '';
            buildInputs =
              self.checks.${system}.pre-commit-check.enabledPackages
              ++ (with pkgs; [
                lua-language-server
                busted-nlua
              ]);
          };
      in {
        devShells = {
          default = devShell;
          inherit devShell;
        };

        packages = rec {
          default = lzextras-vimPlugin;
          lzextras-luaPackage = pkgs.lua51Packages.${name};
          lzextras-vimPlugin = pkgs.vimPlugins.${name};
        };

        checks = {
          inherit
            pre-commit-check
            type-check-nightly
            ;
          inherit
            (pkgs)
            nvim-nightly-tests
            ;
        };
      };
      flake = {
        overlays.default = pkg-overlay;
      };
    };
}
