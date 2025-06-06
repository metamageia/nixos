{
  virtualisation.oci-containers = {
    backend = "podman"; # or "docker"
    containers = {
      omnivore-api = {
        image = "ceramicwhite/omnivore:api-latest";
        autoStart = true;
        ports = [ "3000:3000" ]; # Adjust as needed
        environment = {
          # Set necessary environment variables here
        };
        volumes = [
          # Mount host directories if needed
        ];
      };
      omnivore-web = {
        image = "ceramicwhite/omnivore:web-latest";
        autoStart = true;
        ports = [ "3001:3001" ]; # Adjust as needed
        environment = {
          # Set necessary environment variables here
        };
        volumes = [
          # Mount host directories if needed
        ];
      };
      omnivore-content-fetch = {
        image = "ceramicwhite/omnivore:content-fetch-latest";
        autoStart = true;
        environment = {
          # Set necessary environment variables here
        };
        volumes = [
          # Mount host directories if needed
        ];
      };
      omnivore-migrate = {
        image = "ceramicwhite/omnivore:migrate-latest";
        autoStart = false; # Typically run once during setup
        environment = {
          # Set necessary environment variables here
        };
        volumes = [
          # Mount host directories if needed
        ];
      };
    };
  };
}
