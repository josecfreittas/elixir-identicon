defmodule Identicon do
  def generate(input) do
    slug = Slugger.slugify(input)

    slug
    |> hash_input()
    |> pick_color()
    |> build_grid()
    |> filter_odd_squares()
    |> build_pixel_map()
    |> draw_image()
    |> save_image(slug)
  end

  defp hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end

  defp pick_color(%Identicon.Image{hex: [red, green, blue | _]} = image) do
    %Identicon.Image{image | color: {red, green, blue}}
  end

  defp build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(fn [first, second, _] = row -> row ++ [second, first] end)
      |> List.flatten()
      |> Enum.with_index()

    %Identicon.Image{image | grid: grid}
  end

  defp filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    filtered_grid = Enum.filter(grid, fn {code, _} -> rem(code, 2) == 0 end)
    %Identicon.Image{image | grid: filtered_grid}
  end

  defp build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      Enum.map(grid, fn {_, index} ->
        horizontal = rem(index, 5) * 50
        vertical = div(index, 5) * 50
        start = {horizontal, vertical}
        finish = {horizontal + 50, vertical + 50}
        {start, finish}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  defp draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, finish} ->
      :egd.filledRectangle(image, start, finish, fill)
    end)

    :egd.render(image)
  end

  defp save_image(image, slug) do
    File.write("generated/#{slug}.png", image)
  end
end
