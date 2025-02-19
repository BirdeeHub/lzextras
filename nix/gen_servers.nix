{
  APPNAME ? "server_filetypes_generator",
  writeText,
  writeShellScriptBin,
  lib,
  nvim-lspconfig,
  stdenv,
  wrapNeovim,
  neovim-unwrapped,
  ...
}:
with builtins; let
  servers = lib.pipe "${nvim-lspconfig}/lua/lspconfig/configs" [
    readDir
    attrNames
    (map (str: substring 0 (stringLength str - 4) str))
    (concatStringsSep "', '")
    (s: "{ '" + s + "' }")
  ];
  genvim = wrapNeovim neovim-unwrapped (let
    luaRC =
      writeText "init.lua"
      /*
      lua
      */
      ''
        package.preload["servernames"] = function() return ${servers} end
        local ok, v = pcall(dofile, "${./gen_servers.lua}")
        if not ok then
          vim.cmd.cquit()
        else
          vim.cmd('qa!')
        end
      '';
  in {
    configure = {
      customRC = ''lua dofile("${luaRC}")'';
      packages.all.start = [nvim-lspconfig];
    };
  });
  serverdir = stdenv.mkDerivation {
    name = "${APPNAME}-generated-servers";
    src = ./.;
    phases = ["buildPhase"];
    buildPhase =
      /*
      bash
      */
      ''
        export HOME=$(mktemp -d)
        mkdir -p $out
        ${genvim}/bin/nvim --headless --cmd "lua vim.g.server_gen_out_path = [[$out]]"
      '';
  };
in
  writeShellScriptBin APPNAME ''
    OUTDIR=''${1:-"./pack/lzextras/start/lzextras_lsp_filetypes/lua/lzextras/lsp_filetypes"}
    mkdir -p $OUTDIR
    cp -rvf ${serverdir}/* $OUTDIR
    sudo chmod 644 $OUTDIR/*
    sudo chown $(id -u):$(id -g) $OUTDIR/*
  ''
