defmodule MisRedesSociales.BackupSchedulerTest do
  use MisRedesSociales.DataCase, async: false

  alias MisRedesSociales.BackupScheduler

  test "calculates time until next 1:00 AM in America/Santiago and executes the scheduled daily backup once per day" do
    # 00:30:00 America/Santiago (UTC-3) -> 30 minutes (1_800_000 ms) until 01:00:00 same day
    before_1am_utc = ~U[2026-10-27 03:30:00Z]
    assert BackupScheduler.ms_until_next_run(before_1am_utc) == 1_800_000

    # 02:00:00 America/Santiago (UTC-3) -> 23 hours (82_800_000 ms) until 01:00:00 next day
    after_1am_utc = ~U[2026-10-27 05:00:00Z]
    assert BackupScheduler.ms_until_next_run(after_1am_utc) == 82_800_000

    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "mrs_scheduler_test_#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    pid =
      start_supervised!(
        {BackupScheduler,
         name: nil, backups_dir: tmp_dir, now_fn: fn -> ~U[2026-10-27 04:00:00Z] end}
      )

    send(pid, :run_backup)
    state_after_first = :sys.get_state(pid)

    assert state_after_first.last_backup_date == ~D[2026-10-27]
    assert File.ls!(tmp_dir) == ["backup_2026-10-27_01-00-00.db"]

    # Sending :run_backup again on the same Santiago day does not duplicate automatic backup
    :sys.replace_state(pid, fn state ->
      %{state | now_fn: fn -> ~U[2026-10-27 04:05:00Z] end}
    end)

    send(pid, :run_backup)
    _ = :sys.get_state(pid)

    assert File.ls!(tmp_dir) == ["backup_2026-10-27_01-00-00.db"]
  end
end
