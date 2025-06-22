import Config

test_repos =
  (System.get_env("TENANT_TEST_BACKENDS") || "pgsql,mysql")
  |> String.split(",")
  |> Enum.map(fn backend ->
    case backend do
      "pgsql" -> Tenant.PGTestRepo
      "mysql" -> Tenant.MySQLTestRepo
    end
  end)

# Configure tenant
config :tenant,
  reserved_tenants: [
    "www",
    "api",
    "admin",
    "security",
    "app",
    "staging",
    "tenant_test",
    "travis",
    ~r/^db\d+$/
  ]

config :tenant, tenant_table: :tenants

# Configure your database
config :tenant, ecto_repos: test_repos

config :tenant, Tenant.PGTestRepo,
  username: System.get_env("PG_USERNAME") || "postgres",
  password: System.get_env("PG_PASSWORD") || "postgres",
  hostname: System.get_env("PG_HOST") || "localhost",
  database: "tenant_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :tenant, Tenant.MySQLTestRepo,
  username: System.get_env("MS_USERNAME") || "root",
  password: System.get_env("MS_PASSWORD") || "",
  hostname: System.get_env("MS_HOST") || "localhost",
  database: "tenant_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning
