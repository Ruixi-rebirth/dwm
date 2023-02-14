{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    let
      overlay =
        final: prev: {
          dwm = prev.dwm.overrideAttrs (oldAttrs: rec {
            postPatch = (oldAttrs.postPatch or "") + ''
              if [[ ! -d "statusbar" ]]; then 
                cp -r DEF/statusbar .
              fi
              if [[ ! -f "config.h" ]]; then 
                cp DEF/config.h . 
              fi
              if [[ ! -f "autostart.sh" ]]; then 
                  cp DEF/autostart.sh . 
              fi
            '';
            version = "master";
            src = ./.;
          });
        };
    in
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
            ];
          };
          my-buildInputs = with pkgs; [ ];
          autostart-name = "dwm-autostart";
          autostart-script = (pkgs.writeScriptBin autostart-name (builtins.readFile ./autostart.sh)).overrideAttrs (old: {

            buildCommand = "${old.buildCommand}\n patchShebangs $out";

          });
          statusbar-name = "dwm-statusbar";
          statusbar-script = (pkgs.writeScriptBin statusbar-name (builtins.readFile ./statusbar/statusbar.sh)).overrideAttrs (old: {

            buildCommand = "${old.buildCommand}\n patchShebangs $out";

          });



        in
        rec {
          defaultPackage = packages.statusbar-script;
          packages = {
            dwm = pkgs.dwm;
            autostart-script = pkgs.symlinkJoin {
              name = autostart-name;
              paths = [ autostart-script ] ++ my-buildInputs;
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = "wrapProgram $out/bin/${autostart-name} --prefix PATH : $out/bin";
            };
            statusbar-script = pkgs.symlinkJoin {
              name = statusbar-name;
              paths = [ statusbar-script ] ++ my-buildInputs;
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = "wrapProgram $out/bin/${statusbar-name} --prefix PATH : $out/bin";
            };

          };
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [ xorg.libX11 xorg.libXft xorg.libXinerama gcc ];
          };
        }
      )
    // { overlays.default = overlay; };
}
