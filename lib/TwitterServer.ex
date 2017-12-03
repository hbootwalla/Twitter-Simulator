defmodule TwitterServer do
    use GenServer

    def init(:ok) do
        DatabaseHandler.init();
        {:ok, %{tweetCount: 0}}
    end

    def start_link do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__);
        spawn(fn -> printPerformanceMetrics(); end);
    end

    def handle_call({:add_user, c_pid, username, password}, _from , state) do
        returnValue = :ets.insert_new(:user_table, {username, password});
        DatabaseHandler.setUserPidByName(username, c_pid)
        {:reply, returnValue, state}
    end

    def handle_call({:login_user, c_pid, username, password}, _from , state) do
        returnValue = :ets.lookup(:user_table, username);
        DatabaseHandler.setUserPidByName(username, c_pid)
        if(returnValue == []) do
            {:reply, :unregistered, state}
        else
            [{username,returnedPassword}] = returnValue
            if(returnedPassword != password) do
                {:reply, :incorrect_password, state} 
            else
                IO.puts "#{username} has LOGGED IN";
                {:reply, :logged_in, state}
            end
        end
    end

    def handle_call({:logout_user, username, password}, _from , state) do
        DatabaseHandler.setUserPidByName(username, nil)
        IO.puts "#{username} has LOGGED OUT";
        {:reply, true, state}
    end

    def handle_call({:get_all_following, user}, _from ,state) do
        followingList = DatabaseHandler.getAllFollowing(user)
        {:reply, followingList, state}
    end

    def handle_call({:get_all_followers, user}, _from ,state) do
        followersList = DatabaseHandler.getAllFollowers( user)
        {:reply, followersList, state}
    end

    # def handle_call({:print_metrics, count}, _from, state) do
    #     printPerformanceMetrics(count);
    #     {:reply, true, state}
    # end

    def handle_cast({:return_something}, state) do
        IO.puts "!!";
        {:noreply, state}
    end

    def handle_cast({:handle_tweet, user, gen_pid, print_pid, tweetText}, state) do
        handles = TweetParser.getAllHandles(tweetText);
        hashtags = TweetParser.getAllHashtags(tweetText);
        tweetId = Map.get(state, :tweetCount) + 1;
        DatabaseHandler.insertTweet(tweetId, user, tweetText);
        Enum.map(handles, fn (handle) -> DatabaseHandler.insertHandleTweet(handle, tweetId) end);
        Enum.map(hashtags, fn (hashtag) -> DatabaseHandler.insertHashtagTweet(hashtag, tweetId) end);

        #send Tweet to Followers
        followersList = DatabaseHandler.getAllFollowers(user)
        Enum.map(followersList, fn follower -> sendTweetToUser(follower, tweetId, tweetText) end);
        
        #send Tweet to Mentions
         Enum.map(handles, fn handle -> sendTweetToUser(handle, tweetId, tweetText) end);
         
         send(print_pid, {:add_tweet, tweetId, tweetText});
         {:noreply, Map.put(state, :tweetCount, Map.get(state, :tweetCount) + 1)}

    end

    def handle_cast({:subscribe_to_user, user, subscribedUser}, state) do
        DatabaseHandler.addUserToFollowingList(user, subscribedUser);
        DatabaseHandler.addUserToFollowersList(subscribedUser, user);
        {:noreply, state}
    end

    def handle_cast({:get_all_tweets, c_pid, username, password}, state) do
        tweetList= DatabaseHandler.getAllTweetsByUser(username);
        send(c_pid, {:get_all_tweets, tweetList});
        {:noreply, state}
    end

    def handle_cast({:retweet, username, gen_pid}, state) do
        [tweetId, tweetText] = DatabaseHandler.getRandomTweet(:tweet_table);
        followers = DatabaseHandler.getAllFollowers(username);
        Enum.map(followers, fn follower -> sendTweetToUser(follower, tweetId, tweetText) end);
        {:noreply, state}
    end

    def handle_cast({:get_all_subscribed_users_tweets, username, print_pid}, state) do
        tweets = DatabaseHandler.getSubscribedUsersTweets(username);
        send(print_pid, {:query_all_sub_tweets, tweets});
        {:noreply, state}
    end

    def handle_cast({:get_tweets_by_hashtag, hashtag, print_pid}, state) do
        tweets = DatabaseHandler.getAllTweetsByHashtag(hashtag);
        send(print_pid, {:query_tweets_by_hashtag, hashtag, tweets});
        {:noreply, state}
    end

    def handle_cast({:get_tweets_by_handle, handle, print_pid}, state) do
        tweets = DatabaseHandler.getAllTweetsByHandle(handle);
        send(print_pid, {:query_tweets_by_handle, handle, tweets});
        {:noreply, state}
    end

    # def handle_cast({:return_something}, state) do
    #     {:noreply, state}
    # end

    def printPerformanceMetrics() do
        count = length(:ets.match(:user_table, {:"_", :"$1"}));
        list =  Enum.to_list 1..count;
        user1 = Enum.random(list);
        user2 = Enum.random(list --[user1]);
        printDashboard("huz#{user1}");
        printDashboard("huz#{user2}");
        Process.sleep(1000);
        printPerformanceMetrics();
      end

    def printDashboard(user) do
        IO.puts "***********************************************";
        IO.puts "#{user}'s' DASHBOARD: "
        tweets = DatabaseHandler.getAllTweetsByUser(user);
        IO.puts "Tweet Count: #{length(tweets)}";
        #Enum.each(tweets, fn {tId, tText} -> IO.puts tText; end);
        
        followers = DatabaseHandler.getAllFollowers(user);
        IO.puts "Number of Followers: #{length(followers)}";
        IO.puts "Followers: ";
        Enum.each(followers, fn follower -> IO.puts follower; end);
        followings = DatabaseHandler.getAllFollowing(user);
        IO.puts "Number of Followed User: #{length(followings)}";
        IO.puts "Followed Users: ";
        Enum.each(followings, fn following -> IO.puts following; end);
        IO.puts "***********************************************";
        IO.puts "";
      end

    def sendTweetToUser(user, tweetId, tweetText) do
        DatabaseHandler.insertTweetInUserTable(user, tweetId);
        userPid = DatabaseHandler.getUserPidByName(user);
        if userPid !== nil do
            send(userPid, {:print_tweet, user, tweetText});
            send(userPid, {:add_tweet, tweetId, tweetText});
        end
    end
end 