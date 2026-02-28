ExUnit.start()

unless match?({_, 0}, System.cmd("dotnet", ["--version"], stderr_to_stdout: true)) do
  ExUnit.configure(exclude: [:dotnet])
end
