defmodule ClientSimulator do

        def init() do
            :ets.new(:simulation, [:set, :public, :named_table]);
        end

        def register_user(sname, gen_pid, c_pid, username, password) do
          response = GenServer.call(sname, {:add_user, c_pid, username, password});
          if response === true do
            GenServer.call(gen_pid, {:set_username, username});
            GenServer.call(gen_pid, {:set_password, password});
            {:ok}
          else  
            {:not_ok, "User Handle Exists. Try Again."}
          end
        end
      
        def login_user(sname, c_pid, gen_pid, username, password) do
          response = GenServer.call(sname, {:login_user, c_pid, username, password});
          GenServer.cast(sname, {:get_all_tweets, c_pid, username, password});
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
            response = GenServer.call(sname, {:logout_user, username, password});
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
            response = GenServer.call(sname, {:get_all_tweets, username});
            {:ok, List.flatten response}
          end
        end
      
        def sendTweet(sname, gen_pid, c_pid, tweetText) do
          username = GenServer.call(gen_pid, {:get_username});
          if(username === '') do
            {:not_ok, "User Not Logged In"}
          else
            GenServer.cast(sname, {:handle_tweet, username, gen_pid, c_pid,  tweetText});
            {:ok}
          end
        end
      
        def subscribeToUser(sname, gen_pid, subscribedUser) do
          username = GenServer.call(gen_pid, {:get_username});
          if(username === '') do
            {:not_ok, "User Not Logged In"}
          else
            GenServer.cast(sname, {:subscribe_to_user, username, subscribedUser});
            {:ok}
          end
        end
      
        def getAllFollowers(sname, pid) do
          username = GenServer.call(pid, {:get_username});
          if(username === '') do
            {:not_ok, "User Not Logged In"}
          else
            response = GenServer.call(sname, {:get_all_followers, username}, :infinity);
            {:ok, List.flatten response}
          end
        end
      
        def getAllFollowing(sname, pid) do
          username = GenServer.call(pid, {:get_username});
          if(username === '') do
            {:not_ok, "User Not Logged In"}
          else
            response = GenServer.call(sname, {:get_all_following, username}, :infinity);
            {:ok, List.flatten response}
          end
        end
      
        def retweetToSubscribers(sname, gen_pid) do
          username = GenServer.call(gen_pid, {:get_username});
          if(username === '') do
            {:not_ok, "User Not Logged In"}
          else
            GenServer.cast(sname, {:retweet, username, gen_pid});
            {:ok}
          end
        end
      
        def getAllSubscribedUsersTweets(sname, gen_pid, c_pid) do
          username = GenServer.call(gen_pid, {:get_username});
          if(username === '') do
            {:not_ok, "User Not Logged In"}
          else
            GenServer.cast(sname, {:get_all_subscribed_users_tweets, username, c_pid});
            {:ok}
          end
        end
      
        def getTweetsByHashtag(sname, gen_pid, c_pid, hashtag) do
          username = GenServer.call(gen_pid, {:get_username});
          if(username === '') do
            {:not_ok, "User Not Logged In"}
          else
            GenServer.cast(sname, {:get_tweets_by_hashtag, hashtag, c_pid});
            {:ok}
          end
        end
      
        def getTweetsByHandle(sname, gen_pid, c_pid) do
          username = GenServer.call(gen_pid, {:get_username});
          if(username === '') do
            {:not_ok, "User Not Logged In"}
          else
            GenServer.cast(sname, {:get_tweets_by_handle, username, c_pid});
            {:ok}
          end
        end
      
        def testCode(sname, uname, c_pid) do
          {:ok, gen_pid} = ClientState.start_link
      
          register_user(sname, gen_pid, c_pid, uname ,"sis");
          case uname do
            "huz1" ->
            Process.sleep(10);
            sendTweet(sname, gen_pid, c_pid, "Yay, @huz2 you rock #supposedly");
            sendTweet(sname, gen_pid, c_pid, "No, @huz3 you dont rock #supposedly");
          "huz2" ->
            sendTweet(sname, gen_pid, c_pid, "Hello, @huz3 #supposedly");
            Process.sleep(1000);
            getTweetsByHandle(sname, gen_pid, c_pid);
          "huz3" ->
            Process.sleep(10)
            Process.sleep(1000);
            getTweetsByHashtag(sname, gen_pid, c_pid, "#supposedly");
            getTweetsByHandle(sname, gen_pid, c_pid);
          end
      
        end
      
        def receiveMessages(sname, gen_pid) do
          receive do
            #{:print_tweet, username, tweet} -> IO.puts "** #{username} tweeted: ** #{tweet}"; 
            {:get_all_tweets, tweetList} -> GenServer.cast(gen_pid, {:set_all_tweets, tweetList});
            {:add_tweet, tweetId, tweetText} -> GenServer.cast(gen_pid, {:set_tweet, {tweetId, tweetText}});
            {:query_all_sub_tweets, tweets} -> IO.puts "All Subscribers Tweets: "; Enum.map(tweets, fn {tweetId, tweetText} -> IO.puts tweetText end);
            {:query_tweets_by_hashtag, hashtag, tweets} -> IO.puts "All Tweets containing ##{hashtag}: "; Enum.map(tweets, fn {tweetId, tweetText} -> IO.puts tweetText end);
            {:query_tweets_by_handle, handle, tweets} -> IO.puts "All Tweets mentioning me: "; Enum.map(tweets, fn {tweetId, tweetText} -> IO.puts tweetText end);
            
            {:sim_register_user, username} -> register_user(sname, gen_pid, self(), username ,"sis");
            {:sim_subscribe_to_user, follower} -> subscribeToUser(sname, gen_pid, follower);
            {:sim_send_tweet, tweetString} -> sendTweet(sname, gen_pid, self(), tweetString);
            {:sim_retweet} -> retweetToSubscribers(sname, gen_pid);
            {:sim_login_user, username} -> login_user(sname, self(), gen_pid, username, "sis"); insertIntoSimulationTable(username, self());
            {:sim_logout_user, username} -> logout_user(sname, gen_pid); removeFromSimulationTable(username);
        end
          receiveMessages(sname, gen_pid)
        end

        def insertIntoSimulationTable(uname, c_pid) do
            list = :ets.lookup(:simulation, "user_list");
            if list === [] do
                :ets.insert(:simulation, {"user_list", [{uname, c_pid}]})
            else
                [{"user_list", list}] = list
                list = [{uname, c_pid}] ++ list;
                :ets.insert(:simulation, {"user_list", list})
            end
        end
      
        def removeFromSimulationTable(user) do
          [{_, list}] = :ets.lookup(:simulation, "user_list");
          {user, userPid} = Enum.find(list, nil, fn val -> {h, _} = val; if h == user do true else false end end);
          listNew = List.delete(list, {user, userPid});
          :ets.insert(:simulation, {"user_list", listNew});
        end


        def initializeClients(sname,count) do
            if(count > 0) do
                uname = "huz#{count}";
                c_pid = spawn(fn -> {:ok, gen_pid} = ClientState.start_link; Process.register(gen_pid, :"#{uname}GS"); receiveMessages(sname, :"#{uname}GS"); end);
                insertIntoSimulationTable(uname, c_pid);
                initializeClients(sname, count - 1);
            end
        end

        def getRandomUser(count, num) do
            ret = Enum.random(1..count);
            if num === ret do
                getRandomUser(count, num)
            else
                ret
            end
        end

        def subUser(follower, mainUser) do
            [{_, list}] = :ets.lookup(:simulation, "user_list");
            {follower, followerPid} = Enum.find(list, {follower, nil}, fn val -> {h, _} = val; if h == follower do true else false end end);
            if followerPid !== nil do
              send(followerPid, {:sim_subscribe_to_user, mainUser})
            end
        end

        def regUser(mainUser) do
            [{_, list}] = :ets.lookup(:simulation, "user_list");
            {mainUser, mainUserPid} = Enum.find(list, {mainUser, nil}, fn val -> {h, _} = val; if h == mainUser do true else false end end);
            if mainUserPid !== nil do
              send(mainUserPid, {:sim_register_user, mainUser});
            end
        end

        def registerAndSetupSubscribers(count) do
            harmonicList = for j <- 1..count do
                1/j
              end
              c=(100/getSum(harmonicList,0))
            for user <- 1..count do
                mainUser = ("huz" <> Integer.to_string(user))
                regUser(mainUser);
            end
            for user <- 1..count, i <- 1..round(Float.floor(c/user)) do
            follower = ("huz" <> Integer.to_string(getRandomUser(count, user)))
            mainUser = ("huz" <> Integer.to_string(user))
            subUser(follower, mainUser);
            end
        end

        def getSum([first|tail], sum) do
            sum = sum + first
            getSum(tail,sum)
        end
        
        def getSum([], sum) do
            sum
        end

        

        def getUserMentionString(userMentionNum, count, totUsercount) do
            if userMentionNum > 0 do
                num = getRandomUser(totUsercount, count);
                user = "@huz#{num} ";
                user <> getUserMentionString(userMentionNum - 1, count, totUsercount)
            else
                ""
            end
        end

        def getHashTagString(count, hashtags) do
            if count > 0 do
               ht = Enum.random(hashtags);
               hashtags = hashtags -- [ht];
               ht <> getHashTagString(count - 1, hashtags) 
            else
                ""
            end
        end

        def tweet(sname, user, totUsercount) do
            
            [{_, list}] = :ets.lookup(:simulation, "user_list");
            {user, userPid} = Enum.find(list, {user,nil}, fn val -> {h, _} = val; if h == user do true else false end end);

            if userPid !== nil do
            bodyList = [",come over for the party!,", ",its going to be a long night,", ",give me a break,", ",going for my exam guys,", "damnnnnn, that be scary,"];
            body = Enum.random(bodyList);

            hashtagNum = Enum.random(1..2);
            hashtags = [" #LiveLife ", " #SomethingNeverChanges ", " #DieTomorrow ", " #SleepWell ", " #PLPForever "];
            
            hashtagString = getHashTagString(hashtagNum, hashtags);
            tweetString = body <> hashtagString;
            send(userPid, {:sim_send_tweet, tweetString});
            #Process.sleep(10000);
            end
        end

        def mention(sname, user, totUserCount) do
          [{_, list}] = :ets.lookup(:simulation, "user_list");
          {user, userPid} = Enum.find(list, {user,nil}, fn val -> {h, _} = val; if h == user do true else false end end);
          if userPid !== nil do
          userMentionNum = Enum.random(1..2);
          
          userMentionString = getUserMentionString(userMentionNum, totUserCount, totUserCount);
          
          bodyList = [",come over for the party!,", ",its going to be a long night,", ",give me a break,", ",going for my exam guys,", "damnnnnn, that be scary,"];
          body = Enum.random(bodyList);

          body = userMentionString <> body;
          send(userPid, {:sim_send_tweet, body});
          end
       end

      def retweet(sname, user, count) do
        [{_, list}] = :ets.lookup(:simulation, "user_list");
        {user, userPid} = Enum.find(list, {user,nil}, fn val -> {h, _} = val; if h == user do true else false end end);
        if userPid !== nil do
        send(userPid, {:sim_retweet});
        end
      end

      def logout(sname, user, count) do
        [{_, list}] = :ets.lookup(:simulation, "user_list");
        {user, userPid} = Enum.find(list, {user,nil}, fn val -> {h, _} = val; if h == user do true else false end end);
        if userPid !== nil do
        send(userPid, {:sim_logout_user, user});
        Process.sleep(3000);
        send(userPid, {:sim_login_user, user});
        end
      end

      def simulateOperations(sname, userId, count) do
          randomInt = String.to_integer(Twitter.RandomLibrary.randomizer(2,:numeric))
          if(rem(randomInt,2)==0) do tweet(sname, userId, count) end 
          if(rem(randomInt,6)==0) do retweet(sname, userId, count) end 
          if(rem(randomInt,3)==0) do mention(sname, userId, count) end 
          if(rem(randomInt,307)==0) do logout(sname, userId, count) end 
          simulateOperations(sname, userId, count)
        end

        # def startSimulation(sname, count, totCount) do
        #     if count > 0 do
        #         user = "huz#{count}"
        #         spawn(fn -> startTweeting(sname, count, userPid, totCount) end)
        #         startSimulation(sname, count - 1, totCount);
        #     end
        # end

        def simulateClients(sname, count) do
          init();
          initializeClients(sname, count);
          #Process.sleep(1000);
          registerAndSetupSubscribers(count);
          Enum.each(1..count, fn x -> spawn(fn -> simulateOperations(sname, "huz#{x}", count) end) end);
          #Process.sleep(5000);
          keepAlive
        end

        def keepAlive do
            keepAlive
        end

        def smallTestCode(sname) do
            IO.puts GenServer.cast(sname, {:return_something})
            smallTestCode(sname)
        end

        def printPerformanceMetrics(sname, count) do
          IO.inspect GenServer.call(sname, {:print_metrics, count}, :infinity);
        end

end