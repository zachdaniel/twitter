defmodule Twitter.TweetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Twitter.Tweets` context.
  """

  @doc """
  Generate a tweet.
  """
  def tweet_fixture(attrs \\ %{}) do
    {:ok, tweet} =
      attrs
      |> Enum.into(%{})
      |> Twitter.Tweets.create_tweet()

    tweet
  end
end
