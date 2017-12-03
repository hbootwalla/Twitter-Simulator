defmodule ClientState do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{});
  end

  def init(_) do
    {:ok, %{username: '', password: '', tweets: [], followers: [], following: []}}
  end

  def handle_call({:get_username}, _from, state) do
    {:reply, Map.get(state, :username), state}
  end

  def handle_call({:get_password}, _from, state) do
    {:reply, Map.get(state, :password), state}
  end

  def handle_call({:get_all_tweets}, _from, state) do
    {:reply, Map.get(state, :tweets), state}
  end

  def handle_call({:get_all_followers}, _from, state) do
    {:reply, Map.get(state, :followers), state}
  end

  def handle_call({:get_all_following}, _from, state) do
    {:reply, Map.get(state, :following), state}
  end

  def handle_call({:set_username, username}, _from, state) do
    {:reply, true, Map.put(state, :username, username)}
  end

  def handle_call({:set_password, password}, _from, state) do
    {:reply, true, Map.put(state, :password, password)}
  end

  def handle_call({:set_all_followers, followers}, _from, state) do
    {:reply, true, Map.put(state, :followers, followers)}
  end

  def handle_call({:get_tweet_count}, _from, state) do
    {:reply, Kernel.length(Map.get(state, :tweets, [])), state}
  end

  def handle_call({:get_followers_count}, _from, state) do
    {:reply, Kernel.length(Map.get(state, :followers, [])), state}
  end

  def handle_call({:get_following_count}, _from, state) do
    {:reply, Kernel.length(Map.get(state, :following, [])), state}
  end

  def handle_call({:set_all_following, following}, _from, state) do
    {:reply, true, Map.put(state, :following, following)}
  end

  def handle_cast({:set_all_tweets, tweets}, state) do
    {:noreply, Map.put(state, :tweets, tweets)}
  end

  def handle_cast({:set_tweet, tweet}, state) do
    tList = Map.get(state, :tweets)
    tList = [tweet]  ++ tList;
    {:noreply, Map.put(state, :tweets, tList)}
  end

end

defmodule Project4.CLI do
   
  def main(args \\ []) do
      [choice, count, ipAddr] = args
      if(choice === "0") do
        Node.start(String.to_atom("twitterServer@#{ipAddr}"));
        Node.set_cookie(String.to_atom("tweet"));
        TwitterServer.start_link
        
      :timer.sleep(:infinity)        
      else
        Node.start(String.to_atom("twitterClient@#{ipAddr}"));
        Node.set_cookie(String.to_atom "tweet");
        sname = String.to_atom("twitterServer@#{ipAddr}")
        IO.inspect Node.connect(sname);
        IO.inspect sname
        count = String.to_integer count;
        spawn(fn -> ClientSimulator.simulateClients({TwitterServer, sname}, count) end);
        #Process.sleep(15000);
        :timer.sleep(:infinity)
        #spawn(fn->ClientSimulator.printPerformanceMetrics({TwitterServer, sname}, count) end);
        #Process.sleep(5000);
        # ClientSimulator.printPerformanceMetrics({TwitterServer, sname}, count);
        # Process.sleep(2000);
        # ClientSimulator.printPerformanceMetrics({TwitterServer, sname}, count);
        #Process.exit(self(), :kill);
      end

      # IO.inspect TweetParser.getAllMentions("@huzinboots says @hb1 is here. @@This should be an error");
      # IO.inspect TweetParser.getAllHashtags("@huzinboots says @hb1 is here. #CoolLife");
  end
end
