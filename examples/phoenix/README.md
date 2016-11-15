# JwtExample

## To try

```
mix deps.get
mix ecto.reset
mix phoenix.server
```

### Notes

We put everything in assets that doesn’t need to be transformed by Brunch.
The build tool will simply copy those assets just as they are to priv/static , where
they’ll be served by Phoenix.Static in our endpoint.
