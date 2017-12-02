defmodule TwitterServer do
    use GenServer

    def init(:ok) do
        :ets.new(:user_pid_table, [:set, :protected, :named_table]);
        :ets.new(:user_tweet_table, [:set, :protected, :named_table]);
        :ets.new(:user_table, [:set, :protected, :named_table]);
        :ets.new(:tweet_table, [:set, :protected, :named_table]);
        :ets.new(:handle_table, [:set, :protected, :named_table]);
        :ets.new(:hashtag_table, [:set, :protected, :named_table]);
        :ets.new(:following_table, [:set, :protected, :named_table]);
        :ets.new(:follower_table, [:set, :protected, :named_table]);
        {:ok, %{tweetCount: 0}}
    end

    def start_link do
        GenServer.start_link(__MODULE__, :ok, name: :Twitter_Server);
    end

    # def registerUser(userDetails) do
    #     GenServer.call({:add_user, userDetails[:username], userDetails[:password]});
    # end

    def handle_call({:add_user, c_pid, username, password}, _from , state) do
        returnValue = :ets.insert_new(:user_table, {username, password});
        DatabaseHandler.setUserPidByName(:user_pid_table, username, c_pid)
        {:reply, returnValue, state}
    end

    def handle_call({:login_user, c_pid, username, password}, _from , state) do
        returnValue = :ets.lookup(:user_table, username);
        DatabaseHandler.setUserPidByName(:user_pid_table, username, c_pid)
        if(returnValue == []) do
            {:reply, :unregistered, state}
        else
            [{username,returnedPassword}] = returnValue
            if(returnedPassword != password) do
                {:reply, :incorrect_password, state} 
            else
                {:reply, :logged_in, state}
            end
        end
    end

    def handle_call({:logout_user, username, password}, _from , state) do
        DatabaseHandler.setUserPidByName(:user_pid_table, username, nil)
        {:reply, true, state}
    end

    # def handle_call({:get_all_tweets, user}, _from, state) do
    #     tweetList = DatabaseHandler.getAllTweetsByUser(:tweet_table, user);
    #     {:reply, tweetList, state}
    # end

    def handle_call({:get_all_following, user}, _from ,state) do
        followingList = DatabaseHandler.getAllFollowing(:following_table, user)
        {:reply, followingList, state}
    end

    def handle_call({:get_all_followers, user}, _from ,state) do
        followersList = DatabaseHandler.getAllFollowers(:follower_table, user)
        {:reply, followersList, state}
    end

    def handle_cast({:handle_tweet, user, gen_pid, print_pid, tweetText}, state) do
        handles = TweetParser.getAllHandles(tweetText);
        hashtags = TweetParser.getAllHashtags(tweetText);
        tweetId = Map.get(state, :tweetCount) + 1;
        DatabaseHandler.insertTweet(:tweet_table, :user_tweet_table, tweetId, user, tweetText);
        Enum.map(handles, fn (handle) -> DatabaseHandler.insertHandleTweet(:handle_table, handle, tweetId) end);
        Enum.map(hashtags, fn (hashtag) -> DatabaseHandler.insertHashtagTweet(:hashtag_table, hashtag, tweetId) end);

        #send Tweet to Followers
        followersList = DatabaseHandler.getAllFollowers(:follower_table, user)
        # IO.inspect followersList;
        Enum.map(followersList, fn follower -> sendTweetToUser(follower, tweetId, tweetText) end);
        
        #send Tweet to Mentions
        # IO.inspect handles;
         Enum.map(handles, fn handle -> sendTweetToUser(handle, tweetId, tweetText) end);
         
         send(print_pid, {:add_tweet, gen_pid, tweetId, tweetText});
         {:noreply, Map.put(state, :tweetCount, Map.get(state, :tweetCount) + 1)}

    end

    def handle_cast({:subscribe_to_user, user, subscribedUser}, state) do
        DatabaseHandler.addUserToFollowingList(:following_table, user, subscribedUser);
        DatabaseHandler.addUserToFollowersList(:follower_table, subscribedUser, user);
        {:noreply, state}
    end

    def handle_cast({:get_all_tweets, c_pid, gen_pid, username, password}, state) do
        tweetList= DatabaseHandler.getAllTweetsByUser(:user_tweet_table, :tweet_table , username);
        send(c_pid, {:get_all_tweets, gen_pid, tweetList});
        {:noreply, state}
    end

    def handle_cast({:retweet, username}, state) do
        [tweetId, tweetText] = DatabaseHandler.getRandomTweet(:tweet_table);
        followers = DatabaseHandler.getAllFollowers(:follower_table, username);
        Enum.map(followers, fn follower -> sendTweetToUser(follower, tweetId, tweetText) end);
        {:noreply, state}
    end

    def sendTweetToUser(user, tweetId, tweetText) do
        DatabaseHandler.insertTweetInUserTable(:user_tweet_table, user, tweetId);
        #tweet = DatabaseHandler.getTweetById(tweetId);
        userPid = DatabaseHandler.getUserPidByName(:user_pid_table, user);
        if userPid !== nil do
            send(userPid, {:print_tweet, user, tweetText});
        end
    end
end 