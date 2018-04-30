defmodule Mainlobby.Chat do 

def get_chat_history(chat, channel) do 
  Map.get(chat, channel) 
end

def add_channel(chat, channel) do 
  if not Map.has_key(chat, channel) do 
  	Map.put(chat, channel, [])
  else chat 
  end 
end

def delete_channel(chat, channel) do 
   Map.delete(chat, channel)
end

def add_message(chat, message, channel) do 
  lastMessages = 
    get_chat_history(chat,channel)
    |> Enum.take(49)
  new_messages = [ message | lastMessages ]
  Map.put(chat, channel, new_messages)
end 

end
