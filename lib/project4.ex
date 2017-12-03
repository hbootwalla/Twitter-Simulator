# ClientState GenServer is used to store the tweets, followers and followed users
# for each simulated client

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
      # Choice determines if server(0) should be started or if client simulator(1) should be started
      # Count determines how many clients should be simulated
      # ipAddr is the IP Address of the local machine on which the simulator is run

      if(choice === "0") do
        Node.start(String.to_atom("twitterServer@#{ipAddr}"));
        Node.set_cookie(String.to_atom("tweet"));
        TwitterServer.start_link      
      else
        Node.start(String.to_atom("twitterClient@#{ipAddr}"));
        Node.set_cookie(String.to_atom "tweet");
        sname = String.to_atom("twitterServer@#{ipAddr}")
        Node.connect(sname);
        count = String.to_integer count;
        spawn(fn -> ClientSimulator.simulateClients({TwitterServer, sname}, count) end);
      end
      :timer.sleep(:infinity)
  end
end
