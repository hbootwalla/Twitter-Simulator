defmodule TwitterServer do
    use GenServer

    def init(:ok) do
        DatabaseHandler.init();
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
                {:reply, :logged_in, state}
            end
        end
    end

    def handle_call({:logout_user, username, password}, _from , state) do
        DatabaseHandler.setUserPidByName(username, nil)
        {:reply, true, state}
    end

    # def handle_call({:get_all_tweets, user}, _from, state) do
    #     tweetList = DatabaseHandler.getAllTweetsByUser(:tweet_table, user);
    #     {:reply, tweetList, state}
    # end

    def handle_call({:get_all_following, user}, _from ,state) do
        followingList = DatabaseHandler.getAllFollowing(user)
        {:reply, followingList, state}
    end

    def handle_call({:get_all_followers, user}, _from ,state) do
        followersList = DatabaseHandler.getAllFollowers( user)
        {:reply, followersList, state}
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
        # IO.inspect followersList;
        Enum.map(followersList, fn follower -> sendTweetToUser(follower, tweetId, tweetText) end);
        
        #send Tweet to Mentions
        # IO.inspect handles;
         Enum.map(handles, fn handle -> sendTweetToUser(handle, tweetId, tweetText) end);
         
         send(print_pid, {:add_tweet, gen_pid, tweetId, tweetText});
         {:noreply, Map.put(state, :tweetCount, Map.get(state, :tweetCount) + 1)}

    end

    def handle_cast({:subscribe_to_user, user, subscribedUser}, state) do
        DatabaseHandler.addUserToFollowingList(user, subscribedUser);
        DatabaseHandler.addUserToFollowersList(subscribedUser, user);
        {:noreply, state}
    end

    def handle_cast({:get_all_tweets, c_pid, gen_pid, username, password}, state) do
        tweetList= DatabaseHandler.getAllTweetsByUser(username);
        send(c_pid, {:get_all_tweets, gen_pid, tweetList});
        {:noreply, state}
    end

    def handle_cast({:retweet, username}, state) do
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

    def sendTweetToUser(user, tweetId, tweetText) do
        DatabaseHandler.insertTweetInUserTable(user, tweetId);
        userPid = DatabaseHandler.getUserPidByName(user);
        if userPid !== nil do
            send(userPid, {:print_tweet, user, tweetText});
        end
    end
end 