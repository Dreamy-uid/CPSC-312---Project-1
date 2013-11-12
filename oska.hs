-- Project 1
-- Chris Tulip 24047094
-- Julia Litke 27807098


import Data.List

-- ****************************************************
-- Data Model
-- ****************************************************

data State = State {
	whites 	 :: [ Point ],
	blacks 	 :: [ Point ],
    board    :: [ Point ],
	turn 	 :: Int,
	value	 :: Int
} deriving (Show, Eq, Ord)

data Point = Point {
	x 		   :: Int,
	y 		   :: Int
} deriving (Show, Eq, Ord)

data Level = Level {
	minmax		:: String,
	nStates		:: [ [State] ]
} deriving (Show, Eq, Ord)

-- ****************************************************
-- Constants (Don't mess with these)
-- ****************************************************
white = -1
black = 1

left  = 1
right = 0

-- ****************************************************
-- Main
-- ****************************************************

--oska_t1v7 :: [String] -> Char -> Int -> [String]
--oska_t1v7 currentState player depth = (stateToString (minimax (stringToState currentState) "MAX" depth))

-- ****************************************************
-- Search Level Logic
-- ****************************************************

--1. Generate the game tree to as many levels (plies) that time and space
---- constraints allow. The top level is called MAX (as in it’s now MAX’s
---- turn to move), the next level is called MIN, the next level is MAX, and
---- so on.
--2. Apply the evaluation function to all the terminal (leaf) states/boards
---- to get “goodness” values.
--3. Use those terminal board values to determine the values to be
---- assigned to the immediate parents:
---- a) if the parent is at a MIN level, then the value is
---- the minimum of the values of its children
---- b) if the parent is at a MAX level, then the value is
---- the maximum of the values of its children   
--4. Keep propagating values upward as in step 3
-- apply minOrMax to every level of the tree
--5. When the values reach the top of the game tree, MAX chooses the
---- move indicated by the highest value

minimaxSearch :: State -> String -> Int -> State
minimaxSearch state level depth = (maxState 
									(minOrMax 
										(propogateMinOrMax 
										(generateTree (movesForState state) "MIN" (depth - 1)) level depth)
									level))

generateTree :: [State] -> String -> Int -> [ [ [ State ] ] ]
generateTree states level depth
  | null states						= []
  | (depth == 0)					= []
  | otherwise						= thisLevel : nextLevel
    where 
	  thisLevel = (generateLevel (movesForState(head states)))
	  nextLevel = (generateTree (tail states) (switchLevel level) (depth - 1))

switchLevel :: String -> String
switchLevel level
  | (level == "MAX")				= "MIN"
  | (level == "MIN")				= "MAX"  

generateLevel :: [ State ] -> [ [ State ] ]
generateLevel states
  | null states             = []
  | otherwise               = new : next
  where
    new  = (movesForState (head states))
    next = (generateLevel (tail states))
		
	
propogateMinOrMax :: [ [ [State] ] ] -> String -> Int -> [ [State] ]
propogateMinOrMax treeOfStates level depth
  | (depth == 1)			= (head treeOfStates)
  | otherwise				= (minOrMax (applyToLeaves (head treeOfStates)) level) 
								: (propogateMinOrMax (tail treeOfStates) (switchLevel level) (depth - 1))

applyToLeaves :: [ [State] ] -> [ [State] ]
applyToLeaves bottomLevel = (map applyToLeaf bottomLevel)
	
applyToLeaf :: [State] -> [State]
applyToLeaf bottomNode = (map boardEvaluator bottomNode)
	
minOrMax :: [ [State] ] -> String -> [State]
minOrMax states level
  | (level == "MAX")				= (map maxState states)
  | (level == "MIN")				= (map minState states)


maxState :: [State] -> State
maxState states 
  | ((head states) == (last states))											= (head states)
  | (length states == 2)														= (gState (head states) (head (tail states)))
  | ((value (head states)) > (value (head (tail states))))						= (maxState ((head states) : (tail (tail states))))
  | otherwise																	= (maxState (tail states))
  
gState :: State -> State -> State
gState state1 state2
  | ((value state1) > (value state2))			= state1
  | ((value state1) < (value state2))			= state2
	

minState :: [State] -> State
minState states 
  | ((head states) == (last states))											= (head states)
  | (length states == 2)														= (lState (head states) (head (tail states)))
  | ((value (head states)) < (value (head (tail states))))						= (minState ((head states) : (tail (tail states))))
  | otherwise																	= (minState (tail states))

lState :: State -> State -> State
lState state1 state2
  | ((value state1) < (value state2))			= state1
  | ((value state1) > (value state2))			= state2

-- instead of turning a state into an integer, now updates state with calculated value  
boardEvaluator :: State -> State
boardEvaluator state
  | ((turn state) == white)		= whiteBoardEvaluator state 
  | ((turn state) == black)		= blackBoardEvaluator state
  
whiteBoardEvaluator :: State -> State
whiteBoardEvaluator state = State (whites state) (blacks state) (board state) (turn state) newValue
	where newValue = ((piecesDiff (countWhites state (whites state)) (countBlacks state (blacks state))) 
				+ (whiteJumpDiff state) + (whiteMoves state) + (whiteEndMoveDiff state))
				* (whiteWinningValue state) * (whiteLosingValue state)
		
piecesDiff :: Int -> Int -> Int
piecesDiff x y = x - y

whiteJumpDiff :: State -> Int
whiteJumpDiff state = (countJumps (whites state) state) - (countJumps (blacks state) state)

countJumps :: [Point] -> State -> Int
countJumps pieces state
  | null pieces				= 0
  | otherwise				= (heurJump (head pieces) state) + (countJumps (tail pieces) state)
  
heurJump :: Point -> State -> Int
heurJump piece state
  | twoJumps				= 2
  | oneJump					= 1
  | otherwise				= 0
	where
	  twoJumps = ((canJump piece right state) && (canJump piece left state))
	  oneJump = ((canJump piece right state) || (canJump piece left state))
	  
whiteMoves :: State -> Int
whiteMoves state = (length (movesForState state))

whiteEndMoveDiff :: State -> Int
whiteEndMoveDiff state = ((backRowWhites (whites state) state) - (backRowBlacks (blacks state) state))

backRowWhites :: [Point] -> State -> Int
backRowWhites pieces state
  | null pieces										= 0
  | ((y (head pieces)) == (y (last (board state))))	= (backRowWhites (tail pieces) state) + 1
  | otherwise										= 0
 
backRowBlacks :: [Point] -> State -> Int
backRowBlacks pieces state
  | null pieces										= 0
  | ((y (head pieces)) == (y (last (board state))))	= (backRowBlacks (tail pieces) state) + 1
  | otherwise										= 0

whiteWinningValue :: State -> Int
whiteWinningValue state
  | ((hasWhiteWon state) == True)	= 10
  | otherwise						= 1
  
hasWhiteWon :: State -> Bool
hasWhiteWon state
  | allBlackGone			= True
  | allBackRow				= True
	where
	  allBlackGone = ((countWhites state (whites state)) > (countBlacks state (blacks state))) 
						&& ((countBlacks state (blacks state)) == 0)
	  allBackRow = (countWhites state (whites state)) == (backRowWhites (whites state) state)
  
whiteLosingValue :: State ->Int
whiteLosingValue state
  | ((hasWhiteLost state) == True)	= -10
  | otherwise						= 1
  
hasWhiteLost :: State -> Bool
hasWhiteLost state
  | ((hasBlackWon state) == True)		= True
  | otherwise							= False
  
countWhites :: State -> [Point] -> Int
countWhites state whitePieces
  | null whitePieces		 	= 0
  | otherwise					= 1 + (countWhites state (tail whitePieces))

blackBoardEvaluator :: State -> State
blackBoardEvaluator state  = State (whites state) (blacks state) (board state) (turn state) newValue
	where newValue = ((piecesDiff (countBlacks state (blacks state)) (countWhites state (whites state))) 
					+ (blackJumpDiff state) + (blackMoves state) + (blackEndMoveDiff state))
					* (blackWinningValue state) * (blackLosingValue state)

countBlacks :: State -> [Point] -> Int
countBlacks state blackPieces
  | null blackPieces		 	= 0
  | otherwise					= 1 + (countBlacks state (tail blackPieces))
  
blackJumpDiff :: State -> Int
blackJumpDiff state = (countJumps (blacks state) state) - (countJumps (whites state) state)

blackMoves :: State -> Int
blackMoves state = (length (movesForState state))

blackEndMoveDiff :: State -> Int
blackEndMoveDiff state = ((backRowBlacks (blacks state) state) - (backRowWhites (whites state) state))

blackWinningValue :: State ->Int
blackWinningValue state
  | ((hasBlackWon state) == True)	= 10
  | otherwise						= 1
  
hasBlackWon :: State -> Bool
hasBlackWon state
  | allWhiteGone			= True
  | allBackRow				= True
	where
	  allWhiteGone = ((countBlacks state (blacks state)) > (countWhites state (whites state))) 
					&& ((countWhites state (whites state)) == 0)
	  allBackRow = (countBlacks state (blacks state)) == (backRowBlacks (blacks state) state)

blackLosingValue :: State ->Int
blackLosingValue state
  | ((hasBlackLost state) == True)	= -10
  | otherwise						= 1
  
hasBlackLost :: State -> Bool
hasBlackLost state
  | ((hasWhiteWon state) == True)		= True
  | otherwise							= False


---- ****************************************************
---- State Level Logic
---- ****************************************************

movesForState :: State -> [ State ]
movesForState state
  | (turn state) == white   = possibleMoves (whites state) state
  | otherwise               = possibleMoves (blacks state) state

possibleMoves :: [ Point ] -> State -> [ State ]
possibleMoves pts state
  | null pts                = []
  | otherwise               = merge validMoves next
  where
    validMoves = (validMovesForPoint (head pts) state)
    next       = (possibleMoves (tail pts) state)

-- ****************************************************
-- Point Interactions
-- ****************************************************

validMovesForPoint :: Point -> State -> [ State ]
validMovesForPoint pt state = merge jumpStates moveStates
  where
    jumpStates = jumpStatesForPoint pt state
    moveStates = moveStateForPoint pt state

moveStateForPoint :: Point -> State -> [ State ]
moveStateForPoint pt state
  | both              = [leftMove, rightMove]
  | leftMove /= state = [leftMove]
  | rightMove/= state = [rightMove]
  | otherwise         = [State [(Point 999 999)] [(Point 999 999)] [(Point 999 999)] white (value state)]
  where
    both      = (leftMove /= state) && (rightMove /= state)
    leftMove  = stateAfterMove pt left  state
    rightMove = stateAfterMove pt right state

jumpStatesForPoint :: Point -> State -> [ State ]
jumpStatesForPoint pt state
  | both              = [leftJump, rightJump]
  | leftJump /= state = [leftJump]
  | rightJump/= state = [rightJump]
  | otherwise         = []
  where
    both      = (leftJump /= state) && (rightJump /= state)
    leftJump  = stateAfterJump pt left  state
    rightJump = stateAfterJump pt right state

stateAfterJump :: Point -> Int -> State -> State
stateAfterJump pt dir state
  | whiteJump         = State (whites next) (blacks cleanState) (board state) black (value state)
  | blackJump         = State (whites cleanState) (blacks next) (board state) white (value state)
  | otherwise         = state
  where
    whiteJump   = (canJump pt dir state) && ( (turn state) == white )
    blackJump   = (canJump pt dir state) && ( (turn state) == black )
    next        = replacePointForState pt ( jump pt dir ( turn state ) ) state
    cleanState  = removePointForState ( move pt dir ( turn state ) ) state

stateAfterMove :: Point -> Int -> State -> State
stateAfterMove pt dir state
  | (canMove pt dir state)  = replacePointForState pt ( move pt dir ( turn state ) ) state
  | otherwise               = state

replacePointForState :: Point -> Point -> State -> State
replacePointForState pt newPt state
  | elem pt ( whites state ) = State (replacePoint pt newPt (whites state)) (blacks state) (board state) nextTurn (value state)
  | elem pt ( blacks state ) = State (whites state) (replacePoint pt newPt (blacks state)) (board state) nextTurn (value state)
  | otherwise                = state
  where
    nextTurn = ( (-1) * (turn state) )

removePointForState :: Point -> State -> State
removePointForState pt state
  | elem pt ( whites state ) = State (removePoint pt (whites state)) (blacks state) (board state) (turn state) (value state)
  | elem pt ( blacks state ) = State (whites state) (removePoint pt (blacks state)) (board state) (turn state) (value state)
  | otherwise                = state


removePoint :: Point ->[ Point ] -> [ Point ]
removePoint pt pts
  | (null pts)                    = []
  | pt == (head pts)              = (tail pts)
  | otherwise                     = (head pts) : removePoint pt (tail pts)

replacePoint :: Point -> Point -> [ Point ] -> [ Point ]
replacePoint pt newPt pts
  | (null pts)                    = []
  | pt == (head pts)              = newPt : (tail pts)
  | otherwise                     = (head pts) : (replacePoint pt newPt (tail pts))

-- ****************************************************
-- Point Level Logic (Eg. Moves)
-- ****************************************************

canJump :: Point -> Int -> State -> Bool
canJump pt dir state = bounded && blocked && clear
  where
    nextPoint = jump pt dir (turn state)
    blocked   = elem (move pt dir (turn state)) (otherPts state)
    bounded   = (pointInBounds nextPoint state)
    clear     = not (pointTaken nextPoint state)

canMove :: Point -> Int -> State -> Bool
canMove pt dir state = bounded && clear
  where
    nextPoint = move pt dir (turn state)
    bounded   = (pointInBounds nextPoint state)
    clear     = not (pointTaken nextPoint state)

pointInBounds :: Point -> State -> Bool
pointInBounds point state = ( elem point (board state) )

pointTaken ::  Point -> State -> Bool
pointTaken point state  = ( elem point (blacks state) ) || ( elem point (whites state) )

-- currentPoint, direction, turn, return movedPoint
move :: Point -> Int -> Int -> Point
move old direction turn
  | turn == white     = ( Point ( (x old) + direction ) ( (y old) + 1 ) )
  | otherwise         = ( Point ( (x old) + direction ) ( (y old) - 1 ) )

-- currentPoint, direction, turn, return movedPoint
jump :: Point -> Int -> Int -> Point
jump old direction turn
  | turn == white     = ( Point ( (x old) + 2 * direction ) ( (y old) + 2 ) )
  | otherwise         = ( Point ( (x old) - 2 * direction ) ( (y old) - 2 ) )

-- ****************************************************
-- Process Input Signal - Assumes only initial states
-- ****************************************************
stringToState :: [String] -> State
stringToState input = ( State whites blacks board white 0 )
  where
    whites = (buildWhites (head input) )
    blacks = (buildBlacks (last input) (length input) )
    board  = (buildBoard input ( length (head input) ) (length input) )

buildWhites :: String -> [ Point ]
buildWhites input
  | null input        = []
  | otherwise         = (Point (length input) 1) : buildWhites (tail input)

buildBlacks :: String -> Int -> [ Point ]
buildBlacks input height
  | null input        = []
  | otherwise         = (Point (length input) height) : (buildBlacks (tail input) height)

buildBoard :: [ String ] -> Int -> Int -> [ Point ]
buildBoard input maxWidth height
  | null input        = []
  | otherwise         = merge ( processLine (head input) (length input) offset ) next
  where
    next      = ( buildBoard (tail input) maxWidth height )
    offset    = ( maxWidth - (length (head input) ) )

processLine :: String -> Int -> Int -> [ Point ]
processLine line yCoord offset
  | null line           = []
  | otherwise           = pt : next
  where
    pt    = ( Point xCoord yCoord )
    next  = ( processLine (tail line) yCoord offset )
    xCoord= ( offset + (length line) )

-- ****************************************************
-- Helpers
-- ****************************************************
merge :: [a] -> [a] -> [a]
merge [] []               = []
merge xs []               = xs
merge [] ys               = ys
merge (x:xs) (y:ys)       = x : y : merge xs ys

nth :: [a] -> Int -> Int -> a
nth arr i depth
  | i == depth  = (head arr)
  | otherwise   = nth (tail arr) (i+1) depth

otherPts state
  | (turn state) == white = (blacks state)
  | otherwise             = (whites state)

-- ****************************************************
-- Tests - using my own system that I've made up on the
-- fly here... probs not the best solution but it works
-- ****************************************************

testSuite       = functionalTests && unitTests
functionalTests = t_validMovesForPoint && t_removePointForState && t_removePointForState
unitTests       = t_canJump && t_canMove && t_pointTaken && t_pointInBounds && t_move && t_jump

-- validMovesForPoint :: Point -> State -> [ State ]
t_validMovesForPoint = trueTests && (not falseTests)
  where
    trueTests = t_validMovesForPoint1 && t_validMovesForPoint2
    falseTests= False

t_validMovesForPoint1 = correctLength && newStates && newTurns
  where
    validMoves    = validMovesForPoint (head whiteList) firstState
    correctLength = (length validMoves) == 1
    newStates      = not (elem firstState validMoves)
    newTurns      = not (elem (turn firstState) (map turn validMoves))

t_validMovesForPoint2 = correctLength && newStates && newTurns
  where
    validMoves    = (validMovesForPoint (nth whiteList 0 1) firstState)
    correctLength = (length validMoves) == 2
    newStates      = not (elem firstState validMoves)
    newTurns      = not (elem (turn firstState) (map turn validMoves))


-- stateAfterMove :: Point -> Int -> State (returns inital if not available)
t_stateAfterMoveWL = same && newTurn
  where
    same        = movedState == blockedStateW
    movedState  = (stateAfterMove (head (whites blockedStateW)) left  blockedStateW)
    newTurn     = (turn blockedStateW) /= (turn movedState)

t_stateAfterMoveBL = stateAfterMove (head (blacks blockedStateB)) left  blockedStateB
t_stateAfterMoveWR = stateAfterMove (head (whites firstState)) right firstState
t_stateAfterMoveBR = stateAfterMove (head (blacks firstState)) right firstState

-- stateAfterJump :: Point -> Int -> State (returns inital if not available)
t_stateAfterJumpWL = stateAfterJump (head (whites blockedStateW)) left  blockedStateW
t_stateAfterJumpBL = stateAfterJump (head (blacks blockedStateB)) left  blockedStateB
t_stateAfterJumpWR = stateAfterJump (last (whites blockedStateW)) right blockedStateW

-- replacePointForState :: Point -> Point -> State -> State
t_replacePointForState = elem (Point 10 10) newWhite
  where newWhite = (whites (replacePointForState (head whiteList) (Point 10 10) firstState))

-- removePointForState :: Point -> State -> State
t_removePointForState = not (elem (head whiteList) (whites (removePointForState (head whiteList) firstState)))

-- removePoint :: Point ->[ Point ] -> [ Point ]
t_removePointH   = removePoint (head whiteList) whiteList
t_removePointL   = removePoint (last whiteList) whiteList

-- replacePoint :: Point -> Point -> [ Point ] -> [ Point ]
t_replacePointH  = replacePoint (head whiteList) (Point 10 10) whiteList
t_replacePointL  = replacePoint (last whiteList) (Point 10 10) whiteList

--
-- canMove :: Point -> Int -> State -> Bool
-- Test Cases:
-- Valid
-- Out of Bounds
-- Blocked
--
t_canMove     = trueTests && (not falseTests)
  where
    trueTests = t_canMoveT
    falseTests= t_canMoveFB && t_canMoveFOOB

t_canMoveT    = canMove (head (whites firstState)) right firstState
t_canMoveFOOB = canMove (head (whites firstState)) left firstState
t_canMoveFB   = canMove (head (whites blockedStateW)) right blockedStateW

--
-- canJump :: Point -> Int -> State -> Bool
-- Test Cases:
-- white jump black (T)
-- black jump white (T)
-- white jump white (F)
-- Jump Destination Taken (F)
-- Out of Bounds (F)
-- Jump Not Blocked (F)
--
t_canJump     = trueTests && (not falseTests)
  where
    trueTests = t_canJumpWJB && t_canJumpBJW
    falseTests= (t_canJumpWJW) && (t_canJumpJDT) && (t_canJumpOOB) && (t_canJumpNB)

t_canJumpWJB  = canJump (head (whites blockedStateW)) right blockedStateW
t_canJumpBJW  = canJump (last (blacks blockedStateB)) right blockedStateB
t_canJumpWJW  = canJump (last (whites blockedStateW)) right blockedStateW
t_canJumpJDT  = canJump (last (whites blockedStateW)) right blockedStateW
t_canJumpOOB  = canJump (head (whites blockedStateW)) left  blockedStateW
t_canJumpNB   = canJump (head (whites firstState)) right firstState

--
-- pointTaken ::  Point -> State -> Bool
--
t_pointTaken  = t_pointTakenT && (not t_pointTakenF)

t_pointTakenT = pointTaken (Point 4 3) blockedStateW
t_pointTakenF = pointTaken (Point 1 1) blockedStateW

--
-- pointInBounds :: Point -> State -> Bool
--
t_pointInBounds  = t_pointInBoundsT && (not t_pointInBoundsF)

t_pointInBoundsT = pointInBounds (head whiteList) firstState
t_pointInBoundsF = pointInBounds (Point 99 99) firstState

--
-- move :: Point -> Int -> Int -> Point
--
t_move = trueTests
  where
    trueTests = t_moveLW && t_moveRW && t_moveLB && t_moveRB

t_moveLW = (move p1 left  white) == (Point 2 2)
t_moveRW = (move p1 right white) == (Point 1 2)
t_moveLB = (move p5 left  black) == (Point 2 4)
t_moveRB = (move p5 right black) == (Point 1 4)

--
-- jump :: Point -> Int -> Int -> Point
--
t_jump = trueTests
  where
    trueTests = t_jumpLW && t_jumpRW && t_jumpLB && t_jumpRB

t_jumpLW = (jump p1 left  white) == (Point 3 3)
t_jumpRW = (jump p1 right white) == (Point 1 3)
t_jumpLB = (jump p8 left  black) == (Point 2 3)
t_jumpRB = (jump p5 right black) == (Point 1 3)

-- Test Structures (Point x y)
p1 = (Point 1 1)
p2 = (Point 2 1)
p3 = (Point 3 1)
p4 = (Point 4 1)

p5 = (Point 1 5)
p6 = (Point 2 5)
p7 = (Point 3 5)
p8 = (Point 4 5)

whiteList = (whites firstState)
blackList = (blacks firstState)

firstState = stringToState testString

blockedStateW = ( State [ (Point 3 2) , (Point 3 1) ] [ (Point 4 3),(Point 3 3) ] testBoard white 0)
blockedStateB = ( State [ (Point 3 2) ] [ (Point 4 3),(Point 3 3) ] testBoard black 0)

testBoard = [(Point 3 5),(Point 4 5),(Point 2 5),(Point 1 5),(Point 4 4),(Point 3 4),(Point 2 4),(Point 4 3),(Point 3 3),(Point 4 2),(Point 3 2),(Point 2 2),(Point 4 1),(Point 3 1),(Point 2 1),(Point 1 1)]

testString = [ "wwww", "---", "--",  "---", "bbbb" ]

