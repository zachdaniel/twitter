defmodule Twitter.Tweets do
  use Ash.Api,
    extensions: [AshAdmin.Api]

  admin do
    show? true
  end

  resources do
    registry Twitter.Tweets.Registry
  end
end
