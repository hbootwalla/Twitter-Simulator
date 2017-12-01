defmodule TweetParser do
    
    def getAllHandles(tweet) do
        if(String.contains?(tweet, "@")) do
           tweet = String.trim(tweet);
           list = List.flatten(Regex.scan(~r/[@]\w+/,tweet))
           Enum.map(list, fn(str) -> String.replace(str, "@", "") end)
        else
            []
        end
    end

    def getAllHashtags(tweet) do
        if(String.contains?(tweet, "#")) do
           tweet = String.trim(tweet);
           list = List.flatten(Regex.scan(~r/[#]\w+/,tweet))
           Enum.map(list, fn(str) -> String.replace(str,"@","") end)
        else
            []
        end
    end

end