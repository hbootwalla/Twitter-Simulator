defmodule Twitter.RandomLibrary do



#this randomizer function for generating random string is taken from https://gist.github.com/ahmadshah/8d978bbc550128cca12dd917a09ddfb7 and modified to suit the needs of this project


@moduledoc """

Random string generator module.

"""


@doc """

Generate random string based on the given legth. It is also possible to generate certain type of randomise string using the options below:

* :all - generate alphanumeric random string

* :alpha - generate nom-numeric random string

* :numeric - generate numeric random string

* :upcase - generate upper case non-numeric random string

* :downcase - generate lower case non-numeric random string

## Example

iex> Iurban.String.randomizer(20) //"Je5QaLj982f0Meb0ZBSK"

"""

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


@doc false

defp get_range(length) when length > 1, do: (1..length)

defp get_range(length), do: [1]


@doc false

defp do_randomizer(length, lists) do

    get_range(length) |> Enum.reduce([], fn(_, acc) -> [Enum.random(lists) | acc] end) |> Enum.join("")

end


#generate the input atom

def get_random_id() do

randomizer(9,:alpha)

end


def getZipfDist(numberofClients) do

distList=[]

s=1

c=getConstantValue(numberofClients,s)

distList=Enum.map(1..numberofClients,fn(x)->:math.ceil((c*numberofClients)/:math.pow(x,s))
end)

distList

end


defp getConstantValue(numberofClients,s) do

k=Enum.reduce(1..numberofClients,0,fn(x,acc)->:math.pow(1/x,s)+acc
end )

k=1/k

k

end

end

