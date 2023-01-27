defmodule Twitter.Accounts.FriendLink do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      upsert? true
      upsert_identity :unique_link
    end
  end

  identities do
    identity :unique_link, [:source_user_id, :destination_user_id]
  end

  code_interface do
    define_for Twitter.Accounts
    define :create, args: [:source_user_id, :destination_user_id]
  end

  postgres do
    table "friend_links"
    repo Twitter.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :status, :atom do
      constraints one_of: [:approved, :ignored, :pending]
      default :pending
      allow_nil? false
    end
  end

  relationships do
    belongs_to :source_user, Twitter.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :destination_user, Twitter.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end
  end
end
