defmodule Twitter.Accounts.Registry do
  use Ash.Registry,
    extensions: Ash.Registry.ResourceValidations

  entries do
    entry Twitter.Accounts.User
    entry Twitter.Accounts.Token
    entry Twitter.Accounts.FriendLink
  end
end
