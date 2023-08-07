defmodule Tailscale.Event.User do
  alias Tailscale.User

  @type t :: %__MODULE__{
          event: :added | :removed | :changed,
          user_id: String.t(),
          username: String.t(),
          display_name: String.t()
        }

  defstruct event: nil, user_id: nil, username: nil, display_name: nil

  @spec compare_lists([User.t()], [User.t()]) :: [__MODULE__.t()]
  def compare_lists(old_users, new_users) do
    old_set = MapSet.new(old_users, fn user -> user.id end)
    new_set = MapSet.new(new_users, fn user -> user.id end)

    added_ids = MapSet.difference(new_set, old_set)
    removed_ids = MapSet.difference(old_set, new_set)
    unchanged_ids = MapSet.intersection(old_set, new_set) |> MapSet.to_list()

    added_events =
      new_users
      |> Enum.filter(fn u -> u.id in added_ids end)
      |> Enum.map(fn u -> added(u) end)

    removed_events =
      old_users
      |> Enum.filter(fn u -> u.id in removed_ids end)
      |> Enum.map(fn u -> removed(u) end)

    changed_events =
      unchanged_ids
      |> Enum.map(fn id ->
        old_user = Enum.find(old_users, fn user -> user.id == id end)
        new_user = Enum.find(new_users, fn user -> user.id == id end)

        case Map.equal?(old_user, new_user) do
          true -> nil
          false -> new_user
        end
      end)
      |> Enum.filter(&(&1 != nil))
      |> Enum.map(fn u -> changed(u) end)

    events = added_events ++ removed_events ++ changed_events

    events
  end

  defp make(event, %User{} = user) do
    %__MODULE__{
      event: event,
      user_id: user.id,
      username: user.username,
      display_name: user.display_name
    }
  end

  def added(%User{} = user), do: :added |> make(user)
  def removed(%User{} = user), do: :removed |> make(user)
  def changed(%User{} = user), do: :changed |> make(user)
end
