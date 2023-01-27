defmodule Twitter.Tweets.Tweet do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    notifiers: [
      Ash.Notifier.PubSub
    ]

  require Ecto.Query

  actions do
    defaults [:read, :destroy]

    read :feed do
      description "Get the feed of tweets for a user"

      argument :user_id, :uuid do
        allow_nil? false
      end

      prepare build(sort: [inserted_at: :desc])

      filter expr(visible_to(user_id: arg(:user_id)))
    end

    create :create do
      accept [:text]

      primary? true

      argument :public, :boolean do
        allow_nil? false
        default true
      end

      change fn changeset, _ ->
        if Ash.Changeset.get_argument(changeset, :public) do
          Ash.Changeset.force_change_attribute(changeset, :visibility, :public)
        else
          changeset
        end
      end

      change relate_actor(:author)
    end

    update :update do
      accept [:text]

      primary? true

      argument :public, :boolean do
        allow_nil? false
        default true
      end

      change fn changeset, _ ->
        if Ash.Changeset.get_argument(changeset, :public) do
          Ash.Changeset.force_change_attribute(changeset, :visibility, :public)
        else
          Ash.Changeset.force_change_attribute(changeset, :visibility, :friends)
        end
      end
    end

    update :like do
      accept []

      manual fn changeset, %{actor: actor} ->
        with {:ok, _} <- Twitter.Tweets.Like.like(changeset.data.id, actor: actor) do
          {:ok, changeset.data}
        end
      end
    end

    update :dislike do
      accept []

      manual fn changeset, %{actor: actor} ->
        like =
          Ecto.Query.from(like in Twitter.Tweets.Like,
            where: like.user_id == ^actor.id,
            where: like.tweet_id == ^changeset.data.id
          )

        Twitter.Repo.delete_all(like)

        {:ok, changeset.data}
      end
    end
  end

  pub_sub do
    module TwitterWeb.Endpoint
    prefix "tweets"

    publish :like, ["liked", :id]
    publish :dislike, ["unliked", :id]
    publish :create, ["created"]
  end

  code_interface do
    define_for Twitter.Tweets
    define :feed, args: [:user_id]
    define :get, action: :read, get_by: [:id]
    define :like
    define :dislike
    define :destroy
  end

  attributes do
    uuid_primary_key :id

    attribute :text, :string do
      allow_nil? false
      constraints max_length: 255
    end

    attribute :visibility, :atom do
      constraints one_of: [:friends, :public]
    end

    timestamps()
  end

  relationships do
    belongs_to :author, Twitter.Accounts.User do
      api Twitter.Accounts
      allow_nil? false
    end
  end

  postgres do
    table "tweets"
    repo Twitter.Repo
  end

  relationships do
    has_many :likes, Twitter.Tweets.Like
  end

  calculations do
    calculate :liked_by_user, :boolean, expr(exists(likes, user_id == ^arg(:user_id))) do
      argument :user_id, :uuid do
        allow_nil? false
      end
    end

    calculate :visible_to,
              :boolean,
              expr(
                author_id == ^arg(:user_id) or visibility == :public or
                  visible_as_friend(user_id: arg(:user_id))
              ) do
      argument :user_id, :uuid do
        allow_nil? false
      end
    end

    calculate :visible_as_friend,
              :boolean,
              expr(exists(author.approved_friend_requests, destination_user_id == ^arg(:user_id))) do
      argument :user_id, :uuid do
        allow_nil? false
      end
    end
  end

  aggregates do
    first :author_email, :author, :email
    count :like_count, :likes
  end
end
