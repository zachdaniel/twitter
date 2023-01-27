defmodule Twitter.Tweets.Like do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  actions do
    defaults [:read, :destroy]

    create :like do
      upsert? true
      upsert_identity :unique_user_and_tweet

      argument :tweet_id, :uuid do
        allow_nil? false
      end

      change set_attribute(:tweet_id, arg(:tweet_id))
      change relate_actor(:user)
    end
  end

  identities do
    identity :unique_user_and_tweet, [:user_id, :tweet_id]
  end

  code_interface do
    define_for Twitter.Tweets
    define :like, args: [:tweet_id]
  end

  postgres do
    table "likes"
    repo Twitter.Repo

    references do
      reference :tweet do
        on_delete :delete
      end

      reference :user do
        on_delete :delete
      end
    end
  end

  attributes do
    uuid_primary_key :id

    timestamps()
  end

  relationships do
    belongs_to :user, Twitter.Accounts.User do
      api Twitter.Accounts
      allow_nil? false
    end

    belongs_to :tweet, Twitter.Tweets.Tweet do
      api Twitter.Tweets
      allow_nil? false
    end
  end
end
