defmodule Netler.Mix.Tasks.Netler.NewTest do
  use ExUnit.Case, async: false

  setup do
    original_shell = Mix.shell()
    on_exit(fn -> Mix.shell(original_shell) end)
    :ok
  end

  describe "run/1" do
    test "creates project files with correct content" do
      in_tmp_dir(fn ->
        Mix.shell(Mix.Shell.Process)
        send(self(), {:mix_shell_input, :prompt, "my_dotnet_project"})
        send(self(), {:mix_shell_input, :prompt, "4"}) # Select net9.0

        assert :ok == Mix.Tasks.Netler.New.run([])

        assert File.exists?("dotnet/my_dotnet_project/MyDotnetProject.csproj")
        assert File.exists?("dotnet/my_dotnet_project/Program.cs")
        assert File.exists?("lib/netler/my_dotnet_project.ex")

        csproj = File.read!("dotnet/my_dotnet_project/MyDotnetProject.csproj")
        assert csproj =~ "<TargetFramework>net9.0</TargetFramework>"
        refute csproj =~ "netcoreapp"

        program_cs = File.read!("dotnet/my_dotnet_project/Program.cs")
        assert program_cs =~ "namespace MyDotnetProject"
        refute program_cs =~ "System.Collections.Generic"

        ex_module = File.read!("lib/netler/my_dotnet_project.ex")
        assert ex_module =~ "defmodule Netler.MyDotnetProject"
        assert ex_module =~ "use Netler, dotnet_project: :my_dotnet_project"
      end)
    end

    test "returns :error when no project name given" do
      in_tmp_dir(fn ->
        Mix.shell(Mix.Shell.Process)
        send(self(), {:mix_shell_input, :prompt, ""})

        assert :error == Mix.Tasks.Netler.New.run([])
      end)
    end

    @tag :dotnet
    test "generated .csproj builds successfully" do
      in_tmp_dir(fn ->
        Mix.shell(Mix.Shell.Process)
        send(self(), {:mix_shell_input, :prompt, "my_dotnet_project"})
        send(self(), {:mix_shell_input, :prompt, "4"}) # Select net9.0

        :ok = Mix.Tasks.Netler.New.run([])

        {output, exit_code} =
          System.cmd(
            "dotnet",
            ["build", "dotnet/my_dotnet_project/MyDotnetProject.csproj"],
            stderr_to_stdout: true
          )

        assert exit_code == 0, "dotnet build failed:\n#{output}"
      end)
    end
  end

  defp in_tmp_dir(fun) do
    tmp =
      System.tmp_dir!()
      |> Path.join("netler_test_#{:erlang.unique_integer([:positive])}")

    File.mkdir_p!(tmp)

    try do
      File.cd!(tmp, fun)
    after
      File.rm_rf!(tmp)
    end
  end
end
