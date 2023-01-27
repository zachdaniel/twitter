defmodule Twitter.Accounts.Secrets do
  @moduledoc "Secrets adapter for AshHq authentication"
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Twitter.Accounts.User, _) do
    Application.fetch_env(:twitter, :token_signing_secret)
  end
end
