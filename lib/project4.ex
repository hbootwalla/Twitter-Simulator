defmodule ClientState do
  
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :Client_State);
  end

  def init(:ok) do
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

  def handle_call({:set_all_tweets, tweets}, _from, state) do
    {:reply, true, Map.put(state, :tweets, tweets)}
  end

  def handle_call({:set_all_followers, followers}, _from, state) do
    {:reply, true, Map.put(state, :followers, followers)}
  end

  def handle_call({:set_all_following, following}, _from, state) do
    {:reply, true, Map.put(state, :following, following)}
  end

end

defmodule TwitterClientSimulator do
  def register_user(sname,pid, c_pid, username, password) do
    response = GenServer.call({:Twitter_Server, sname}, {:add_user, c_pid, username, password}, :infinity);
    if response === true do
      GenServer.call(pid, {:set_username, username});
      GenServer.call(pid, {:set_password, password});
      {:ok}
    else  
      {:not_ok, "User Handle Exists. Try Again."}
    end
  end

  def login_user(sname, pid,c_pid, username, password) do
    response = GenServer.call({:Twitter_Server, sname}, {:login_user, c_pid, username, password}, :infinity);
    case response do
    :logged_in ->
      GenServer.call(pid, {:set_username, username});
      GenServer.call(pid, {:set_password, password});
      {:ok}
    :unregistered ->
      {:not_ok, "Username is invalid. Try Again"}
    :incorrect_password ->
      {:not_ok, "Password is invalid. Try Again"}
    end
  end

  def logout_user(sname, pid, c_pid) do
    username = GenServer.call(pid, {:get_username});
    password = GenServer.call(pid, {:get_password});
    if(username === '' || password === '') do
      {:not_ok, "Logout Invalid at this stage"}
    else
      response = GenServer.call({:Twitter_Server, sname}, {:logout_user, c_pid, username, password}, :infinity);
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

  def addTweet(sname, pid, tweetText) do
    username = GenServer.call(pid, {:get_username});
    if(username === '') do
      {:not_ok, "User Not Logged In"}
    else
      GenServer.cast({:Twitter_Server, sname}, {:handle_tweet, {username, tweetText}});
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

  def testCode(sname, c_pid) do
    {:ok, pid} = ClientState.start_link

    register_user(sname, pid, c_pid, "huz1","sis");
    logout_user(sname, pid);

    register_user(sname,pid, c_pid, "huz2","sis");
    logout_user(sname, pid);

    register_user(sname,pid, c_pid, "huz3","sis");
    logout_user(sname, pid);

    register_user(sname,pid, c_pid, "huz4","sis");
    logout_user(sname, pid);

    #IO.inspect register_user(sname,pid, "huz","sis");
    login_user(sname,pid, c_pid, "huz1","sis");
    #IO.inspect login_user(sname,pid, "hu","sis");
    #IO.inspect login_user(sname,pid, "huz","si1s");
    addTweet(sname, pid, "@HuzInBoots mention you @huz2 in a comment. #LiveLife1");
    addTweet(sname, pid, "@Tazo mention you @HuzInBoots in a comment. #LiveLife2");
    # IO.inspect logout_user(sname, pid);

    # IO.inspect register_user(sname,pid, "huz2","sis");

    # IO.inspect addTweet(sname, pid, "@huz1 mention you @hb1 in a comment. #LiveLife2");
    IO.inspect getAllTweets(sname, pid);
    # IO.inspect logout_user(sname, pid);

    # IO.inspect login_user(sname,pid, "huz1","sis");
    # IO.inspect addTweet(sname, pid, "@huz1 mention you @huz2 in a comment. #LiveLife3");
    # IO.inspect getAllTweets(sname, pid);

    login_user(sname,pid, c_pid, "huz1","sis");
    subscribeToUser(sname,pid, "huz2");
    subscribeToUser(sname,pid, "huz3");
    logout_user(sname, pid);

    login_user(sname,pid, c_pid, "huz3","sis");
    subscribeToUser(sname,pid, "huz4");
    # logout_user(sname, pid);

    login_user(sname,pid, c_pid, "huz2","sis");
    subscribeToUser(sname,pid, "huz3");
    logout_user(sname, pid);

    login_user(sname,pid, c_pid,"huz1","sis");
    IO.inspect getAllFollowers(sname,pid);
    IO.inspect getAllFollowing(sname,pid);
    logout_user(sname, pid);

    login_user(sname,pid, "huz3","sis");
    IO.inspect getAllFollowers(sname,pid);
    IO.inspect getAllFollowing(sname,pid);
    logout_user(sname, pid);

  end

  def printTweets do
    receive do
      {:print_tweet, tweet} -> IO.puts tweet; 
    end
    printTweets
  end

  def simulateClients(count) do
    if count > 0 do
        Node.spawn_link(Node.self, fn -> 
        c_pid = spawn(fn -> printTweets end);
        testCode(sname, c_pid)
      end);
    end
  end



end

defmodule Project4.CLI do
  
  def registerNewUser(sname) do
    username = IO.gets "Enter username: ";
    password = IO.gets "Enter password: ";
    response = GenServer.call({:Twitter_Server, sname}, {:add_user, username, password});
    if(response == false) do
      IO.puts "User already registered. Try Again."; registerNewUser(sname);
    else
      user_window(sname);
    end
  end

  def loginUser(sname) do
    username = IO.gets "Enter username: ";
    password = IO.gets "Enter password: ";
    response = GenServer.call({:Twitter_Server, sname}, {:login_user, username, password});
    case response do
     :unregistered ->
      IO.puts "User not registered. Try Again."; main_window(sname);
    :incorrect_password ->
      IO.puts "Incorrect Password. Try Again."; loginUser(sname);
    _ ->
      user_window(sname);
    end
  end

  def user_window(sname) do
    IO.puts "1. Send a Tweet"
    IO.puts "2. Subscribe to a User"
    IO.puts "3. Retweet"
    IO.puts "4. Query a Tweet"
    choice = IO.gets "Enter choice: ";
  end



  def main_window(sname) do
    IO.puts "1. Register New User";
    IO.puts "2. Login";
    result = (IO.gets "Choose one of the above options: " |> IO.chardata_to_string);
    result = IO.chardata_to_string(result);
    case result do
      "1\n" -> registerNewUser(sname);
      "2\n" -> loginUser(sname); 
    end
  end

  # def keepAlive() do
  #   keepAlive()
  # end

  

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
        #main_window(sname);
        TwitterClientSimulator.simulateClients(sname, count)
        
      end
      :timer.sleep(:infinity)
      

      # IO.inspect TweetParser.getAllMentions("@huzinboots says @hb1 is here. @@This should be an error");
      # IO.inspect TweetParser.getAllHashtags("@huzinboots says @hb1 is here. #CoolLife");
  end
end
