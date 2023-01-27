defmodule Twitter.Accounts do
  use Ash.Api, extensions: [AshAdmin.Api]

  admin do
    show? true
  end

  resources do
    registry Twitter.Accounts.Registry
  end
end
