defmodule TenantTest do
  use ExUnit.Case

  alias Tenant.Note
  import Tenant.TestHelper

  @migration_version 20_160_711_125_401
  @tenant "trilegal"

  setup_all :setup_repos

  setup do
    repos =
      for repo <- repos() do
        drop_tenants = fn ->
          Tenant.drop("lala", repo)
          Tenant.drop("lili", repo)
          Tenant.drop("lolo", repo)
          Tenant.drop(@tenant, repo)
        end

        drop_tenants.()
        on_exit(drop_tenants)

        repo
      end

    %{repos: repos}
  end

  test "create/2 must create a new tenant" do
    for repo <- repos() do
      Tenant.create("lala", repo)
      assert Tenant.exists?("lala", repo)
    end
  end

  test "create/2 must return a error if the tenant already exists", context do
    prefix = Tenant.config().tenant_prefix

    if Enum.member?(context.repos, Tenant.PGTestRepo) do
      assert {:ok, _} = Tenant.create("lala", Tenant.PGTestRepo)

      assert {:error, message} =
               Tenant.create("lala", Tenant.PGTestRepo)

      expected_error_msg =
        "ERROR 42P06 (duplicate_schema) schema \"#{prefix}lala\" already exists"

      assert message =~ expected_error_msg
    end

    if Enum.member?(context.repos, Tenant.MySQLTestRepo) do
      assert {:ok, _} = Tenant.create("lala", Tenant.MySQLTestRepo)

      assert {:error, message} =
               Tenant.create("lala", Tenant.MySQLTestRepo)

      expected_error_msg = "(1007): Can't create database \'#{prefix}lala\'; database exists"
      assert message =~ expected_error_msg
    end
  end

  test "create/2 must return a error if the tenant is reserved" do
    for repo <- repos() do
      assert {:error, msg} = Tenant.create("www", repo)

      assert msg ==
               """
               You cannot create the schema because \"www\" is a reserved
               tenant
               """
    end
  end

  test "create_schema/3 must rollback the tenant creation when function fails" do
    for repo <- repos() do
      result = {:error, "message"}

      assert Tenant.create_schema("lala", repo, fn "lala", ^repo ->
               assert Tenant.exists?("lala", repo)
               result
             end) == result

      refute Tenant.exists?("lala", repo)
    end
  end

  test "drop/2 must drop a existent tenant" do
    for repo <- repos() do
      Tenant.create("lala", repo)
      Tenant.drop("lala", repo)
      refute Tenant.exists?("lala", repo)
    end
  end

  test "rename/3 must drop a existent tenant" do
    for repo <- repos() do
      Tenant.create("lala", repo)
      Tenant.rename("lala", "lolo", repo)
      refute Tenant.exists?("lala", repo)
      assert Tenant.exists?("lolo", repo)
    end
  end

  test "all/1 must return all tenants" do
    for repo <- repos() do
      Tenant.create("lala", repo)
      Tenant.create("lili", repo)
      Tenant.create("lolo", repo)
      assert MapSet.new(Tenant.all(repo)) == MapSet.new(["lala", "lili", "lolo"])
    end
  end

  test "exists?/2 for a not created tenant returns false" do
    for repo <- repos() do
      refute Tenant.exists?("lala", repo)
      refute Tenant.exists?("lili", repo)
      refute Tenant.exists?("lulu", repo)
    end
  end

  test "exists?/2 for a reserved tenants returns false" do
    for repo <- repos() do
      tenants = Enum.filter(Tenant.reserved_tenants(), &(!is_struct(&1, Regex)))
      tenants = ["pg_lol", "pg_cow" | tenants]

      for tenant <- tenants do
        refute Tenant.exists?(tenant, repo)
      end
    end
  end

  test "reserved_tenant?/1 returns if the given tenant is reserved" do
    assert Tenant.reserved_tenant?(%{id: "www"}) == true
    assert Tenant.reserved_tenant?("www") == true
    assert Tenant.reserved_tenant?(%{id: "bla"}) == false
    assert Tenant.reserved_tenant?("bla") == false
  end

  test "migrations_path/1 must return the tenant migrations path" do
    for repo <- repos() do
      folder = repo |> Module.split() |> List.last() |> Macro.underscore()
      expected = Application.app_dir(:tenant, "priv/#{folder}/tenant_migrations")
      assert Tenant.migrations_path(repo) == expected
    end
  end

  test "migrate/2 migrates the tenant forward by default" do
    for repo <- repos() do
      create_tenant_schema(repo)

      assert_creates_notes_table(repo, fn ->
        {status, versions} = Tenant.migrate(@tenant, repo)

        assert status == :ok
        assert versions == [@migration_version]
      end)
    end
  end

  test "migrate/2 returns an error tuple when it fails" do
    for repo <- repos() do
      create_and_migrate_tenant(repo)

      force_migration_failure(repo, fn expected_error ->
        {status, error_message} = Tenant.migrate(@tenant, repo)
        assert status == :error
        assert error_message =~ expected_error
      end)
    end
  end

  test "migrate/2 works when invoked with list of tenants from all/1" do
    for repo <- repos() do
      Tenant.create("lala", repo)
      Tenant.create("lili", repo)
      Tenant.create("lolo", repo)

      result =
        Tenant.all(repo)
        |> Enum.map(fn t -> Tenant.migrate(t, repo) end)

      assert result == [ok: [], ok: [], ok: []]
    end
  end

  test "to_prefix/2 must apply the given prefix to the tenant name" do
    assert Tenant.to_prefix("a", nil) == "a"
    assert Tenant.to_prefix(%{id: "a"}, nil) == "a"
    assert Tenant.to_prefix("a", "b") == "ba"
    assert Tenant.to_prefix(%{id: "a"}, "b") == "ba"
  end

  defp assert_creates_notes_table(repo, fun) do
    assert_notes_table_is_dropped(repo)
    fun.()
    assert_notes_table_is_present(repo)
  end

  defp assert_notes_table_is_dropped(repo) do
    error =
      case repo.__adapter__() do
        Ecto.Adapters.MyXQL -> MyXQL.Error
        Ecto.Adapters.Postgres -> Postgrex.Error
      end

    assert_raise error, fn ->
      find_tenant_notes(repo)
    end
  end

  defp assert_notes_table_is_present(repo) do
    assert find_tenant_notes(repo) == []
  end

  defp create_and_migrate_tenant(repo) do
    Tenant.create(@tenant, repo)
  end

  defp create_tenant_schema(repo) do
    Tenant.create_schema(@tenant, repo)
  end

  defp find_tenant_notes(repo) do
    query =
      Note
      |> Ecto.Queryable.to_query()
      |> Map.put(:prefix, Tenant.to_prefix(@tenant))

    repo.all(query)
  end

  defp force_migration_failure(repo, migration_function) do
    prefix = Tenant.config().tenant_prefix

    sql =
      case repo.__adapter__() do
        Ecto.Adapters.MyXQL ->
          """
          DELETE FROM #{prefix}#{@tenant}.schema_migrations
          """

        _ ->
          """
          DELETE FROM "#{prefix}#{@tenant}"."schema_migrations"
          """
      end

    {:ok, _} = Ecto.Adapters.SQL.query(repo, sql, [])

    if repo.__adapter__() == Ecto.Adapters.MyXQL do
      migration_function.("(1050) (ER_TABLE_EXISTS_ERROR) Table 'notes' already exists")
    else
      migration_function.("ERROR 42P07 (duplicate_table) relation \"notes\" already exists")
    end
  end
end
