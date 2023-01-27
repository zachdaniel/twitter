defmodule Twitter.Repo do
  use AshPostgres.Repo,
    otp_app: :twitter

  def installed_extensions do
    ["citext"]
  end
end
