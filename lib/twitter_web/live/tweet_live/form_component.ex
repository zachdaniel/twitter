defmodule TwitterWeb.TweetLive.FormComponent do
  use TwitterWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Share your thoughts</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@form}
        id="tweet-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :text}} type="textarea" label="Text" />
        <.input field={{f, :public}} type="checkbox" label="Public?" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Tweet</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{tweet: tweet, current_user: current_user} = assigns, socket) do
    form =
      if tweet do
        AshPhoenix.Form.for_action(tweet, :update,
          as: "tweet",
          api: Twitter.Tweets,
          actor: current_user
        )
      else
        AshPhoenix.Form.for_action(Twitter.Tweets.Tweet, :create,
          as: "tweet",
          api: Twitter.Tweets,
          actor: current_user
        )
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)}
  end

  @impl true
  def handle_event("validate", %{"tweet" => tweet_params}, socket) do
    {:noreply, assign(socket, :form, AshPhoenix.Form.validate(socket.assigns.form, tweet_params))}
  end

  def handle_event("save", %{"tweet" => tweet_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: tweet_params) do
      {:ok, _tweet} ->
        message =
          case socket.assigns.form.type do
            :create ->
              "Tweet created successfully"

            :update ->
              "Tweet updated successfully"
          end

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end
end
