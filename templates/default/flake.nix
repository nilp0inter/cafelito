{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    cafelito = {
      url = "github:nilp0inter/cafelito";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, cafelito }:
  let
    features = cafelito.loadFeatures { inherit inputs; basePath = ./features; };
  in
  {
    nixosConfigurations.workstation = let
      aliceFeatures = with (features.forUser "alice"); [
        example-feature-1
        example-feature-2
      ];
      bobFeatures = with (features.forUser "bob"); [
        example-feature-2
        example-feature-3
      ];
    in nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ] ++ (cafelito.asNixosModules aliceFeatures)
        ++ (cafelito.asNixosModules bobFeatures);
    };
  };
}
