defmodule DatabaseHandler do
    def insertTweet(tweet_tablename, user_tablename,  tweetId, user, tweet) do
        :ets.insert_new(tweet_tablename, {tweetId, tweet});
        insertTweetInUserTable(user_tablename, user, tweetId);
    end

    def insertTweetInUserTable(tablename, user, tweetId) do
        tweets = :ets.lookup(user_tablename, user)
        if tweets === [] do
            :ets.insert(user_tablename, {user, [tweetId]})
        else
            [{user, tweetList}] = tweets
            tweetList = [tweetId] ++ tweetList;
            :ets.insert(user_tablename, {user, tweetList});
        end
    end

    def insertHandleTweet(tablename, handle, tweetId) do
        tweets = :ets.lookup(tablename, handle)
        if tweets === [] do
            :ets.insert(tablename, {handle, [tweetId]})
        else
            [{handle, tweetList}] = tweets
            tweetList = [tweetId] ++ tweetList;
            :ets.insert(tablename, {handle, tweetList});
        end
    end

    def insertHashtagTweet(tablename, hashtag, tweetId) do
        tweets = :ets.lookup(tablename, hashtag)
        if tweets === [] do
            :ets.insert(tablename, {hashtag, [tweetId]})
        else
            [{hashtag, tweetList}] = tweets
            tweetList = [tweetId] ++ tweetList;
            :ets.insert(tablename, {hashtag, tweetList});
        end
    end

    def getTweetById(tablename, tweetId) do
         [{tweetId, tweetText}] = :ets.lookup(tablename, tweetId)
         tweetText
    end

    def getUserPidByName(tablename, username) do
        userpid = :ets.lookup(tablename, username)
        if userpid === [] do
            nil
        else
            [{username, pid}] = userpid
            userpid
        end
    end

    def setUserPidByName(tablename, username, pid) do
        :ets.insert(tablename, {username, pid})
    end

    def getAllTweetsByUser(tablename, user) do
        :ets.match(tablename, {:"_", user, :"$1"});
    end

    def getAllTweetsByHandle(tablename, handle) do
        list = :ets.lookup(tablename, handle);
        if list === [] do
            []
        else
            [{u, list}] = list
            list
        end
    end

    def getAllTweetsByHashtag(tablename, hashtag) do
        list = :ets.lookup(tablename, hashtag);
        if list === [] do
            []
        else
            [{u, list}] = list
            list
        end
    end

    def addUserToFollowingList(tablename, user, subscribedUser) do
        followings = :ets.lookup(tablename, user)
        if followings === [] do
            :ets.insert(tablename, {user, [subscribedUser]})
        else
            [{user, followingList}] = followings
            followingList = [subscribedUser] ++ followingList;
            :ets.insert(tablename, {user, followingList});
        end
    end

    def addUserToFollowersList(tablename, subscribedUser, user) do
        followers = :ets.lookup(tablename, subscribedUser)
        if followers === [] do
            :ets.insert(tablename, {subscribedUser, [user]})
        else
            [{subscribedUser, followersList}] = followers
            followersList = [user] ++ followersList;
            :ets.insert(tablename, {subscribedUser, followersList});
        end
    end

    def getAllFollowers(tablename, user) do 
        list = :ets.lookup(tablename, user);
        if list === [] do
            []
        else
            [{u, list}] = list
            list
        end
    end

    def getAllFollowing(tablename, user) do
        list = :ets.lookup(tablename, user);
        if list === [] do
            []
        else
            [{u, list}] = list
            list
        end
    end

    def insertUserInto

end