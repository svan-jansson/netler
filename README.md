<p align="center">
    <img src="logo/netler.svg" alt="netler logo" height="150px">
</p>

[![Build Status](https://github.com/svan-jansson/netler/actions/workflows/build-test-publish.yml/badge.svg)](https://github.com/svan-jansson/netler/actions/workflows/build-test-publish.yml)
[![Hex pm](https://img.shields.io/hexpm/v/netler.svg?style=flat)](https://hex.pm/packages/netler)
[![Hex pm](https://img.shields.io/hexpm/dt/netler.svg?style=flat)](https://hex.pm/packages/netler)

# Netler

Enables language interoperability between Elixir and .NET. Heavily inspired by Rustler's convenient workflows. Full docs are available on [https://hexdocs.pm/netler/](https://hexdocs.pm/netler/).

## Getting Started

Before continuing, ensure that the [.NET Core SDK](https://dotnet.microsoft.com/download) is installed on the machine.

### 1. Add Netler to Your Dependencies

```elixir
defp deps do
    [
        {:netler, "~> 0.4"}
    ]
end
```

### 2. Run a Mix Task to Generate .NET Project and Elixir Module

```bash
> mix netler.new
```

You will be asked to give the project a name. This name will be used for both the .NET project and the Elixir module. Here's an example of the output:

```text
Please give your .NET project a name: my_dotnet_project

Created ./dotnet/my_dotnet_project/MyDotnetProject.csproj
Created ./dotnet/my_dotnet_project/Program.cs
Created ./lib/<elixir project>/my_dotnet_project.ex

Microsoft (R) Build Engine
Copyright (C) Microsoft Corporation. All rights reserved.

  Restore completed in 355.64 ms

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:08.74

Done! Remember to add :my_dotnet_project to the dotnet_projects list in your application's mix.exs
```

### 3. Add Netler Compiler and .NET Project to mix.exs

Netler will automatically compile the .NET projects when you run `mix compile`, but you need to wire up the compiler in your `mix.exs` file. You must also specify which .NET projects that should be compiled and started together with the Elixir application.

```elixir
def project do
    [
        app: :my_elixir_application,
        version: "0.1.0",
        elixir: "~> 1.9",
        start_permanent: Mix.env() == :prod,
        deps: deps(),
        compilers: Mix.compilers() ++ [:netler],
        dotnet_projects: [:my_dotnet_project]
    ]
end
```

#### Project Options

The `dotnet_projects` keyword accepts a list of `atom` (project name) or `{atom, keyword}` (project name, options).

##### Autostart

If you want to handle the startup of the `Netler.Client` for an embedded .NET project manually you can pass the `autostart: false` option. It can be useful if you want to run multiple instances of a .NET project or want to supervise it from a different supervisor.

```elixir
def project do
    [
        ...,
        dotnet_projects: [
            {:my_dotnet_project, autostart: false}
        ]
    ]
end
```

### 4. Compile and Start your Elixir Application

```bash
> iex -S mix
```

You should now see how the Netler compiler starts MSBuild to compile your embedded .NET project. When the compilation is completed you should be able to call the Elixir module that was created by `mix netler.new` like this:

```elixir
iex(1)> MyElixirApplication.MyDotnetProject.add(2, 5)
{:ok, 7}
```

## Umbrella Projects

Netler supports umbrella applications. The child app is configured the same way as a standalone project.

### 1. Configure the Child App

Add `:netler` as a dependency and configure the compiler and `.NET` projects in the child app's `mix.exs`, just like you would for a standalone project:

```elixir
def project do
  [
    app: :my_child_app,
    version: "0.1.0",
    deps: [{:netler, "~> 0.4"}],
    compilers: Mix.compilers() ++ [:netler],
    dotnet_projects: [:my_dotnet_project]
  ]
end
```

### 2. Generate the .NET Project from Inside the Child App

Run `mix netler.new` from within the child app directory:

```bash
cd apps/my_child_app
mix netler.new
```

This creates `dotnet/` and `lib/` files relative to the child app.

### 3. Compile from the Umbrella Root

To trigger `.NET` compilation when running `mix compile` from the umbrella root. No additional dependency declaration is needed, netler is already available through the child app.


Netler will find each child app that declares `dotnet_projects` and compile them. The compiled binaries are placed under each child app's `priv/` directory.

## The Project Structure

### Embedded .NET Projects

.NET projects created with `mix netler.new` are stored in a folder called `dotnet` in the root of your Elixir project. You will find a `<project_name>.csproj` file and a `Program.cs` file, which is the entrypoint.

This is what the generated `Program.cs` looks like:

```csharp
using System;
using System.Threading.Tasks;
using Netler;
using Netler.Contracts;

namespace Cow
{
    class Program
    {
        static async Task Main(string[] args)
        {
            var port = Convert.ToInt32(args[0]);
            var clientPid = Convert.ToInt32(args[1]);

            var server = Server.Create((config) =>
                {
                    config.UsePort(port);
                    config.UseClientPid(clientPid);
                    config.UseRoutes((routes) =>
                    {
                        // Example routes:
                        routes.AddTyped("Add", (int a, int b) => a + b);
                        routes.AddTyped("Subtract", (int a, int b) => a - b);
                        routes.AddTyped("Multiply", (int a, int b) => a * b);
                        routes.AddTyped("Divide", (int a, int b) => a / Convert.ToDouble(b));

                        // More routes can be added here ...
                    });
                });

            await server.Start();
        }
    }
}
```

### Elixir Modules for Calling the Embedded .NET Projects

`mix netler.new` also creates an Elixir module that corresponds to the embedded .NET project that was created. The module is your API for interop with .NET.

```elixir
defmodule MyElixirApplication.MyDotnetProject do

  # This links the module to a specific .NET project
  use Netler, dotnet_project: :my_dotnet_project

  # Use invoke/2 or invoke!/2 to route a message to an exported .NET method
  def add(a, b), do: invoke("Add", [a, b])
  def subtract(a, b), do: invoke("Subtract", [a, b])
  def multiply(a, b), do: invoke("Multiply", [a, b])
  def divide(a, b), do: invoke("Divide", [a, b])
end
```
