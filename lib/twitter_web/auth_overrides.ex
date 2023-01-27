defmodule TwitterWeb.AuthOverrides do
  @moduledoc "UI overrides for authentication views"
  use AshAuthentication.Phoenix.Overrides

  override AshAuthentication.Phoenix.SignInLive do
    set :root_class, "grid h-screen place-items-center dark:bg-black"
  end
end
