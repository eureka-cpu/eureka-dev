{
  description = "A flake for managing the eureka developer site.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices;

        # The preprocessor version must be the same for both mdbook
        # and mdbook-mermaid, otherwise it may throw an error.
        mdbook = pkgs.callPackage ./pkgs/mdbook {
          inherit CoreServices;
          version = "0.4.36";
          sha256 = "sha256-QQSGnOWRx5KK9eJP759E1V9zFVzvRol5bdJfD9mDr5g=";
          cargoHash = "sha256-IlD4YI7jsWZw0Dn1PoljmhuIOqejva8HMhU4ULy32yE=";
        };
        mdbook-mermaid = pkgs.callPackage ./pkgs/mdbook-mermaid {
          inherit CoreServices;
          version = "0.14.0";
          hash = "sha256-elDKxtGMLka9Ss5CNnzw32ndxTUliNUgPXp7e4KUmBo=";
          cargoHash = "sha256-BnbllOsidqDEfKs0pd6AzFjzo51PKm9uFSwmOGTW3ug=";
        };

        # TODO: inject src so this will build the actual book at root
        mdbook-build = pkgs.runCommand "mdbook-build" {
          buildInputs = [
            self.packages.${system}.mdbook
            self.packages.${system}.mdbook-mermaid
          ];
        } ''
          mkdir -p $out
          mdbook init $out
          mdbook-mermaid install $out
          mdbook build $out
        '';
      in
      {
        checks = {
          inherit mdbook-build;
        };
        packages = {
          inherit
            mdbook
            mdbook-mermaid
            mdbook-build
            ;
          default = mdbook-build;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            mdformat
          ] ++ [
            self.packages.${system}.mdbook
            self.packages.${system}.mdbook-mermaid
          ];
        };
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
