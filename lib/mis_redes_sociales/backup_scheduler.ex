defmodule MisRedesSociales.BackupScheduler do
  @moduledoc """
  Supervised GenServer that schedules and executes an automatic SQLite database
  backup every day at 01:00 AM (`America/Santiago`).
  """
  use GenServer
  require Logger

  alias MisRedesSociales.Backups

  @timezone "America/Santiago"
  @target_time ~T[01:00:00]

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  def ms_until_next_run(now_utc \\ DateTime.utc_now()) do
    {:ok, santiago_now} = DateTime.shift_zone(now_utc, @timezone)
    current_date = DateTime.to_date(santiago_now)
    current_time = DateTime.to_time(santiago_now)

    target_date =
      if Time.compare(current_time, @target_time) == :lt do
        current_date
      else
        Date.add(current_date, 1)
      end

    target_dt =
      case DateTime.new(target_date, @target_time, @timezone) do
        {:ok, dt} -> dt
        {:ambiguous, dt, _} -> dt
        {:gap, _before, dt} -> dt
      end

    max(DateTime.diff(target_dt, santiago_now, :millisecond), 1_000)
  end

  @impl true
  def init(opts) do
    now_fn = Keyword.get(opts, :now_fn, &DateTime.utc_now/0)
    backups_dir = Keyword.get(opts, :backups_dir, Backups.backups_dir())

    state = %{
      now_fn: now_fn,
      backups_dir: backups_dir,
      last_backup_date: nil,
      timer_ref: nil
    }

    {:ok, schedule_next(state)}
  end

  @impl true
  def handle_info(:run_backup, state) do
    now_utc = state.now_fn.()
    {:ok, santiago_now} = DateTime.shift_zone(now_utc, @timezone)
    today = DateTime.to_date(santiago_now)

    state =
      if state.last_backup_date == today do
        state
      else
        case Backups.create_backup(backups_dir: state.backups_dir, now: now_utc) do
          {:ok, path} ->
            Logger.info("Daily database backup created at #{path}")
            %{state | last_backup_date: today}

          {:error, reason} ->
            Logger.error("Daily database backup failed: #{inspect(reason)}")
            state
        end
      end

    {:noreply, schedule_next(state)}
  end

  defp schedule_next(state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    delay_ms = ms_until_next_run(state.now_fn.())
    ref = Process.send_after(self(), :run_backup, delay_ms)
    %{state | timer_ref: ref}
  end
end
