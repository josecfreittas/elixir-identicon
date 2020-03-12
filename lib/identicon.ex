defmodule Identicon do
  @image_size {250, 250}
  @dest_folder "generated/"

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
    {total_width, total_height} = @image_size
    square_width = Kernel.trunc(total_width / 5)
    square_height = Kernel.trunc(total_height / 5)

    pixel_map =
      Enum.map(grid, fn {_, index} ->
        horizontal = rem(index, 5) * square_width
        vertical = div(index, 5) * square_height
        start = {horizontal, vertical}
        finish = {horizontal + square_width, vertical + square_height}
        {start, finish}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  defp draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    {width, height} = @image_size

    image = :egd.create(width, height)
    :egd.filledRectangle(image, {0, 0}, @image_size, :egd.color({225, 225, 225}))

    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, finish} ->
      :egd.filledRectangle(image, start, finish, fill)
    end)

    :egd.render(image)
  end

  defp save_image(image, slug) do
    File.write(@dest_folder <> "#{slug}.png", image)
  end
end
