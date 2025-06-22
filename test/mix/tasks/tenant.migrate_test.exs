defmodule Mix.Tasks.Tenant.MigrateTest do
  use ExUnit.Case

  alias Mix.Tasks.Tenant.Migrate

  @repos [Tenant.PGTestRepo, Tenant.MySQLTestRepo]

  test "runs the migrator function" do
    for repo <- @repos do
      Migrate.run(["-r", repo, "--step=1", "--quiet"], fn args, direction ->
        assert args == ["-r", repo, "--step=1", "--quiet"]
        assert direction == :up
      end)
    end
  end
end
