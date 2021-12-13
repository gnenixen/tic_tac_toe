PLAYER_SYMBOL_1 = "X"
PLAYER_SYMBOL_2 = "O"

board = {}
rank = -1

gamemodes = {}

-- REGISTER ALL GAME MODES
gamemodes["Player vs AI"] = {
    init = function()
        while true do
            io.write( "AI turn (1 or 2): " )
            local turn = tonumber( io.read() )
            if turn == 1 or turn == 2 then
                if turn == 1 then
                    AITurn( -1 )
                end

                return
            end

            print( "Not valid answer!" )
        end
    end,
    process = function()
        DrawGlobalSeparator()
        DrawBoard()
        PlayerTurn( 1 )
        AITurn( -1 )
    end
}

gamemodes["Player vs Player"] ={
    init = function()
    end,
    process = function()
        DrawGlobalSeparator()

        DrawBoard()

        PlayerTurn( 1 )

        DrawBoard()

        PlayerTurn( -1 )
    end
}

gamemodes["AI vs AI (DEMO)"] ={
    init = function() end,
    process = function()
        DrawGlobalSeparator()
        DrawBoard()
        AITurn( 1 )
        AITurn( -1 )
    end
}

printf = function( s, ... )
    return io.write( s:format( ... ) )
end

GetTableLength = function( t )
    local getn = 0
    for n in pairs( t ) do
        getn = getn + 1
    end

    return getn
end

-- Setup board with given rank
function SetupBoard( irank )
    assert( irank >= 3 and irank <= 6, "Board rank must be 3, 4 or 5" )

    rank = irank

    for i = 0, ( rank - 1 ) do
        board[i] = {}
        for j = 0, ( rank - 1 ) do
            board[i][j] = nil
        end
    end
end

function GetFromUserRankOfBoard()
    while true do
        io.write( "Please, enter rank of board: " )
        local r = tonumber( io.read() )
        if r >= 3 and r <= 5 then
            return r
        end

        io.write( "Wrong, rank must be >= 3 and <= 5\n" )
    end
end

function GetFromUserGameMode()
    local idx = 1
    for i, v in pairs( gamemodes ) do
        print( idx .. ") " .. i )
        idx = idx + 1
    end

    while true do
        io.write( "Enter gamemode number you want to play: " )
        local num = tonumber( io.read() )
        if num > 0 and num <= idx then
            idx = 1
            for i, v in pairs( gamemodes ) do
                if idx == num then
                    return i
                end

                idx = idx + 1
            end
        end

        print( "Invalid number!" )
    end
end

function GetCell( x, y )
    assert( rank ~= -1, "Run 'SetupBoard' first" )
    assert( x >= 0 and x < rank and y >= 0 and y < rank, "Invlaid values for board checks" )

    return board[x][y]
end

function SetCell( x, y, value )
    assert( rank ~= -1, "Run 'SetupBoard' first" )
    assert( value == 1 or value == -1, "Invalid 'SetCell' value, must be equals to player number" )

    if x < 0 or x >= rank or y < 0 or y >= rank then
        return false
    end

    if board[x][y] ~= nil then
        return false
    end

    board[x][y] = value

    return true
end

function IsEmpty( x, y )
    assert( rank ~= -1, "Run 'SetupBoard' first" )

    return GetCell( x, y ) == nil
end

function GetEmptyCells()
    local ret = {}
    
    for i = 0, ( rank - 1 ) do
        for j = 0, ( rank - 1 ) do
            if IsEmpty( i, j ) then
                table.insert( ret, {i, j} )
            end
        end
    end

    return ret
end

function IsBoardFull()
    return GetTableLength( GetEmptyCells() ) == 0
end

function GetSymbolForNumber( number )
    if number == 1 then
        return PLAYER_SYMBOL_1
    elseif number == -1 then
        return PLAYER_SYMBOL_2
    else
        return " "
    end
end

function PlayerTurn( number )
    if IsGameOver() then return end

    local bPlaced = false
    while bPlaced == false do
        printf( "(%s)Where whould you like to play your turn?\n", GetSymbolForNumber( number ) )

        io.write( "X: " )
        local x = tonumber( io.read() )

        io.write( "Y: " )
        local y = tonumber( io.read() )

        bPlaced = SetCell( x - 1, y - 1, number )
        if bPlaced == false then
            print( "You can't play there!" )
        end
    end
end

function AITurn( number )
    local x
    local y
    local move

    if GetTableLength( GetEmptyCells() ) == rank * rank then
        x = math.random( 0, rank - 1 )
        y = math.random( 0, rank - 1 )
    else
        move = MinimaxAB( 0, number, -1000, 1000 )
        x = move[1]
        y = move[2]
    end

    SetCell( x, y, number )
end

function EvaluateMinimaxResultAB()
    local ret = 0

    if GetWinner() == -1 then
        ret = 1000
    elseif GetWinner() == 1 then
        ret = -1000
    end

    return ret
end

function MinimaxAB( depth, number, alpha, beta )
    local best

    if IsBoardFull() or EvaluateMinimaxResultAB() ~= 0 or depth == rank then
        return {-1, -1, EvaluateMinimaxResultAB()}
    end

    if number == -1 then
        best = {-1, -1, -1000}
    else
        best = {-1, -1, 1000}
    end

    for i, v in pairs( GetEmptyCells() ) do
        local x = v[1]
        local y = v[2]

        board[x][y] = number

        if number == -1 then
            local score = MinimaxAB( depth + 1, -number, alpha, beta )

            if best[3] < score[3] then
                best[1] = x
                best[2] = y
                best[3] = score[3] - depth * 10

                alpha = math.max( alpha, best[3] )
                board[x][y] = nil
                if beta <= alpha then
                    best[3] = alpha
                    break
                end
            end
        else
            local score = MinimaxAB( depth + 1, -number, alpha, beta )

            if best[3] > score[3] then
                best[1] = x
                best[2] = y
                best[3] = score[3] + depth * 10

                beta = math.min( beta, best[3] )
                board[x][y] = nil
                if beta <= alpha then
                    best[3] = alpha
                    break
                end
            end
        end

        board[x][y] = nil
    end

    return best
end

function GetWinner()
    assert( rank ~= -1, "Run 'SetupBoard' first" )

    -- Check horizontal lines
    for i = 0, ( rank - 1 ) do
        local val = GetCell( i, 0 )

        -- Do checks only if readed value not nil
        if val ~= nil then
            for j = 1, ( rank - 1 ) do
                local nval = GetCell( i, j )
                -- Finded nil, skip
                if nval == nil then val = nil; break end

                -- Not all values in line of same type, skip
                if val ~= nval then val = nil; break end
            end
            
            if val ~= nil then
                return val
            end
        end
    end

    -- Check vertical lines
    for i = 0, ( rank - 1 ) do
        local val = GetCell( 0, i )

        -- Do checks only if readed value not nil
        if val ~= nil then
            for j = 1, ( rank - 1 ) do
                local nval = GetCell( j, i )
                -- Finded nil, skip
                if nval == nil then val = nil; break end

                -- Not all values in line of same type, skip
                if val ~= nval then val = nil; break end
            end

            if val ~= nil then
                return val
            end
        end
    end

    -- Check diagonales
    local dval = GetCell( 0, 0 )
    if dval ~= nil then
        for i = 1, ( rank - 1 ) do
            local nval = GetCell( i, i )

            if nval == nil then dval = nil; break end
            if dval ~= nval then dval = nil; break end
        end

        if dval ~= nil then
            return dval
        end
    end

    dval = GetCell( 0, rank - 1 )
    if dval ~= nil then
        for i = 1, ( rank - 1 ) do
            local nval = GetCell( i, rank - i - 1 )

            if nval == nil then dval = nil; break end
            if dval ~= nval then dval = nil; break end
        end

        if dval ~= nil then
            return dval
        end
    end

    return nil
end

function IsGameOver()
    return GetWinner() ~= nil or GetTableLength( GetEmptyCells() ) == 0
end

function DrawGlobalSeparator()
    print()
    print( "+-----------------------------+" )
    print()
end

function DrawBoard()
    assert( rank ~= -1, "Run 'SetupBoard' first" )

    local hseparator = "+"
    for i = 0, ( rank - 1 ) do
        hseparator = hseparator .. "---+"
    end

    print( hseparator )

    for i = 0, ( rank - 1 ) do
        local line = "|"
        for j = 0, ( rank - 1 ) do
            if IsEmpty( j, i ) then
                line = line .. "   "
            else
                line = line .. " " .. GetSymbolForNumber( GetCell( j, i ) ) .. " "
            end

            line = line .. "|"
        end

        print( line )
        print( hseparator )
    end
end

print( "Welcome to Tic-Tac-Toe!\n" )

math.randomseed( os.time() )
for i = 0, 10 do
    math.random()
end

SetupBoard( GetFromUserRankOfBoard() )

local gamemode = GetFromUserGameMode()

gamemodes[gamemode]["init"]()
while true do
    gamemodes[gamemode]["process"]()

    if IsGameOver() then
        break
    end
end

DrawGlobalSeparator()
print( "Final board:" )
DrawBoard()

local winner = GetWinner()
if winner == nil then
    print( "No one wins!" )
else
    print( "Winner is: " .. GetSymbolForNumber( winner ) )
end
