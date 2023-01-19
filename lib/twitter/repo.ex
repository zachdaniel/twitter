defmodule Twitter.Repo do
  use AshPostgres.Repo,
    otp_app: :twitter
end
