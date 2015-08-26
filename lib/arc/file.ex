defmodule Arc.File do
  defstruct [:path, :file_name]

  # Given a remote file
  def new(remote_path = "http" <> _) do
    case save_file(remote_path) do
      {:ok, local_path} ->
          %Arc.File{path: local_path, file_name: Path.basename(local_path)}
      :error ->
        {:error, :bad_remote_file}
    end
  end

  # Accepts a path
  def new(path) when is_binary(path) do
    case File.exists?(path) do
      true -> %Arc.File{path: path, file_name: Path.basename(path)}
      false -> {:error, :no_file}
    end
  end

  # Accepts a map conforming to %Plug.Upload{} syntax
  def new(%{filename: filename, path: path}) do
    case File.exists?(path) do
      true -> %Arc.File{path: path, file_name: filename}
      false -> {:error, :no_file}
    end
  end

  defp save_file(remote_path) when is_binary(remote_path) do
    local_path =
      generate_temp_path
      |> Path.join(Path.basename(remote_path))

    case save_temp_file(local_path, remote_path) do
      :ok -> {:ok, local_path}
      _   -> :error
    end
  end

  defp save_temp_file(local_path, remote_path) do
    File.write(local_path, get_remote_file(remote_path))
  end

  defp get_remote_file(remote_path) do
    {:ok, {{'HTTP/1.1', _, _}, _, body}} =
      :httpc.request(:get, {String.to_char_list(remote_path), []}, [], [])

    body
  end

  defp generate_temp_path do
    rand = Base.encode32(:crypto.rand_bytes(20), case: :lower)
    temp_path = Path.join(System.tmp_dir, rand)
    File.mkdir_p(temp_path)
    temp_path
  end

end
