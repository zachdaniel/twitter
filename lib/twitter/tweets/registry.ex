defmodule Twitter.Tweets.Registry do
  use Ash.Registry

  entries do
    entry Twitter.Tweets.Tweet
    entry Twitter.Tweets.Like
  end
end
