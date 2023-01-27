defmodule Twitter.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication, AshAdmin.Resource]

  admin do
    actor? true
  end

  authentication do
    api Twitter.Accounts

    strategies do
      password :password do
        identity_field :email
      end
    end

    tokens do
      enabled? true
      require_token_presence_for_authentication? true
      signing_secret Twitter.Accounts.Secrets
      store_all_tokens? true
      token_resource Twitter.Accounts.Token
    end
  end

  code_interface do
    define_for Twitter.Accounts

    define :add_and_request_friend, args: [:destination_user_id]
  end

  actions do
    read :read do
      primary? true
      pagination offset?: true
    end

    update :add_and_request_friend do
      primary? true
      accept []

      argument :destination_user_id, :uuid do
        allow_nil? false
      end

      manual fn changeset, _ ->
        with {:ok, destination_user_id} <-
               Ash.Changeset.fetch_argument(changeset, :destination_user_id),
             {:ok, _} <-
               Twitter.Accounts.FriendLink.create(changeset.data.id, destination_user_id, %{
                 status: :approved
               }),
             {:ok, _} <-
               Twitter.Accounts.FriendLink.create(destination_user_id, changeset.data.id) do
          {:ok, changeset.data}
        end
      end
    end
  end

  identities do
    identity :unique_email, [:email]
  end

  postgres do
    table "users"
    repo Twitter.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
    end

    attribute :hashed_password, :string do
      sensitive? true
    end

    timestamps()
  end

  relationships do
    many_to_many :my_friends, Twitter.Accounts.User do
      through Twitter.Accounts.FriendLink
      source_attribute_on_join_resource :source_user_id
      destination_attribute_on_join_resource :destination_user_id
    end

    many_to_many :friends_to_me, Twitter.Accounts.User do
      through Twitter.Accounts.FriendLink
      source_attribute_on_join_resource :destination_user_id
      destination_attribute_on_join_resource :source_user_id
    end

    has_many :pending_friend_requests, Twitter.Accounts.FriendLink do
      filter expr(status == :pending)
      destination_attribute :source_user_id
    end

    has_many :approved_friend_requests, Twitter.Accounts.FriendLink do
      filter expr(status == :approved)
      destination_attribute :source_user_id
    end
  end
end
