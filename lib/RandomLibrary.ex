defmodule Twitter.RandomLibrary do

# These randomizer functions for generating random userID is taken from https://gist.github.com/ahmadshah/8d978bbc550128cca12dd917a09ddfb7 
# and modified to suit the needs of this project


def randomizer(length, type \\ :all) do

alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
numbers = "0123456789"

lists = cond do
type == :alpha -> alphabets <> String.downcase(alphabets)
type == :numeric -> numbers
type == :upcase -> alphabets
type == :downcase -> String.downcase(alphabets)
true -> alphabets <> String.downcase(alphabets) <> numbers
end |> String.split("", trim: true)
do_randomizer(length, lists) 
end

defp get_range(length) when length > 1, do: (1..length)
defp get_range(length), do: [1]

defp do_randomizer(length, lists) do
    get_range(length) |> Enum.reduce([], fn(_, acc) -> [Enum.random(lists) | acc] end) |> Enum.join("")
end

def get_random_id() do
randomizer(9,:alpha)
end

end

