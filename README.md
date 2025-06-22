# Tenant

[![Module Version](https://img.shields.io/hexpm/v/tenant.svg)](https://hex.pm/packages/tenant)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/tenant/)

A simple and effective way to build multitenant applications on top of Ecto.

[Documentation](https://hexdocs.pm/tenant/readme.html)

Tenant leverages database data segregation techniques (such as [Postgres schemas](https://www.postgresql.org/docs/current/static/ddl-schemas.html)) to keep tenant-specific data separated, while allowing you to continue using the Ecto functions you are familiar with.



## Quick Start

1. Add `tenant` to your list of dependencies in `mix.exs`:

   ```elixir
   def deps do
     [
       {:tenant, "~> 2.0.0"},
     ]
   end
   ```

2. Run in your shell:

   ```bash
   mix deps.get
   ```


## Configuration

Configure the Repo you will use to execute the database commands with:

    config :tenant, repo: ExampleApp.Repo

## Testing

The unit tests run, by default, against both PostgreSQL and MySQL. It is possible to run the tests
against only one or the other by setting the `TENANT_TEST_BACKENDS` environment variable to a
comma-separated list. The recognized values are `pgsql` and `mysql`.

This command would run only the PostgreSQL tests:

    TENANT_TEST_BACKENDS="pgsql" mix test

### Additional configuration for MySQL

In MySQL, each tenant will have its own MySQL database.
Tenant used to use a table called `tenants` in the main Repo to keep track of the different tenants.
If you wish to keep this behavior, generate the migration that will create the table by running:

```bash
mix tenant.mysql.install
```

And then create the table:

```bash
mix ecto.migrate
```

Finally, configure Tenant to use the `tenants` table:

```elixir
config :tenant, tenant_table: :"information_schema.schemata"
```

Otherwise, Tenant will continue to use the `information_schema.schemata` table as the default behavior for storing tenants.

## Usage

Here is a quick overview of what you can do with tenant!


### Creating, renaming and dropping tenants


#### To create a new tenant:

```elixir
Tenant.create("your_tenant")
```

This will create a new database schema and run your migrations—which may take a while depending on your application.


#### Rename a tenant:

```elixir
Tenant.rename("your_tenant", "my_tenant")
```

This is not something you should need to do often. :-)


#### Delete a tenant:

```elixir
Tenant.drop("my_tenant")
```

More information on the API can be found in [documentation](https://hexdocs.pm/tenant/Tenant.html#content).


### Creating tenant migrations

To create a migration to run across tenant schemas:

```bash
mix tenant.gen.migration your_migration_name
```

If migrating an existing project to use Tenant, you can move some or all of your existing migrations from `priv/YOUR_REPO/migrations` to  `priv/YOUR_REPO/tenant_migrations`.

Tenant and Ecto will automatically add prefixes to standard migration functions.  If you have _custom_ SQL in your migrations, you will need to use the [`prefix`](https://hexdocs.pm/ecto/Ecto.Migration.html#prefix/0) function provided by Ecto. e.g.

```elixir
def up do
  execute "CREATE INDEX name_trgm_index ON #{prefix()}.users USING gin (nam gin_trgm_ops);"
end
```


### Running tenant migrations:

```bash
mix tenant.migrate
```

This will migrate all of your existing tenants, one by one.  In the case of failure, the next run will continue from where it stopped.


### Using Ecto

Your Ecto usage only needs the `prefix` option.  Tenant provides a helper to coerce the tenant value into the proper format, e.g.:

```elixir
Repo.all(User, prefix: Tenant.to_prefix("my_tenant"))
Repo.get!(User, 123, prefix: Tenant.to_prefix("my_tenant"))
```


### Fetching the tenant with Plug

Tenant includes configurable plugs that you can use to load the current tenant in your application.

Here is an example loading the tenant from the current subdomain:

```elixir
plug Tenant.SubdomainPlug, endpoint: MyApp.Endpoint
```

For more information, check the `Tenant.Plug` documentation for an overview of our plugs.


## Thanks

This lib is inspired by the gem [apartment](https://github.com/influitive/apartment), which does the same thing in Ruby on Rails world. We also give credit (and a lot of thanks) to @Dania02525 for the work on [apartmentex](https://github.com/Dania02525/apartmentex).  A lot of the work here is based on what she has done there.  And also to @jeffdeville, who forked ([tenantex](https://github.com/jeffdeville/tenantex)) taking a different approach, which gave us additional ideas.

## Copyright and License

Copyright (c) 2017 ateliware

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.
