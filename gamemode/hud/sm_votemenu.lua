--[[
	this panel holds two children, votestart and votecast 
	the votestart is used by the first player when he's deciding what to vote for, parses the options and rules from the vote controller,
		the player is shown all the options, such as ENT.VoteTypes.ROUNDFLAGS , which then shows all the valid options the player can input , the player can still back out of this menu
		to change his choice
		when the player is done he has to press the start vote button, which automatically makes him agree to the vote serverside
	
	the votecast is when the vote has already been started and the other players can decide to vote agree or disagree, this state shows all the informations about the current vote
	
]]