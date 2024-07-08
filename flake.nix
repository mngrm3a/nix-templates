{
  outputs =
    { self }:
    {
      templates = {
        haskell = {
          path = ./haskell;
          description = "haskell template";
          welcomeText = ''
            run 'zsh setup' to create a project
          '';
        };
      };
    };
}
