# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.0.0

### Renamed and development continued

Due to no releases having been made in six years despite reaching out to the previous
developers repeatedly over multiple years, Triplex was forked and renamed to Tenant.

### Fixes

- `Triplex.all` no longer returns tenants that do not match the configured rpefix (Aaron Seigo)
- `Triplex.all` no longer returns prefixes (Andre Barr)
- `mix triplex.migrations` fixed for Ecto 3 (Paul Ostazeski)

### Improvements

- Logging of SQL statements can be turned off with `config :tenant, log: false` (Thomas Cioppettini)
- Use information schema as the default behaviour for MySQL driver (Hammam Samara)

### Maintenance

- De-duplicate the `timestamp/0` function (Aaron Seigo)
- Support for myxql was added. Mariaex package was removed. Add the myxql package
  e.g `{:myxql, "~> 0.7"}` in your `mix.exs` file.
- Fix compiler warnings for Elixir >= 1.17 (Paul Ostazeski)

### Testing

- ` TENANT_TEST_BACKENDS` environment variable introduced which controls which backends
  to run tests for. A comma separated list of database names is expected.
  Defaults to `pgsql,mysql` (Aaron Seigo)

### Documentation

- Updated documentation (Kian-Meng Ang)


## v1.3.0 (2019-05-31)

### Bug fixes

- Fixed compilation error when optional adapters are not included in downstream project.

### Changed

- docker-compose configuration that allows easy setup for test databases.
- `Triplex.create/1,2` now rolls back the prefix creation if the `func` fails with error tuple
- Now we support to Ecto 3! :tada: But be aware that this new version does not support
the old versions of Ecto, only 3.0 and up

### Breaking changes

It's not our fault, but there is a breaking change if you upgrade it because migration on
Ecto 3 are ran on a different process.

The problem you may find is basically with this kind of code:

```elixir
Repo.transaction(fn ->
  {:ok, _} = Triplex.create("tenant")
  User.insert!(%{name: "Demo user 1"})
  User.insert!(%{name: "Demo user 2"})
end)
```

As `Triplex.create/1` runs the tenant migrations, and they will run on different processes,
you will get an error from your db saying that the given tenant prefix (schema or database
depending on the db) does not exist.

That occurs because the new processes will checkout a new connection to db, making them
not aware of the current transaction, since it is on another db connection. But don't panic,
we have a solution for you!

Here is how you could achieve the same results on success or fail:

```elixir
Triplex.create_schema("tenant", Repo, fn(tenant, repo) ->
  Repo.transaction(fn ->
    {:ok, _} = Triplex.migrate(tenant, repo)
    User.insert!(%{name: "Demo user 1"})
    User.insert!(%{name: "Demo user 2"})

    tenant
  end)
end)
```

For more details about these function check the online documentation for `Triplex.create/1,2`
and `Triplex.create_schema/1,2,3`.

## v1.3.0-rc.1 (2019-03-07)

### Bug fixes

- Fixed compilation error when optional adapters are not included in downstream project.

### Changed

- docker-compose configuration that allows easy setup for test databases.

## v1.3.0-rc.0 (2019-03-03)

### Added

- Support to MySQL :dolphin:

### Changed

- `Triplex.create/1,2` now rolls back the prefix creation if the `func` fails with error tuple
- Now we support to Ecto 3! :tada: But be aware that this new version does not support
the old versions of Ecto, only 3.0 and up

### Breaking changes

It's not our fault, but there is a breaking change if you upgrade it because migration on
Ecto 3 are ran on a different process.

The problem you may find is basically with this kind of code:

```elixir
Repo.transaction(fn ->
  {:ok, _} = Triplex.create("tenant")
  User.insert!(%{name: "Demo user 1"})
  User.insert!(%{name: "Demo user 2"})
end)
```

As `Triplex.create/1` runs the tenant migrations, and they will run on different processes,
you will get an error from your db saying that the given tenant prefix (schema or database
depending on the db) does not exist.

That occurs because the new processes will checkout a new connection to db, making them
not aware of the current transaction, since it is on another db connection. But don't panic,
we have a solution for you!

Here is how you could achieve the same results on success or fail:

```elixir
Triplex.create_schema("tenant", Repo, fn(tenant, repo) ->
  Repo.transaction(fn ->
    {:ok, _} = Triplex.migrate(tenant, repo)
    User.insert!(%{name: "Demo user 1"})
    User.insert!(%{name: "Demo user 2"})

    tenant
  end)
end)
```

For more details about these function check the online documentation for `Triplex.create/1,2`
and `Triplex.create_schema/1,2,3`.
