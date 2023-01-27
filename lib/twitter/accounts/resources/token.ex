defmodule Twitter.Accounts.Token do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  actions do
    defaults [:destroy]
  end

  code_interface do
    define_for Twitter.Accounts
    define :destroy
  end

  token do
    api Twitter.Accounts
  end

  postgres do
    table "tokens"
    repo Twitter.Repo
  end

  attributes do
    uuid_primary_key :id

    timestamps()
  end
end
