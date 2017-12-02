defmodule ClientState do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, []);
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

  def handle_call({:set_all_following, following}, _from, state) do
    {:reply, true, Map.put(state, :following, following)}
  end

  def handle_cast({:set_all_tweets, tweets}, state) do
    IO.inspect tweets;
    {:noreply, Map.put(state, :tweets, tweets)}
  end

  def handle_cast({:set_tweet, tweet}, state) do
    tList = Map.get(state, :tweets)
    tList = [tweet]  ++ tList;
    {:noreply, Map.put(state, :tweets, tList)}
  end

end

defmodule TwitterClientSimulator do
  def register_user(sname, gen_pid, c_pid, username, password) do
    response = GenServer.call({:Twitter_Server, sname}, {:add_user, c_pid, username, password}, :infinity);
    if response === true do
      GenServer.call(gen_pid, {:set_username, username});
      GenServer.call(gen_pid, {:set_password, password});
      {:ok}
    else  
      {:not_ok, "User Handle Exists. Try Again."}
    end
  end

  def login_user(sname, c_pid, gen_pid, username, password) do
    response = GenServer.call({:Twitter_Server, sname}, {:login_user, c_pid, username, password}, :infinity);
    GenServer.cast({:Twitter_Server, sname}, {:get_all_tweets, c_pid, gen_pid, username, password});
    case response do
      :logged_in ->
      GenServer.call(gen_pid, {:set_username, username});
      GenServer.call(gen_pid, {:set_password, password});
      {:ok}
    :unregistered ->
      {:not_ok, "Username is invalid. Try Again"}
    :incorrect_password ->
      {:not_ok, "Password is invalid. Try Again"}
    end
  end

  def logout_user(sname, pid) do
    username = GenServer.call(pid, {:get_username});
    password = GenServer.call(pid, {:get_password});
    if(username === '' || password === '') do
      {:not_ok, "Logout Invalid at this stage"}
    else
      response = GenServer.call({:Twitter_Server, sname}, {:logout_user, username, password}, :infinity);
      if response === true do
        GenServer.call(pid, {:set_username, ''});
        GenServer.call(pid, {:set_password, ''});
        {:ok}
      else  
        {:not_ok, "Unable to logout"}
      end
    end
  end

  def getAllTweets(sname, pid) do
    username = GenServer.call(pid, {:get_username});
    if(username === '') do
      {:not_ok, "User Not Logged In"}
    else
      response = GenServer.call({:Twitter_Server, sname}, {:get_all_tweets, username}, :infinity);
      {:ok, List.flatten response}
    end
  end

  def addTweet(sname, gen_pid, c_pid, tweetText) do
    username = GenServer.call(gen_pid, {:get_username});
    if(username === '') do
      {:not_ok, "User Not Logged In"}
    else
      GenServer.cast({:Twitter_Server, sname}, {:handle_tweet, username, gen_pid, c_pid,  tweetText});
      {:ok}
    end
  end

  def subscribeToUser(sname, pid, subscribedUser) do
    username = GenServer.call(pid, {:get_username});
    if(username === '') do
      {:not_ok, "User Not Logged In"}
    else
      GenServer.cast({:Twitter_Server, sname}, {:subscribe_to_user, username, subscribedUser});
      {:ok}
    end
  end

  def getAllFollowers(sname, pid) do
    username = GenServer.call(pid, {:get_username});
    if(username === '') do
      {:not_ok, "User Not Logged In"}
    else
      response = GenServer.call({:Twitter_Server, sname}, {:get_all_followers, username}, :infinity);
      {:ok, List.flatten response}
    end
  end

  def getAllFollowing(sname, pid) do
    username = GenServer.call(pid, {:get_username});
    if(username === '') do
      {:not_ok, "User Not Logged In"}
    else
      response = GenServer.call({:Twitter_Server, sname}, {:get_all_following, username}, :infinity);
      {:ok, List.flatten response}
    end
  end

  def retweetToSubscribers(sname, gen_pid) do
    username = GenServer.call(gen_pid, {:get_username});
    if(username === '') do
      {:not_ok, "User Not Logged In"}
    else
      GenServer.cast({:Twitter_Server, sname}, {:retweet, username});
      {:ok}
    end
  end


  def testCode(sname, uname, c_pid) do
    {:ok, gen_pid} = ClientState.start_link

    register_user(sname, gen_pid, c_pid, uname ,"sis");
    case uname do
      "huz1" ->
        IO.puts "huz1"
      #Process.sleep(100);
      addTweet(sname, gen_pid, c_pid, "Hello, #supposedly");
      addTweet(sname, gen_pid, c_pid, "Goodbye, #supposedly");
      
      subscribeToUser(sname, gen_pid, "huz2");
      
      #logout_user(sname, pid);
      # login_user(sname, c_pid, gen_pid, "huz1", "sis");
      # addTweet(sname, gen_pid, c_pid, "@huz2 is my friend also okay??!, #supposedlyAgain");
      # login_user(sname,  c_pid, gen_pid, "huz1", "sis");
    "huz2" -> 
      IO.puts "huz2"
      Process.sleep(1000);
      #addTweet(sname, pid, "Hello, @huz1 is Hussain");
      retweetToSubscribers(sname, gen_pid);
    "huz3" ->
      # logout_user(sname, gen_pid);
      # Process.sleep(5000)
      # login_user(sname, c_pid, gen_pid, "huz3","sis");
      subscribeToUser(sname, gen_pid, "huz2");
    end

    # if uname === "huz1" do
    #   addTweet(sname, gen_pid, c_pid, "@huz2 is my friend, #supposedly");
    # else
    #   Process.sleep(1000);
    # end

  end

  def printTweets do
    receive do
      {:print_tweet, username, tweet} -> IO.puts "** #{username} ** #{tweet}"; 
      {:get_all_tweets, g_pid, tweetList} -> GenServer.cast(g_pid, {:set_all_tweets, tweetList});
      {:add_tweet,g_pid, tweetId, tweetText} -> GenServer.cast(g_pid, {:set_tweet, {tweetId, tweetText}});
    end
    printTweets
  end

  def simulateClients(sname, count) do
    if count > 0 do
        spawn(fn -> 
          c_pid = spawn(fn -> printTweets end);
          uname = "huz#{count}";
          testCode(sname, uname, c_pid) end);
      simulateClients(sname, count - 1)
    end
  end

end

defmodule Project4.CLI do
   
  def main(args \\ []) do
      [choice, count] = args
      if(choice == "0") do
        IO.inspect Node.start(String.to_atom("twitterServer@192.168.56.1"));
        IO.inspect Node.set_cookie(String.to_atom("tweet"));
        TwitterServer.start_link        
      else
        IO.inspect Node.start(String.to_atom("twitterClient@192.168.56.1"));
        IO.inspect Node.set_cookie(String.to_atom "tweet");
        sname = String.to_atom("twitterServer@192.168.56.1")
        IO.inspect Node.connect(sname);
        IO.inspect sname
        TwitterClientSimulator.simulateClients(sname, String.to_integer count)
      end
      :timer.sleep(:infinity)
      

      # IO.inspect TweetParser.getAllMentions("@huzinboots says @hb1 is here. @@This should be an error");
      # IO.inspect TweetParser.getAllHashtags("@huzinboots says @hb1 is here. #CoolLife");
  end
end
