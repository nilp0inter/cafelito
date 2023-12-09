{
  description = "A NixOS and Home Manager Configuration Framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    haumea.url = "github:nix-community/haumea/v0.2.2";
  };

  outputs = inputs@{ self, nixpkgs, haumea }:
  {
    templates = {
      default = {
        path = ./templates/default;
        description = "A default template for NixOS and Home Manager";
      };
    };
    lib = {
      loadModules = ({ inputs, moduleType, basePath, ... }:
        let
          directories = builtins.attrNames (nixpkgs.lib.filterAttrs (k: v: v == "directory" && builtins.pathExists (basePath + /${k}/${moduleType})) (builtins.readDir basePath));
        in
        (nixpkgs.lib.attrsets.genAttrs directories (name: { pkgs, ... }@args: haumea.lib.load {
          src = basePath + /${name}/${moduleType};
          inputs = args // { inherit inputs; };
          transformer = [
            haumea.lib.transformers.liftDefault
            (haumea.lib.transformers.hoistLists "_imports" "imports")
          ];
        })));
      loadFeatures = ({ inputs, basePath }: rec {
        homeModules = self.lib.loadModules { inherit inputs; moduleType = "homeModule"; basePath = basePath; };
        nixosModules = self.lib.loadModules { inherit inputs; moduleType = "nixosModule"; basePath = basePath; };
        forUser = let
          fromHomeModule = user: homeModule: { home-manager.users.${user} = { imports = [ homeModule ]; }; };
        in user: nixpkgs.lib.attrsets.zipAttrsWith (_: vs: vs) [ (nixpkgs.lib.attrsets.mapAttrs (_: m: fromHomeModule user m) homeModules) nixosModules ];
      });
      asNixosModules = nixpkgs.lib.lists.flatten;
    };
  };
}
