{ pkgs, ... }:

{
    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
        mycontainer = {
            image = "nginx:latest";
            ports = [ "8080:80" ];
            volumes = [
            "/host/path:/container/path"
            ];
            environment = {
            ENV_VAR = "value";
            };
            autoStart = true;
        };
        };
    };
}
