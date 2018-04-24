defmodule Mainlobby.Chat do 

# %{
#       time_stamp: time_stamp,
#       author: author,
#       message: message,
#     }

def get_chat_history(chat) do 
  chat
end


def add_message(message, chat) do 
  lastMessages = Enum.take(chat, 9)
  [ message | lastMessages ]
end 

end
