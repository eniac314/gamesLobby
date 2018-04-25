defmodule Mainlobby.GamesMeta do 
  
  def games_meta do
	%{ hexaboard: 
       %{ name: "hexaboard",
          min_players: 2,
	      max_players: 6,
		  has_ia: false
	    },

	   war: 
	     %{ name: "war",
          min_players: 2,
	      max_players: 2,
		  has_ia: true
	     }
   }
  end

end
