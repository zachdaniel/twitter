defmodule TwitterWeb.TweetLive.Index do
  use TwitterWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Tweets
      <:actions>
        <%= if @pending_tweets > 0 do %>
          <.button phx-click="load-pending-tweets">Load <%= @pending_tweets %> new tweets</.button>
        <% end %>
        <.link patch={~p"/tweets/new"}>
          <.button>New Tweet</.button>
        </.link>
      </:actions>
    </.header>

    <.table id="tweets" rows={@tweets} row_click={&JS.navigate(~p"/tweets/#{&1}")}>
      <:col :let={tweet} label="Email"><%= tweet.author_email %></:col>
      <:col :let={tweet} label="Text">
        <%= tweet.text %>
        <%= if tweet.liked_by_user do %>
          <button phx-click="dislike" phx-value-id={tweet.id}>
            <Heroicons.heart class="h-4 w-4 fill-red-700" />
          </button>
        <% else %>
          <button phx-click="like" phx-value-id={tweet.id}>
            <Heroicons.heart class="h-4 w-4" />
          </button>
        <% end %>
        <%= tweet.like_count %>
      </:col>
      <:action :let={tweet}>
        <div class="sr-only">
          <.link navigate={~p"/tweets/#{tweet}"}>Show</.link>
        </div>
        <.link patch={~p"/tweets/#{tweet}/edit"}>Edit</.link>
      </:action>
      <:action :let={tweet}>
        <.link phx-click={JS.push("delete", value: %{id: tweet.id})} data-confirm="Are you sure?">
          Delete
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="tweet-modal"
      show
      on_cancel={JS.navigate(~p"/tweets")}
    >
      <.live_component
        module={TwitterWeb.TweetLive.FormComponent}
        current_user={@current_user}
        id={if @tweet, do: @tweet.id, else: :new}
        tweet={@tweet}
        title={@page_title}
        action={@live_action}
        navigate={~p"/tweets"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    TwitterWeb.Endpoint.subscribe("tweets:created")

    {:ok, assign(socket, pending_tweets: 0) |> assign_tweets()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("load-pending-tweets", _, socket) do
    socket.assigns.tweets
    |> Enum.map(&unsubscribe(&1.id))

    {:noreply, socket |> assign_tweets() |> assign(pending_tweets: 0)}
  end

  def handle_event("like", %{"id" => id}, socket) do
    tweet =
      socket.assigns.tweets
      |> Enum.find(&(&1.id == id))
      |> Twitter.Tweets.Tweet.like!(actor: socket.assigns.current_user)
      |> Map.put(:liked_by_user, true)

    {:noreply, assign(socket, :tweets, replace_tweet(socket.assigns.tweets, tweet))}
  end

  @impl true
  def handle_event("dislike", %{"id" => id}, socket) do
    tweet =
      socket.assigns.tweets
      |> Enum.find(&(&1.id == id))
      |> Twitter.Tweets.Tweet.dislike!(actor: socket.assigns.current_user)
      |> Map.put(:liked_by_user, false)

    {:noreply, assign(socket, :tweets, replace_tweet(socket.assigns.tweets, tweet))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Twitter.Tweets.Tweet.get!()
    |> Twitter.Tweets.Tweet.destroy!()

    {:noreply, assign(socket, :tweets, remove_tweet(socket.assigns.tweets, id))}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "tweets:created",
          payload: %Ash.Notifier.Notification{data: %{id: id}, from: from}
        },
        socket
      ) do
    # This is a tweet we just published
    if from == self() do
      tweet = Twitter.Tweets.Tweet.get!(id, load: tweet_load(socket.assigns.current_user))
      {:noreply, assign(socket, :tweets, [tweet | socket.assigns.tweets])}
    else
      id
      |> Twitter.Tweets.Tweet.get!(
        load:
          tweet_load(socket.assigns.current_user) ++
            [visible_to: %{user_id: socket.assigns.current_user.id}]
      )
      |> case do
        %{visible_to: true} ->
          {:noreply, assign(socket, :pending_tweets, socket.assigns.pending_tweets + 1)}

        _ ->
          {:noreply, socket}
      end
    end
  end

  def handle_info(%Phoenix.Socket.Broadcast{topic: "tweets:liked:" <> id}, socket) do
    {:noreply, assign(socket, :tweets, tweet_liked(socket.assigns.tweets, id))}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{topic: "tweets:unliked:" <> id}, socket) do
    {:noreply, assign(socket, :tweets, tweet_unliked(socket.assigns.tweets, id))}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Tweet")
    |> assign(:tweet, Twitter.Tweets.Tweet.get!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tweet")
    |> assign(:tweet, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tweets")
    |> assign(:tweet, nil)
  end

  defp assign_tweets(socket) do
    tweets =
      Twitter.Tweets.Tweet.feed!(socket.assigns.current_user.id,
        load: tweet_load(socket.assigns.current_user)
      )

    Enum.map(tweets, &subscribe/1)
    assign(socket, tweets: tweets)
  end

  defp remove_tweet(tweets, id) do
    unsubscribe(id)
    Enum.reject(tweets, &(&1.id == id))
  end

  defp replace_tweet(tweets, tweet) do
    Enum.map(tweets, fn current_tweet ->
      if current_tweet.id == tweet.id do
        tweet
      else
        current_tweet
      end
    end)
  end

  defp subscribe(tweet) do
    TwitterWeb.Endpoint.subscribe("tweets:liked:#{tweet.id}")
    TwitterWeb.Endpoint.subscribe("tweets:unliked:#{tweet.id}")
  end

  defp unsubscribe(id) do
    TwitterWeb.Endpoint.unsubscribe("tweets:liked:#{id}")
    TwitterWeb.Endpoint.unsubscribe("tweets:unliked:#{id}")
  end

  defp tweet_liked(tweets, id) do
    update_tweet(tweets, id, &%{&1 | like_count: &1.like_count + 1})
  end

  defp tweet_unliked(tweets, id) do
    update_tweet(tweets, id, &%{&1 | like_count: &1.like_count - 1})
  end

  defp update_tweet(tweets, id, func) do
    Enum.map(tweets, fn tweet ->
      if tweet.id == id do
        func.(tweet)
      else
        tweet
      end
    end)
  end

  defp tweet_load(current_user) do
    [
      :author_email,
      :like_count,
      liked_by_user: %{user_id: current_user.id}
    ]
  end
end
