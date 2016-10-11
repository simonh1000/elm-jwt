use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or you later on).
config :jwt_example, JwtExample.Endpoint,
  secret_key_base: "2ncE0xOuEFNc1dN13QiAWeIOstGXNxn+SzXGati1PJ1NYJ15VnCpa6DHTt7IWEXF"
