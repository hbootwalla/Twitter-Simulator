defmodule DatabaseHandler do

    def init() do
        :ets.new(:user_pid_table, [:set, :protected, :named_table]);
        :ets.new(:user_tweet_table, [:set, :protected, :named_table]);
        :ets.new(:user_table, [:set, :protected, :named_table]);
        :ets.new(:tweet_table, [:set, :protected, :named_table]);
        :ets.new(:handle_table, [:set, :protected, :named_table]);
        :ets.new(:hashtag_table, [:set, :protected, :named_table]);
        :ets.new(:following_table, [:set, :protected, :named_table]);
        :ets.new(:follower_table, [:set, :protected, :named_table]);
    end

    def insertTweet(tweetId, user, tweet) do
        :ets.insert_new(:tweet_table, {tweetId, tweet});
        insertTweetInUserTable(user, tweetId);
    end

    def insertTweetInUserTable(user, tweetId) do
        tweets = :ets.lookup(:user_tweet_table, user)
        if tweets === [] do
            :ets.insert(:user_tweet_table, {user, [tweetId]})
        else
            [{user, tweetList}] = tweets
            tweetList = [tweetId] ++ tweetList;
            :ets.insert(:user_tweet_table, {user, tweetList});
        end
    end

    def insertHandleTweet(handle, tweetId) do
        tweets = :ets.lookup(:handle_table, handle)
        if tweets === [] do
            :ets.insert(:handle_table, {handle, [tweetId]})
        else
            [{handle, tweetList}] = tweets
            tweetList = [tweetId] ++ tweetList;
            :ets.insert(:handle_table, {handle, tweetList});
        end
    end

    def insertHashtagTweet(hashtag, tweetId) do
        tweets = :ets.lookup(:hashtag_table, hashtag)
        if tweets === [] do
            :ets.insert(:hashtag_table, {hashtag, [tweetId]})
        else
            [{hashtag, tweetList}] = tweets
            tweetList = [tweetId] ++ tweetList;
            :ets.insert(:hashtag_table, {hashtag, tweetList});
        end
    end

    def getTweetById(tablename, tweetId) do
         [{tweetId, tweetText}] = :ets.lookup(tablename, tweetId)
         tweetText
    end

    def getUserPidByName(username) do
        userpid = :ets.lookup(:user_pid_table, username)
        IO.inspect userpid
        if userpid === [] do
            nil
        else
            [{username, pid}] = userpid
            pid
        end
    end

    def setUserPidByName(username, pid) do
        :ets.insert(:user_pid_table, {username, pid})
    end

    def getAllTweetsByUser(user) do
        # :ets.match(tablename, {:"_", user, :"$1"});
        tweets = :ets.lookup(:user_tweet_table, user)
        if tweets === [] do
            []
        else
            [{user, tweetList}] = tweets
            tweetList
            Enum.map(tweetList, fn tweetId -> {tweetId, getTweetById(:tweet_table, tweetId)}  end)
        end
        
    end

    def getAllTweetsByHandle(handle) do
        list = :ets.lookup(:handle_table, handle);
        if list === [] do
            []
        else
            [{u, list}] = list
            list
            Enum.map(list, fn tweetId -> {tweetId, getTweetById(:tweet_table, tweetId)}  end)
        end
    end

    def getAllTweetsByHashtag( hashtag) do
        list = :ets.lookup(:hashtag_table, hashtag);
        if list === [] do
            []
        else
            [{u, list}] = list
            list
            Enum.map(list, fn tweetId -> {tweetId, getTweetById(:tweet_table, tweetId)}  end)
        end

    end

    def addUserToFollowingList(user, subscribedUser) do
        followings = :ets.lookup(:following_table, user)
        if followings === [] do
            :ets.insert(:following_table, {user, [subscribedUser]})
        else
            [{user, followingList}] = followings
            followingList = [subscribedUser] ++ followingList;
            :ets.insert(:following_table, {user, followingList});
        end
    end

    def addUserToFollowersList(subscribedUser, user) do
        followers = :ets.lookup(:follower_table, subscribedUser)
        if followers === [] do
            :ets.insert(:follower_table, {subscribedUser, [user]})
        else
            [{subscribedUser, followersList}] = followers
            followersList = [user] ++ followersList;
            :ets.insert(:follower_table, {subscribedUser, followersList});
        end
    end

    def getAllFollowers(user) do 
        list = :ets.lookup(:follower_table, user);
        if list === [] do
            []
        else
            [{u, l}] = list
            l
        end
    end

    def getAllFollowing(user) do
        list = :ets.lookup(:following_table, user);
        if list === [] do
            []
        else
            [{u, list}] = list
            list
        end
    end

    def getRandomTweet(tablename) do
        tweets = :ets.match(tablename, {:"$1", :"$2"})
        Enum.random(tweets)
    end

    def getSubscribedUsersTweets(username) do
        list = getAllFollowing(username);
        createTweetList(list)    
    end

    def createTweetList([h | t]) do
        list = getAllTweetsByUser(h);
        list ++ createTweetList(t)
    end

    def createTweetList([]) do
        []
    end


end