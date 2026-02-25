/* EXERCISE 1 */

// Load Country and Contests (year) into Nodes

LOAD CSV WITH HEADERS FROM "file:///eurovision_location.csv" AS row
MERGE (contest:Contest {year: toInteger(row.Year)})
SET contest.city = row.Location
MERGE (winner:Country {name: row.Country})
MERGE (winner)-[:Winning_Entry]->(contest);

// SUCCESS Set 72 properties, completed after 13 ms.

// Load the Winning Artists and Song

LOAD CSV WITH HEADERS FROM "file:///Eurovision_Winners.csv" AS row
MATCH (contest:Contest {year: toInteger(row.Year)})
MATCH (winner:Country {name: row.Country})
MERGE (contest)-[entry:Winning_Entry]->(winner)
SET entry.artist = row.Artist,
    entry.song = row.Song,
    entry.points = toInteger(row.Total_Points);

// SUCCESS Set 216 properties, completed after 18 ms.

// Load the voting results

LOAD CSV WITH HEADERS FROM "file:///eurovision_results.csv" AS row
MATCH (contest:Contest {year: toInteger(row.Year)})
MERGE (from:Country {name: row.From})
MERGE (to:Country {name: row.To})
MERGE (contest)-[:Voting_Result]->(from)
MERGE (from)-[vote:VOTED_FOR {year: toInteger(row.Year)}]->(to)
SET vote.points = toInteger(row.Points);

// SUCCESS Set 16467 properties, completed after 1253 ms.

/* Exercise 2 */

// Countries with >2 wins

MATCH (contest:Contest)-[:Winning_Entry]->(country:Country)
WITH country, count(contest) AS wins
WHERE wins > 2
RETURN country.name AS country, wins
ORDER BY wins DESC;

// SUCCESS Completed after 8 ms.

/**
country,wins
Ireland,7
Sweden,7
Netherlands,5
France,5
Luxembourg,5
United Kingdom,5
Israel,4
Switzerland,3
Denmark,3
Italy,3
Austria,3
Norway,3
Ukraine,3
*/

/* Exercise 3 */

// Host countries that won their own contest
// The query should list the winning nations, the song they won with and the year in which
// they won returned in chronological order.

/* The "Country" given by `eurovision_location.csv` is the country that WON that years contest, not the host! 
As the previous winner of EuroVision hosts the next years context, can we assume that if a country wins two years
in a row, they have won their own hosted contest? */

MATCH (country:Country)<-[:Winning_Entry]-(contestOne:Contest)
MATCH (country)<-[entryTwo:Winning_Entry]-(contestTwo:Contest)
WHERE contestTwo.year = contestOne.year + 1
RETURN country.name AS WinningHostNation, entryTwo.song AS Song, contestTwo.year AS Year
ORDER BY Year;

/* A spot check of these values seems to be accurate. The only issue is 1956 where Switzerland won the first contest 
hosted in Lugano, Switzerland. As this wasn't a consecutive win, being the first contest, this query won't find it! I could
manually check for this contest, `WHERE (country.name = "Switzerland" AND contestOne.year = 1956)`, but this feels cheaty...

This query would also break if a country chose not to host the contest after a win, such as if Ukraine had won in 2023,
which would have been a consecutive win, but not a home win as the contest was hosted in the UK that year! 
TL;DR, the dataset is flawed. */

// SUCCESS Started streaming 5 records after 10 ms and completed after 13 ms.

/**
WinningHostNation,Song,Year
Spain,"\""Vivo cantando\""",1969
Luxembourg,"\""Tu te reconnaitras\""",1973
Israel,"\""Hallelujah\""",1979
Ireland,"\""In Your Eyes\""",1993
Ireland,"\""Rock 'n' Roll Kids\""",1994
*/

/* Exercise 4 */

// Produce a Neo4j query to identify all the persistent friendships between countries. 
// The query should list both countries and the number of points given. 
// The query result should be listed in alphabetical order by the country giving the points.

// Define persistent?

MATCH (from:Country)-[vote:VOTED_FOR]->(to:Country)
RETURN from.name AS GivingCountry, to.name AS ReceivingCountry, sum(vote.points) AS Points
ORDER BY GivingCountry, Points DESC;

// See https://github.com/corey-richardson/comp3007-cw1 for full query result of above
// Below query better captures "persistence" by counting the number of years that a 
// country has voted for another country, and filtering off single votes.

MATCH (from:Country)-[vote:VOTED_FOR]->(to:Country)
WITH from.name AS GivingCountry,
    to.name AS ReceivingCountry,
    count(vote) AS YearsVoted,
    sum(vote.points) AS Points
WHERE YearsVoted > 1
RETURN GivingCountry, ReceivingCountry, YearsVoted, Points
ORDER BY GivingCountry, YearsVoted DESC, Points DESC;

// SUCCESS Started streaming 1712 records after 7 ms and completed after 8 ms, displaying first 1000 rows.

/**
GivingCountry,ReceivingCountry,YearsVoted,Points
albania,greece,12,117
albania,sweden,11,55
albania,italy,9,74
albania,france,9,45
albania,serbia,8,19
albania,cyprus,7,46
albania,israel,7,39
albania,turkey,6,54
albania,germany,6,27
albania,switzerland,5,49
albania,norway,5,29
albania,estonia,5,26
albania,spain,5,24
albania,azerbaijan,5,21
albania,north macedonia,4,36
albania,armenia,4,24
albania,ukraine,4,23
albania,united kingdom,4,22
albania,russia,4,18
albania,bosnia & herzegovina,3,21
albania,san marino,3,17
albania,malta,3,15
albania,croatia,3,13
albania,finland,3,11
albania,moldova,3,10
albania,belgium,3,8
albania,australia,3,7
albania,portugal,3,7
albania,serbia & montenegro,2,13
albania,bulgaria,2,13
albania,luxembourg,2,12
albania,romania,2,10
albania,austria,2,9
albania,netherlands,2,9
albania,slovenia,2,4
armenia,france,13,78
armenia,greece,12,81
armenia,ukraine,11,70
armenia,russia,9,89
armenia,norway,8,34
armenia,georgia,7,60
armenia,sweden,7,42
armenia,spain,6,31
armenia,italy,6,30
armenia,portugal,4,34
armenia,switzerland,4,21
armenia,serbia,4,21
armenia,cyprus,4,20
armenia,austria,4,15
armenia,moldova,4,14
armenia,belarus,3,23
armenia,israel,3,19
armenia,malta,3,19
armenia,bulgaria,3,18
armenia,belgium,3,13
armenia,germany,3,12
armenia,united kingdom,3,12
armenia,denmark,3,10
armenia,romania,3,7
armenia,montenegro,2,20
armenia,finland,2,18
armenia,croatia,2,8
armenia,netherlands,2,7
armenia,bosnia & herzegovina,2,6
armenia,australia,2,6
armenia,ireland,2,5
armenia,estonia,2,5
armenia,latvia,2,3
armenia,poland,2,2
australia,sweden,8,70
australia,israel,6,47
australia,italy,6,26
australia,belgium,5,39
australia,united kingdom,5,33
australia,norway,5,33
australia,austria,5,24
australia,estonia,5,23
australia,spain,4,28
australia,lithuania,4,22
australia,france,4,20
australia,finland,4,14
australia,croatia,4,14
australia,denmark,3,19
australia,russia,3,19
australia,switzerland,3,18
australia,malta,3,18
australia,moldova,3,16
australia,cyprus,3,16
australia,portugal,3,15
australia,serbia,3,14
australia,the netherlands,3,13
australia,poland,3,10
australia,ukraine,3,10
australia,latvia,2,17
australia,bulgaria,2,16
australia,ireland,2,16
australia,greece,2,15
australia,germany,2,13
australia,czech republic,2,6
australia,azerbaijan,2,4
australia,armenia,2,2
austria,united kingdom,33,208
austria,germany,28,145
austria,switzerland,27,141
austria,sweden,26,173
austria,france,26,149
austria,ireland,25,171
austria,italy,21,124
austria,the netherlands,20,111
austria,norway,19,71
austria,belgium,19,61
austria,israel,18,102
austria,luxembourg,18,73
austria,spain,17,80
austria,denmark,16,89
austria,malta,11,61
austria,finland,10,54
austria,iceland,10,38
austria,greece,10,37
austria,croatia,9,56
austria,yugoslavia,9,37
austria,estonia,9,33
austria,monaco,9,28
austria,poland,8,57
austria,portugal,8,45
austria,turkey,7,40
austria,bosnia & herzegovina,6,49
austria,serbia,6,37
austria,russia,6,37
austria,cyprus,6,18
austria,ukraine,5,38
austria,armenia,5,28
austria,hungary,5,25
austria,slovenia,5,19
austria,romania,4,25
austria,latvia,4,23
austria,albania,4,21
austria,bulgaria,3,21
austria,moldova,3,15
austria,australia,2,24
austria,netherlands,2,10
austria,lithuania,2,8
austria,czech republic,2,7
azerbaijan,ukraine,14,107
azerbaijan,russia,10,91
azerbaijan,greece,10,52
azerbaijan,israel,9,69
azerbaijan,italy,9,62
azerbaijan,sweden,9,50
azerbaijan,norway,8,38
azerbaijan,georgia,7,50
azerbaijan,malta,7,45
azerbaijan,romania,7,37
azerbaijan,moldova,6,39
azerbaijan,spain,6,21
azerbaijan,france,6,18
azerbaijan,switzerland,5,29
azerbaijan,poland,5,16
azerbaijan,turkey,4,48
azerbaijan,belarus,4,27
azerbaijan,portugal,4,23
azerbaijan,albania,4,23
azerbaijan,hungary,4,21
azerbaijan,australia,4,16
azerbaijan,estonia,4,16
azerbaijan,slovenia,4,15
azerbaijan,lithuania,4,13
azerbaijan,cyprus,4,13
azerbaijan,united kingdom,3,19
azerbaijan,san marino,3,16
azerbaijan,finland,3,13
azerbaijan,bulgaria,3,11
azerbaijan,croatia,3,10
azerbaijan,austria,2,11
azerbaijan,ireland,2,11
azerbaijan,denmark,2,9
azerbaijan,serbia,2,8
azerbaijan,belgium,2,7
azerbaijan,netherlands,2,7
azerbaijan,bosnia & herzegovina,2,5
azerbaijan,germany,2,3
belarus,russia,5,45
belarus,ukraine,5,41
belarus,moldova,4,26
belarus,azerbaijan,4,24
belarus,armenia,4,22
belarus,norway,4,21
belarus,greece,4,18
belarus,the netherlands,3,13
belarus,romania,3,4
belarus,malta,2,19
belarus,georgia,2,13
belarus,hungary,2,13
belarus,sweden,2,10
belarus,slovenia,2,9
belarus,australia,2,9
belarus,israel,2,9
belarus,poland,2,9
belarus,iceland,2,9
belarus,lithuania,2,7
belarus,denmark,2,4
belgium,united kingdom,32,200
belgium,france,30,159
belgium,germany,30,157
belgium,sweden,29,157
belgium,ireland,27,153
belgium,italy,27,126
belgium,switzerland,26,147
belgium,spain,26,141
belgium,norway,26,135
belgium,the netherlands,26,128
belgium,austria,25,115
belgium,israel,19,116
belgium,luxembourg,15,76
belgium,yugoslavia,14,62
belgium,greece,13,53
belgium,portugal,13,52
belgium,denmark,12,74
belgium,monaco,10,40
belgium,turkey,9,50
belgium,malta,9,48
belgium,cyprus,9,41
belgium,finland,7,52
belgium,iceland,7,40
belgium,ukraine,7,34
belgium,russia,6,41
belgium,poland,6,32
belgium,armenia,5,28
belgium,australia,5,27
belgium,croatia,5,26
belgium,estonia,5,22
belgium,albania,5,20
belgium,latvia,4,34
belgium,azerbaijan,4,17
belgium,bulgaria,3,22
belgium,moldova,3,18
belgium,georgia,3,12
belgium,netherlands,2,13
belgium,romania,2,11
belgium,czechia,2,5
belgium,bosnia & herzegovina,2,2
bulgaria,ukraine,6,33
bulgaria,moldova,5,41
bulgaria,serbia,5,33
bulgaria,greece,4,38
bulgaria,armenia,4,29
bulgaria,israel,4,17
bulgaria,azerbaijan,4,13
bulgaria,sweden,4,8
bulgaria,austria,3,28
bulgaria,france,3,24
bulgaria,belgium,3,20
bulgaria,russia,3,18
bulgaria,italy,3,17
bulgaria,portugal,3,17
bulgaria,spain,3,16
bulgaria,the netherlands,3,14
bulgaria,cyprus,3,13
bulgaria,romania,3,9
bulgaria,poland,2,13
bulgaria,malta,2,12
bulgaria,lithuania,2,11
bulgaria,hungary,2,11
bulgaria,switzerland,2,10
bulgaria,belarus,2,3
croatia,bosnia & herzegovina,13,107
croatia,malta,11,82
croatia,united kingdom,10,64
croatia,slovenia,10,60
croatia,greece,10,51
croatia,norway,10,49
croatia,spain,9,48
croatia,sweden,9,40
croatia,cyprus,9,36
croatia,turkey,9,36
croatia,estonia,8,33
croatia,italy,7,54
croatia,russia,7,50
croatia,ukraine,7,46
croatia,ireland,7,40
croatia,france,7,33
croatia,germany,7,24
croatia,portugal,6,43
croatia,north macedonia,6,41
croatia,albania,6,37
croatia,israel,6,35
croatia,serbia,5,31
croatia,hungary,5,30
croatia,austria,5,24
croatia,moldova,5,18
croatia,switzerland,5,15
croatia,the netherlands,4,23
croatia,latvia,4,20
croatia,romania,4,19
croatia,iceland,4,14
croatia,finland,3,24
croatia,lithuania,3,15
croatia,belgium,3,11
croatia,serbia & montenegro,2,24
croatia,australia,2,18
croatia,denmark,2,15
croatia,poland,2,12
croatia,bulgaria,2,11
croatia,armenia,2,7
cyprus,greece,27,295
cyprus,france,22,111
cyprus,spain,20,131
cyprus,sweden,20,124
cyprus,united kingdom,20,76
cyprus,italy,18,109
cyprus,israel,16,94
cyprus,switzerland,15,64
cyprus,norway,14,70
cyprus,ireland,13,92
cyprus,malta,13,66
cyprus,russia,11,75
cyprus,austria,11,60
cyprus,belgium,11,54
cyprus,yugoslavia,9,59
cyprus,ukraine,9,55
cyprus,germany,9,55
cyprus,romania,9,41
cyprus,croatia,8,45
cyprus,the netherlands,8,32
cyprus,denmark,7,33
cyprus,armenia,7,27
cyprus,finland,7,24
cyprus,poland,7,18
cyprus,azerbaijan,6,37
cyprus,australia,6,36
cyprus,portugal,6,30
cyprus,estonia,6,24
cyprus,luxembourg,5,26
cyprus,iceland,5,24
cyprus,lithuania,5,21
cyprus,bulgaria,4,36
cyprus,moldova,4,19
cyprus,serbia,4,17
cyprus,albania,4,16
cyprus,latvia,4,9
cyprus,hungary,3,15
cyprus,serbia & montenegro,2,20
cyprus,turkey,2,12
cyprus,north macedonia,2,5
cyprus,slovenia,2,5
czech-republic,sweden,3,32
czech-republic,ukraine,2,24
czech-republic,russia,2,22
czech-republic,slovenia,2,17
czech-republic,israel,2,15
czech-republic,the netherlands,2,13
czech-republic,hungary,2,12
czech-republic,azerbaijan,2,11
czech-republic,austria,2,9
czech-republic,malta,2,9
czech-republic,bulgaria,2,9
czech-republic,australia,2,9
czech-republic,france,2,7
czech-republic,estonia,2,6
czech-republic,lithuania,2,4
czechia,ukraine,4,40
czechia,sweden,4,35
czechia,norway,4,16
czechia,israel,3,28
czechia,germany,3,18
czechia,estonia,3,16
czechia,portugal,3,12
czechia,finland,3,9
czechia,united kingdom,2,22
czechia,switzerland,2,16
czechia,poland,2,15
czechia,armenia,2,14
czechia,moldova,2,13
czechia,france,2,12
czechia,spain,2,10
czechia,australia,2,8
czechia,italy,2,7
czechia,croatia,2,6
czechia,lithuania,2,6
czechia,greece,2,5
denmark,sweden,37,299
denmark,united kingdom,32,161
denmark,germany,29,177
denmark,norway,27,166
denmark,switzerland,22,120
denmark,ireland,21,143
denmark,france,20,102
denmark,austria,19,94
denmark,iceland,18,115
denmark,israel,14,63
denmark,the netherlands,13,74
denmark,luxembourg,13,37
denmark,cyprus,12,59
denmark,belgium,12,57
denmark,estonia,11,57
denmark,italy,11,39
denmark,finland,10,51
denmark,spain,10,39
denmark,malta,9,61
denmark,greece,9,41
denmark,turkey,8,38
denmark,portugal,8,32
denmark,yugoslavia,7,53
denmark,ukraine,7,31
denmark,latvia,6,43
denmark,bosnia & herzegovina,6,32
denmark,romania,6,26
denmark,lithuania,6,18
denmark,russia,5,26
denmark,poland,5,22
denmark,australia,4,22
denmark,moldova,4,16
denmark,armenia,4,7
denmark,monaco,3,16
denmark,azerbaijan,3,14
denmark,hungary,2,6
denmark,bulgaria,2,5
estonia,sweden,19,159
estonia,russia,12,97
estonia,norway,12,74
estonia,germany,11,40
estonia,iceland,10,57
estonia,lithuania,10,27
estonia,finland,9,60
estonia,united kingdom,9,47
estonia,denmark,8,56
estonia,france,8,50
estonia,italy,8,45
estonia,ukraine,7,49
estonia,latvia,7,47
estonia,belgium,7,35
estonia,malta,7,28
estonia,ireland,6,38
estonia,israel,6,27
estonia,austria,5,40
estonia,poland,5,24
estonia,hungary,5,24
estonia,slovenia,5,19
estonia,spain,5,14
estonia,switzerland,4,38
estonia,australia,4,23
estonia,azerbaijan,4,23
estonia,croatia,4,20
estonia,the netherlands,4,19
estonia,portugal,3,13
estonia,cyprus,3,13
estonia,czech republic,2,13
estonia,greece,2,12
estonia,moldova,2,7
estonia,georgia,2,4
estonia,netherlands,2,2
finland,sweden,36,228
finland,united kingdom,30,160
finland,france,30,146
finland,italy,26,152
finland,ireland,25,122
finland,switzerland,23,145
finland,norway,22,131
finland,germany,21,91
finland,israel,18,136
finland,spain,18,96
finland,luxembourg,17,87
finland,belgium,16,82
finland,austria,16,70
finland,the netherlands,15,82
finland,portugal,14,40
finland,denmark,13,74
finland,yugoslavia,13,49
finland,greece,13,49
finland,estonia,12,106
finland,cyprus,9,55
finland,monaco,9,41
finland,malta,9,35
finland,turkey,9,33
finland,iceland,8,52
finland,ukraine,8,45
finland,russia,7,39
finland,hungary,6,57
finland,bosnia & herzegovina,5,25
finland,croatia,4,23
finland,lithuania,4,14
finland,moldova,4,12
finland,bulgaria,3,25
finland,serbia,3,21
finland,latvia,3,21
finland,azerbaijan,3,10
finland,armenia,3,6
finland,australia,2,16
finland,slovenia,2,11
finland,poland,2,11
france,sweden,34,157
france,united kingdom,33,207
france,italy,33,194
france,spain,33,185
france,israel,32,217
france,portugal,30,207
france,germany,27,162
france,the netherlands,25,153
france,belgium,25,149
france,ireland,25,120
france,switzerland,23,115
france,greece,22,121
france,luxembourg,19,97
france,austria,19,97
france,denmark,18,107
france,norway,17,76
france,turkey,16,141
france,finland,15,59
france,yugoslavia,15,43
france,armenia,14,104
france,russia,12,52
france,malta,12,49
france,monaco,12,42
france,ukraine,10,61
france,poland,10,48
france,romania,10,45
france,cyprus,10,39
france,moldova,8,48
france,bosnia & herzegovina,8,39
france,serbia,7,45
france,hungary,7,21
france,estonia,6,38
france,iceland,6,23
france,australia,5,24
france,slovenia,5,16
france,croatia,4,25
france,azerbaijan,4,21
france,bulgaria,3,20
france,latvia,3,18
france,albania,3,14
france,serbia & montenegro,2,16
france,czech republic,2,7
france,netherlands,2,7
france,czechia,2,6
france,lithuania,2,4
georgia,armenia,10,97
georgia,ukraine,10,84
georgia,azerbaijan,7,55
georgia,italy,7,54
georgia,lithuania,7,38
georgia,israel,7,22
georgia,russia,6,38
georgia,sweden,6,27
georgia,greece,6,24
georgia,latvia,5,29
georgia,norway,5,21
georgia,moldova,5,20
georgia,france,4,17
georgia,croatia,4,5
georgia,belgium,3,28
georgia,belarus,3,25
georgia,estonia,3,15
georgia,turkey,3,13
georgia,germany,3,5
georgia,denmark,2,17
georgia,switzerland,2,16
georgia,united kingdom,2,15
georgia,portugal,2,11
georgia,netherlands,2,11
georgia,australia,2,10
georgia,austria,2,8
georgia,spain,2,7
georgia,hungary,2,7
georgia,poland,2,6
georgia,finland,2,3
germany,united kingdom,36,199
germany,sweden,34,223
germany,france,34,191
germany,ireland,31,158
germany,italy,30,138
germany,switzerland,29,141
germany,norway,28,144
germany,the netherlands,27,136
germany,belgium,26,115
germany,israel,23,142
germany,spain,21,132
germany,greece,19,115
germany,denmark,19,115
germany,austria,19,108
germany,turkey,18,170
germany,finland,18,88
germany,malta,17,84
germany,luxembourg,17,83
germany,russia,14,90
germany,portugal,14,66
germany,poland,13,82
germany,iceland,13,55
germany,croatia,13,55
germany,monaco,11,56
germany,estonia,11,55
germany,cyprus,9,44
germany,yugoslavia,9,33
germany,ukraine,8,47
germany,australia,7,48
germany,serbia,7,44
germany,bosnia & herzegovina,7,35
germany,armenia,7,33
germany,hungary,6,30
germany,lithuania,6,9
germany,latvia,5,34
germany,albania,5,28
germany,romania,5,17
germany,moldova,4,22
germany,slovenia,4,13
germany,bulgaria,3,16
germany,azerbaijan,3,11
germany,serbia & montenegro,2,13
greece,france,26,154
greece,cyprus,25,265
greece,spain,25,146
greece,italy,20,108
greece,united kingdom,17,91
greece,portugal,17,68
greece,austria,16,92
greece,switzerland,16,91
greece,russia,14,81
greece,malta,14,75
greece,norway,14,74
greece,the netherlands,14,66
greece,sweden,14,65
greece,israel,13,54
greece,ireland,12,101
greece,belgium,12,77
greece,germany,12,45
greece,albania,11,78
greece,finland,11,75
greece,romania,11,66
greece,ukraine,11,59
greece,armenia,10,60
greece,azerbaijan,9,63
greece,croatia,9,37
greece,iceland,8,31
greece,moldova,7,43
greece,poland,7,32
greece,luxembourg,7,28
greece,denmark,6,39
greece,turkey,6,36
greece,georgia,6,27
greece,yugoslavia,6,18
greece,serbia,5,26
greece,estonia,4,27
greece,australia,4,20
greece,slovenia,4,19
greece,bulgaria,3,22
greece,latvia,3,14
greece,belarus,3,9
greece,monaco,2,16
greece,serbia & montenegro,2,14
greece,san marino,2,13
greece,netherlands,2,12
greece,bosnia & herzegovina,2,9
greece,hungary,2,8
greece,slovakia,2,7
greece,czechia,2,3
hungary,sweden,9,56
hungary,norway,7,30
hungary,the netherlands,6,47
hungary,russia,6,38
hungary,austria,6,35
hungary,poland,6,29
hungary,italy,6,24
hungary,denmark,5,36
hungary,united kingdom,5,35
hungary,greece,5,32
hungary,cyprus,5,27
hungary,romania,5,26
hungary,moldova,5,23
hungary,australia,4,34
hungary,malta,4,30
hungary,azerbaijan,4,30
hungary,iceland,4,29
hungary,belgium,4,27
hungary,ireland,4,27
hungary,ukraine,4,24
hungary,germany,4,24
hungary,spain,4,18
hungary,france,4,14
hungary,armenia,4,13
hungary,bulgaria,3,24
hungary,israel,3,19
hungary,estonia,3,15
hungary,latvia,3,14
hungary,turkey,3,10
hungary,georgia,3,10
hungary,portugal,2,19
hungary,albania,2,18
hungary,serbia,2,16
hungary,slovenia,2,14
hungary,croatia,2,12
hungary,czech republic,2,10
hungary,lithuania,2,8
hungary,switzerland,2,4
iceland,sweden,27,184
iceland,norway,21,138
iceland,denmark,20,167
iceland,france,18,113
iceland,finland,13,71
iceland,germany,13,64
iceland,switzerland,12,73
iceland,ireland,11,60
iceland,united kingdom,11,57
iceland,spain,11,32
iceland,portugal,10,61
iceland,estonia,10,58
iceland,italy,10,39
iceland,austria,8,61
iceland,cyprus,8,56
iceland,the netherlands,8,45
iceland,russia,8,32
iceland,poland,7,41
iceland,israel,7,39
iceland,ukraine,7,38
iceland,greece,7,33
iceland,yugoslavia,6,48
iceland,croatia,6,35
iceland,belgium,5,33
iceland,turkey,5,18
iceland,serbia,5,9
iceland,hungary,4,26
iceland,azerbaijan,4,23
iceland,malta,4,17
iceland,armenia,4,13
iceland,slovenia,4,11
iceland,lithuania,4,10
iceland,luxembourg,3,9
iceland,australia,2,22
iceland,netherlands,2,14
iceland,latvia,2,14
iceland,albania,2,11
iceland,romania,2,11
iceland,czechia,2,8
iceland,bosnia & herzegovina,2,5
ireland,united kingdom,41,216
ireland,germany,30,160
ireland,sweden,29,191
ireland,france,29,165
ireland,the netherlands,24,113
ireland,norway,21,115
ireland,switzerland,20,113
ireland,italy,19,103
ireland,israel,18,113
ireland,spain,18,83
ireland,belgium,17,103
ireland,finland,17,89
ireland,denmark,16,115
ireland,luxembourg,16,96
ireland,austria,16,95
ireland,malta,13,83
ireland,cyprus,12,60
ireland,yugoslavia,12,52
ireland,lithuania,11,79
ireland,estonia,11,68
ireland,portugal,10,48
ireland,ukraine,9,46
ireland,greece,9,31
ireland,iceland,8,42
ireland,monaco,8,38
ireland,croatia,7,33
ireland,russia,6,41
ireland,moldova,6,25
ireland,romania,6,24
ireland,turkey,6,16
ireland,latvia,5,30
ireland,poland,4,37
ireland,slovenia,4,24
ireland,hungary,3,21
ireland,serbia,3,10
ireland,azerbaijan,3,6
ireland,czechia,2,10
ireland,armenia,2,7
ireland,georgia,2,6
ireland,australia,2,6
ireland,bosnia & herzegovina,2,5
ireland,albania,2,4
israel,france,27,146
israel,united kingdom,24,164
israel,sweden,23,155
israel,the netherlands,20,118
israel,spain,19,104
israel,norway,18,107
israel,italy,18,89
israel,switzerland,17,85
israel,finland,17,81
israel,belgium,17,79
israel,denmark,16,87
israel,germany,13,95
israel,ukraine,13,77
israel,ireland,13,60
israel,cyprus,13,48
israel,russia,11,95
israel,greece,11,83
israel,austria,11,70
israel,luxembourg,10,59
israel,romania,9,68
israel,malta,9,51
israel,estonia,9,49
israel,yugoslavia,8,68
israel,armenia,8,52
israel,iceland,8,44
israel,croatia,7,40
israel,portugal,7,38
israel,turkey,7,30
israel,moldova,6,29
israel,azerbaijan,6,27
israel,australia,5,34
israel,latvia,5,34
israel,monaco,5,23
israel,lithuania,4,18
israel,bulgaria,4,16
israel,slovenia,4,14
israel,poland,4,13
israel,hungary,3,12
israel,georgia,3,9
israel,czech republic,2,13
israel,serbia,2,9
israel,czechia,2,6
italy,united kingdom,29,148
italy,france,27,142
italy,switzerland,25,121
italy,germany,24,116
italy,the netherlands,22,85
italy,spain,21,127
italy,ireland,19,128
italy,sweden,19,102
italy,norway,19,101
italy,austria,17,91
italy,luxembourg,17,79
italy,israel,16,96
italy,belgium,15,68
italy,denmark,14,69
italy,greece,14,60
italy,ukraine,12,85
italy,malta,12,68
italy,finland,12,48
italy,portugal,12,44
italy,monaco,11,56
italy,yugoslavia,9,32
italy,moldova,8,53
italy,iceland,8,43
italy,serbia,8,26
italy,cyprus,8,26
italy,estonia,7,41
italy,poland,7,29
italy,albania,6,45
italy,romania,6,43
italy,russia,5,43
italy,armenia,5,21
italy,lithuania,4,23
italy,australia,4,20
italy,turkey,3,23
italy,croatia,3,18
italy,hungary,3,9
italy,azerbaijan,2,19
italy,north macedonia,2,11
italy,san marino,2,9
italy,bulgaria,2,9
italy,georgia,2,8
italy,bosnia & herzegovina,2,7
latvia,sweden,10,76
latvia,lithuania,10,71
latvia,russia,9,88
latvia,ukraine,9,74
latvia,norway,9,42
latvia,estonia,8,73
latvia,israel,7,22
latvia,switzerland,6,38
latvia,finland,6,33
latvia,united kingdom,6,23
latvia,germany,6,20
latvia,france,5,28
latvia,malta,5,25
latvia,denmark,4,33
latvia,austria,4,25
latvia,croatia,4,22
latvia,armenia,4,18
latvia,ireland,4,9
latvia,georgia,3,16
latvia,belgium,3,16
latvia,spain,3,16
latvia,italy,3,13
latvia,australia,3,12
latvia,iceland,3,12
latvia,slovenia,3,9
latvia,moldova,2,15
latvia,cyprus,2,14
latvia,poland,2,13
latvia,greece,2,9
latvia,hungary,2,8
latvia,portugal,2,7
latvia,azerbaijan,2,7
latvia,serbia,2,5
latvia,bulgaria,2,3
latvia,romania,2,3
lithuania,sweden,14,82
lithuania,estonia,12,93
lithuania,ukraine,11,73
lithuania,france,11,60
lithuania,russia,10,66
lithuania,italy,9,54
lithuania,latvia,8,73
lithuania,norway,8,35
lithuania,united kingdom,6,32
lithuania,israel,6,30
lithuania,malta,6,22
lithuania,germany,6,20
lithuania,georgia,5,48
lithuania,azerbaijan,5,39
lithuania,portugal,5,35
lithuania,ireland,5,35
lithuania,belgium,5,28
lithuania,finland,5,26
lithuania,iceland,5,25
lithuania,denmark,5,21
lithuania,switzerland,4,30
lithuania,poland,4,30
lithuania,austria,4,25
lithuania,slovenia,4,19
lithuania,hungary,4,13
lithuania,moldova,4,13
lithuania,croatia,3,20
lithuania,australia,3,19
lithuania,serbia,3,11
lithuania,the netherlands,3,11
lithuania,cyprus,3,6
lithuania,netherlands,2,14
lithuania,belarus,2,8
lithuania,greece,2,8
lithuania,armenia,2,6
lithuania,bulgaria,2,4
lithuania,romania,2,3
luxembourg,united kingdom,30,180
luxembourg,france,28,143
luxembourg,switzerland,25,126
luxembourg,ireland,21,116
luxembourg,spain,20,91
luxembourg,italy,19,85
luxembourg,germany,18,95
luxembourg,sweden,17,79
luxembourg,the netherlands,16,82
luxembourg,portugal,15,81
luxembourg,israel,14,97
luxembourg,belgium,14,65
luxembourg,norway,13,49
luxembourg,monaco,12,43
luxembourg,yugoslavia,10,40
luxembourg,finland,10,36
luxembourg,denmark,9,37
luxembourg,greece,8,44
luxembourg,austria,8,37
luxembourg,malta,5,31
luxembourg,turkey,4,19
luxembourg,cyprus,3,15
luxembourg,iceland,2,13
luxembourg,latvia,2,10
luxembourg,lithuania,2,8
malta,united kingdom,21,130
malta,sweden,21,117
malta,greece,18,100
malta,italy,16,127
malta,cyprus,15,81
malta,norway,15,75
malta,ireland,13,85
malta,switzerland,13,82
malta,spain,12,75
malta,the netherlands,12,57
malta,ukraine,10,63
malta,israel,10,62
malta,germany,10,33
malta,turkey,9,63
malta,russia,9,50
malta,france,9,41
malta,finland,9,36
malta,croatia,8,72
malta,austria,8,44
malta,romania,7,47
malta,denmark,7,34
malta,portugal,7,22
malta,azerbaijan,6,41
malta,luxembourg,6,40
malta,estonia,6,36
malta,albania,6,32
malta,iceland,5,40
malta,serbia,5,20
malta,bosnia & herzegovina,5,18
malta,lithuania,5,16
malta,armenia,4,26
malta,poland,4,18
malta,yugoslavia,4,10
malta,latvia,3,22
malta,australia,3,12
malta,monaco,3,11
malta,belgium,3,10
malta,north macedonia,3,9
malta,slovenia,3,8
malta,san marino,3,5
malta,slovakia,2,20
malta,hungary,2,7
moldova,ukraine,13,108
moldova,romania,10,111
moldova,sweden,10,54
moldova,russia,9,72
moldova,greece,9,36
moldova,azerbaijan,8,57
moldova,norway,7,30
moldova,armenia,7,25
moldova,italy,6,45
moldova,estonia,6,39
moldova,israel,5,30
moldova,portugal,5,23
moldova,france,5,19
moldova,bulgaria,4,33
moldova,australia,4,22
moldova,belarus,4,20
moldova,georgia,4,19
moldova,lithuania,4,15
moldova,finland,3,18
moldova,switzerland,3,17
moldova,united kingdom,3,15
moldova,cyprus,3,11
moldova,spain,3,10
moldova,hungary,3,4
moldova,denmark,2,11
moldova,croatia,2,10
moldova,serbia,2,8
moldova,iceland,2,8
moldova,germany,2,6
moldova,belgium,2,6
moldova,austria,2,5
monaco,france,19,86
monaco,united kingdom,14,83
monaco,italy,14,55
monaco,spain,12,54
monaco,luxembourg,11,43
monaco,switzerland,11,38
monaco,germany,10,51
monaco,the netherlands,9,33
monaco,belgium,7,37
monaco,ireland,7,34
monaco,austria,6,26
monaco,portugal,6,22
monaco,finland,5,29
monaco,israel,5,26
monaco,norway,5,24
monaco,sweden,4,20
monaco,yugoslavia,3,18
monaco,greece,2,17
monaco,malta,2,5
monaco,denmark,2,4
montenegro,italy,4,23
montenegro,sweden,4,20
montenegro,ukraine,3,19
montenegro,estonia,3,14
montenegro,serbia,2,24
montenegro,albania,2,20
montenegro,switzerland,2,12
montenegro,slovenia,2,12
montenegro,armenia,2,11
montenegro,israel,2,10
montenegro,austria,2,10
montenegro,spain,2,10
montenegro,azerbaijan,2,9
montenegro,poland,2,8
montenegro,lithuania,2,5
montenegro,netherlands,2,5
netherlands,switzerland,4,38
netherlands,portugal,4,28
netherlands,sweden,3,21
netherlands,greece,3,21
netherlands,israel,3,19
netherlands,ukraine,3,18
netherlands,poland,3,18
netherlands,france,3,15
netherlands,estonia,3,14
netherlands,italy,3,11
netherlands,finland,2,16
netherlands,austria,2,13
netherlands,spain,2,12
netherlands,belgium,2,10
netherlands,norway,2,10
netherlands,lithuania,2,8
netherlands,australia,2,8
netherlands,germany,2,6
netherlands,latvia,2,4
norway,sweden,46,354
norway,france,35,189
norway,united kingdom,31,175
norway,ireland,30,174
norway,denmark,29,207
norway,switzerland,27,140
norway,israel,25,137
norway,finland,25,126
norway,germany,24,115
norway,spain,22,86
norway,belgium,21,90
norway,iceland,20,115
norway,italy,20,100
norway,the netherlands,19,114
norway,greece,17,78
norway,portugal,13,72
norway,cyprus,13,63
norway,malta,12,74
norway,austria,12,69
norway,turkey,11,43
norway,luxembourg,10,61
norway,russia,10,43
norway,estonia,9,45
norway,poland,9,42
norway,ukraine,9,26
norway,yugoslavia,8,42
norway,lithuania,8,41
norway,monaco,8,32
norway,romania,7,41
norway,croatia,7,39
norway,bosnia & herzegovina,5,42
norway,latvia,5,36
norway,australia,5,28
norway,azerbaijan,4,23
norway,moldova,4,17
norway,hungary,4,16
norway,serbia,3,19
norway,bulgaria,2,18
norway,czech republic,2,16
norway,armenia,2,11
norway,netherlands,2,10
norway,slovenia,2,7
norway,georgia,2,2
poland,sweden,14,100
poland,norway,11,61
poland,ukraine,10,97
poland,estonia,9,65
poland,france,9,46
poland,united kingdom,9,43
poland,germany,8,51
poland,greece,8,33
poland,israel,7,53
poland,croatia,7,33
poland,spain,7,22
poland,belgium,6,46
poland,italy,6,40
poland,switzerland,5,41
poland,australia,5,35
poland,russia,5,34
poland,ireland,5,30
poland,austria,5,24
poland,cyprus,5,21
poland,armenia,5,18
poland,finland,5,17
poland,lithuania,5,16
poland,slovenia,5,15
poland,the netherlands,4,32
poland,hungary,4,28
poland,portugal,4,26
poland,latvia,4,20
poland,malta,4,20
poland,denmark,4,17
poland,iceland,4,12
poland,romania,2,15
poland,moldova,2,13
poland,netherlands,2,13
poland,turkey,2,10
poland,bulgaria,2,9
poland,serbia,2,9
poland,azerbaijan,2,8
portugal,united kingdom,33,189
portugal,france,30,153
portugal,italy,29,196
portugal,spain,28,173
portugal,ireland,27,130
portugal,germany,26,169
portugal,sweden,26,125
portugal,belgium,22,118
portugal,switzerland,20,116
portugal,norway,20,85
portugal,israel,19,140
portugal,austria,17,78
portugal,the netherlands,16,75
portugal,denmark,16,57
portugal,luxembourg,15,97
portugal,greece,14,68
portugal,cyprus,11,38
portugal,yugoslavia,11,30
portugal,iceland,10,68
portugal,finland,10,42
portugal,malta,10,40
portugal,ukraine,9,61
portugal,monaco,9,31
portugal,croatia,8,40
portugal,moldova,7,54
portugal,estonia,5,31
portugal,russia,5,24
portugal,romania,4,23
portugal,bulgaria,3,27
portugal,lithuania,3,18
portugal,turkey,3,16
portugal,armenia,3,13
portugal,slovenia,3,12
portugal,poland,3,10
portugal,serbia,3,8
portugal,australia,2,17
portugal,latvia,2,15
portugal,albania,2,14
portugal,netherlands,2,12
portugal,hungary,2,3
romania,greece,15,109
romania,moldova,11,121
romania,turkey,11,70
romania,sweden,9,72
romania,russia,9,67
romania,hungary,9,57
romania,ukraine,9,43
romania,spain,9,39
romania,norway,9,39
romania,denmark,7,34
romania,israel,7,32
romania,germany,7,29
romania,italy,6,41
romania,cyprus,6,24
romania,azerbaijan,5,29
romania,united kingdom,5,28
romania,malta,5,27
romania,belgium,5,26
romania,armenia,5,25
romania,estonia,5,22
romania,france,5,18
romania,serbia,4,25
romania,poland,4,22
romania,ireland,4,20
romania,croatia,4,17
romania,australia,4,15
romania,albania,4,8
romania,north macedonia,3,25
romania,finland,3,18
romania,the netherlands,3,17
romania,switzerland,3,14
romania,slovenia,3,11
romania,austria,3,10
romania,bulgaria,2,15
romania,serbia & montenegro,2,14
romania,portugal,2,13
romania,latvia,2,7
russia,greece,14,76
russia,ukraine,13,92
russia,azerbaijan,11,102
russia,armenia,9,79
russia,france,9,61
russia,sweden,9,38
russia,cyprus,9,35
russia,norway,8,65
russia,moldova,8,52
russia,united kingdom,8,38
russia,malta,7,50
russia,georgia,7,45
russia,romania,7,39
russia,iceland,7,13
russia,belgium,6,36
russia,slovenia,6,35
russia,germany,6,34
russia,estonia,6,32
russia,lithuania,6,28
russia,spain,6,22
russia,latvia,6,22
russia,israel,5,32
russia,the netherlands,5,22
russia,hungary,5,15
russia,belarus,4,33
russia,italy,4,30
russia,denmark,4,27
russia,croatia,4,17
russia,austria,4,17
russia,serbia,4,16
russia,turkey,4,16
russia,switzerland,4,15
russia,ireland,3,22
russia,australia,3,10
russia,finland,2,16
russia,serbia & montenegro,2,16
russia,north macedonia,2,11
russia,poland,2,11
russia,bulgaria,2,10
san marino,italy,4,37
san marino,ukraine,4,22
san marino,sweden,4,12
san marino,israel,3,32
san marino,greece,3,29
san marino,switzerland,3,23
san marino,spain,3,20
san marino,lithuania,3,12
san marino,poland,3,11
san marino,estonia,2,17
san marino,finland,2,16
san marino,france,2,11
san marino,australia,2,11
san marino,portugal,2,11
san marino,austria,2,11
san marino,united kingdom,2,10
san marino,cyprus,2,8
san marino,moldova,2,7
san marino,norway,2,3
san-marino,italy,2,22
san-marino,greece,2,16
san-marino,azerbaijan,2,16
san-marino,iceland,2,14
san-marino,cyprus,2,13
san-marino,russia,2,11
san-marino,malta,2,11
san-marino,albania,2,9
san-marino,switzerland,2,6
san-marino,the netherlands,2,5
san-marino,finland,2,4
serbia,sweden,12,68
serbia,russia,8,53
serbia,italy,8,47
serbia,ukraine,8,47
serbia,greece,8,41
serbia,israel,8,39
serbia,slovenia,7,52
serbia,france,7,43
serbia,norway,6,30
serbia,bosnia & herzegovina,5,49
serbia,hungary,5,44
serbia,switzerland,5,28
serbia,estonia,5,24
serbia,armenia,5,12
serbia,finland,4,29
serbia,croatia,4,27
serbia,lithuania,4,24
serbia,cyprus,4,23
serbia,belgium,4,22
serbia,azerbaijan,4,22
serbia,bulgaria,4,18
serbia,portugal,4,15
serbia,north macedonia,3,34
serbia,germany,3,28
serbia,austria,3,18
serbia,moldova,3,18
serbia,malta,3,17
serbia,australia,3,16
serbia,the netherlands,3,15
serbia,denmark,3,11
serbia,spain,3,9
serbia,united kingdom,3,7
serbia,albania,3,6
serbia,iceland,2,12
serbia,romania,2,11
serbia,czech republic,2,9
serbia,czechia,2,4
serbia,latvia,2,2
slovakia,malta,3,34
slovakia,croatia,3,27
slovakia,ireland,3,17
slovakia,united kingdom,3,10
slovakia,cyprus,2,15
slovakia,greece,2,13
slovakia,poland,2,6
slovakia,iceland,2,2
slovenia,sweden,16,102
slovenia,norway,12,65
slovenia,estonia,10,62
slovenia,france,10,46
slovenia,italy,9,78
slovenia,switzerland,9,43
slovenia,croatia,8,70
slovenia,serbia,8,66
slovenia,austria,8,52
slovenia,spain,8,18
slovenia,denmark,7,46
slovenia,the netherlands,7,42
slovenia,united kingdom,7,36
slovenia,ireland,7,34
slovenia,israel,6,35
slovenia,cyprus,6,27
slovenia,bosnia & herzegovina,5,39
slovenia,ukraine,5,31
slovenia,germany,5,27
slovenia,iceland,5,23
slovenia,russia,4,32
slovenia,malta,4,18
slovenia,belgium,4,17
slovenia,greece,4,16
slovenia,poland,4,12
slovenia,lithuania,3,20
slovenia,albania,3,19
slovenia,latvia,3,18
slovenia,north macedonia,3,16
slovenia,moldova,3,14
slovenia,portugal,3,12
slovenia,luxembourg,3,10
slovenia,australia,3,8
slovenia,montenegro,2,17
slovenia,czech republic,2,15
slovenia,turkey,2,13
slovenia,netherlands,2,11
slovenia,hungary,2,8
spain,italy,36,239
spain,germany,36,239
spain,sweden,35,175
spain,united kingdom,35,166
spain,france,32,166
spain,portugal,31,184
spain,ireland,26,161
spain,greece,22,132
spain,belgium,22,116
spain,norway,22,75
spain,israel,21,141
spain,the netherlands,21,110
spain,switzerland,21,93
spain,austria,18,101
spain,malta,17,97
spain,luxembourg,17,71
spain,denmark,16,83
spain,romania,15,132
spain,ukraine,15,97
spain,finland,15,60
spain,iceland,13,62
spain,turkey,13,53
spain,yugoslavia,12,51
spain,cyprus,11,70
spain,monaco,11,39
spain,russia,10,57
spain,estonia,10,43
spain,armenia,9,60
spain,moldova,8,40
spain,croatia,7,41
spain,poland,6,22
spain,slovenia,6,16
spain,australia,5,41
spain,bulgaria,5,37
spain,azerbaijan,5,35
spain,latvia,5,29
spain,hungary,5,24
spain,lithuania,4,8
spain,bosnia & herzegovina,3,11
spain,serbia,3,11
spain,czech republic,2,10
sweden,norway,39,219
sweden,france,38,171
sweden,ireland,34,231
sweden,united kingdom,33,188
sweden,denmark,32,192
sweden,finland,25,165
sweden,germany,25,125
sweden,austria,24,111
sweden,israel,22,118
sweden,switzerland,22,116
sweden,the netherlands,21,116
sweden,belgium,21,79
sweden,iceland,19,125
sweden,italy,19,104
sweden,malta,17,87
sweden,greece,16,69
sweden,luxembourg,15,83
sweden,estonia,14,97
sweden,spain,14,77
sweden,cyprus,13,65
sweden,portugal,13,64
sweden,bosnia & herzegovina,11,74
sweden,ukraine,10,55
sweden,russia,10,49
sweden,yugoslavia,10,45
sweden,monaco,9,47
sweden,turkey,8,45
sweden,poland,8,34
sweden,australia,7,59
sweden,croatia,7,27
sweden,lithuania,7,26
sweden,hungary,6,39
sweden,armenia,6,18
sweden,azerbaijan,5,33
sweden,serbia,5,31
sweden,latvia,5,26
sweden,romania,5,16
sweden,slovenia,4,18
sweden,albania,4,12
sweden,bulgaria,3,17
sweden,czech republic,3,7
sweden,serbia & montenegro,2,16
sweden,moldova,2,10
sweden,netherlands,2,9
sweden,czechia,2,8
switzerland,united kingdom,39,218
switzerland,france,34,189
switzerland,italy,31,167
switzerland,ireland,27,180
switzerland,spain,27,156
switzerland,germany,27,131
switzerland,sweden,26,155
switzerland,israel,23,151
switzerland,the netherlands,20,116
switzerland,portugal,18,84
switzerland,norway,17,74
switzerland,finland,15,78
switzerland,austria,15,75
switzerland,greece,13,88
switzerland,luxembourg,13,53
switzerland,monaco,13,40
switzerland,denmark,13,35
switzerland,belgium,12,51
switzerland,malta,11,53
switzerland,cyprus,10,36
switzerland,turkey,9,62
switzerland,croatia,9,48
switzerland,yugoslavia,7,28
switzerland,serbia,6,43
switzerland,iceland,6,32
switzerland,albania,5,49
switzerland,bosnia & herzegovina,4,31
switzerland,ukraine,4,8
switzerland,north macedonia,3,18
switzerland,poland,3,14
switzerland,australia,3,10
switzerland,russia,3,8
switzerland,netherlands,2,16
switzerland,estonia,2,15
switzerland,latvia,2,15
switzerland,armenia,2,9
switzerland,hungary,2,5
switzerland,azerbaijan,2,3
the-netherlands,united kingdom,31,152
the-netherlands,france,30,164
the-netherlands,sweden,27,144
the-netherlands,norway,24,118
the-netherlands,belgium,23,134
the-netherlands,switzerland,22,145
the-netherlands,ireland,22,139
the-netherlands,germany,22,131
the-netherlands,denmark,20,115
the-netherlands,israel,20,107
the-netherlands,italy,20,78
the-netherlands,spain,18,78
the-netherlands,luxembourg,17,81
the-netherlands,portugal,15,82
the-netherlands,finland,15,55
the-netherlands,austria,14,74
the-netherlands,greece,13,63
the-netherlands,turkey,12,62
the-netherlands,malta,11,53
the-netherlands,iceland,9,54
the-netherlands,monaco,9,46
the-netherlands,cyprus,8,55
the-netherlands,yugoslavia,8,40
the-netherlands,russia,7,34
the-netherlands,estonia,6,33
the-netherlands,hungary,5,29
the-netherlands,poland,5,24
the-netherlands,ukraine,4,18
the-netherlands,croatia,4,13
the-netherlands,azerbaijan,4,9
the-netherlands,australia,3,18
the-netherlands,lithuania,3,15
the-netherlands,slovenia,3,11
the-netherlands,bulgaria,2,11
the-netherlands,czech republic,2,10
the-netherlands,armenia,2,9
the-netherlands,bosnia & herzegovina,2,5
the-netherlands,albania,2,2
turkey,united kingdom,20,120
turkey,ireland,20,119
turkey,spain,19,118
turkey,sweden,15,80
turkey,the netherlands,15,76
turkey,bosnia & herzegovina,14,119
turkey,germany,12,83
turkey,malta,12,78
turkey,italy,12,76
turkey,greece,12,65
turkey,france,12,38
turkey,austria,11,66
turkey,switzerland,11,60
turkey,yugoslavia,10,80
turkey,belgium,10,63
turkey,denmark,10,25
turkey,norway,9,51
turkey,portugal,9,47
turkey,israel,8,50
turkey,croatia,8,50
turkey,romania,8,28
turkey,russia,7,43
turkey,finland,7,33
turkey,luxembourg,7,26
turkey,albania,6,31
turkey,armenia,5,44
turkey,ukraine,5,32
turkey,north macedonia,5,24
turkey,iceland,5,23
turkey,azerbaijan,4,48
turkey,moldova,4,22
turkey,estonia,3,22
turkey,georgia,3,14
turkey,hungary,3,10
turkey,slovenia,2,13
ukraine,sweden,14,79
ukraine,russia,13,108
ukraine,azerbaijan,11,86
ukraine,norway,11,58
ukraine,moldova,10,71
ukraine,armenia,10,54
ukraine,lithuania,9,67
ukraine,israel,9,42
ukraine,estonia,8,27
ukraine,poland,7,49
ukraine,portugal,7,35
ukraine,georgia,6,45
ukraine,france,6,41
ukraine,croatia,6,35
ukraine,italy,6,33
ukraine,hungary,6,20
ukraine,switzerland,5,38
ukraine,united kingdom,5,35
ukraine,finland,5,31
ukraine,greece,5,28
ukraine,belgium,5,28
ukraine,malta,5,25
ukraine,latvia,5,24
ukraine,turkey,5,21
ukraine,australia,5,20
ukraine,romania,5,14
ukraine,belarus,4,42
ukraine,germany,4,29
ukraine,austria,3,16
ukraine,iceland,3,16
ukraine,ireland,3,13
ukraine,denmark,3,13
ukraine,slovenia,3,12
ukraine,spain,3,7
ukraine,bulgaria,3,6
ukraine,serbia & montenegro,2,15
ukraine,the netherlands,2,11
ukraine,czechia,2,8
ukraine,cyprus,2,8
ukraine,serbia,2,8
ukraine,north macedonia,2,6
ukraine,luxembourg,2,4
united kingdom,sweden,4,37
united kingdom,lithuania,4,29
united kingdom,israel,3,28
united kingdom,poland,3,26
united kingdom,ukraine,3,22
united kingdom,finland,3,20
united kingdom,estonia,3,14
united kingdom,greece,3,6
united kingdom,australia,2,16
united kingdom,spain,2,15
united kingdom,portugal,2,15
united kingdom,latvia,2,15
united kingdom,norway,2,13
united kingdom,switzerland,2,12
united kingdom,moldova,2,9
united kingdom,luxembourg,2,8
united kingdom,italy,2,7
united kingdom,france,2,4
united-kingdom,sweden,36,215
united-kingdom,ireland,35,243
united-kingdom,germany,33,171
united-kingdom,france,30,138
united-kingdom,switzerland,28,169
united-kingdom,the netherlands,27,109
united-kingdom,belgium,26,117
united-kingdom,denmark,25,129
united-kingdom,austria,25,126
united-kingdom,spain,25,80
united-kingdom,israel,24,134
united-kingdom,norway,22,128
united-kingdom,italy,19,75
united-kingdom,malta,18,109
united-kingdom,turkey,18,94
united-kingdom,greece,16,120
united-kingdom,cyprus,16,87
united-kingdom,luxembourg,16,87
united-kingdom,finland,15,78
united-kingdom,iceland,13,90
united-kingdom,yugoslavia,12,69
united-kingdom,monaco,12,55
united-kingdom,portugal,11,55
united-kingdom,lithuania,10,66
united-kingdom,estonia,9,59
united-kingdom,russia,9,50
united-kingdom,latvia,8,47
united-kingdom,ukraine,8,44
united-kingdom,croatia,6,21
united-kingdom,australia,5,37
united-kingdom,bulgaria,5,30
united-kingdom,poland,5,28
united-kingdom,romania,4,25
united-kingdom,moldova,4,20
united-kingdom,hungary,4,13
united-kingdom,azerbaijan,3,12
united-kingdom,albania,3,9
united-kingdom,slovenia,2,16
united-kingdom,czech republic,2,6
united-kingdom,serbia,2,3
yugoslavia,italy,18,94
yugoslavia,ireland,17,64
yugoslavia,united kingdom,16,95
yugoslavia,france,16,93
yugoslavia,switzerland,14,80
yugoslavia,sweden,14,70
yugoslavia,spain,14,49
yugoslavia,the netherlands,13,67
yugoslavia,luxembourg,12,61
yugoslavia,germany,10,52
yugoslavia,israel,9,61
yugoslavia,belgium,9,42
yugoslavia,austria,9,41
yugoslavia,cyprus,8,52
yugoslavia,finland,8,39
yugoslavia,monaco,7,32
yugoslavia,turkey,6,42
yugoslavia,portugal,6,30
yugoslavia,norway,6,27
yugoslavia,malta,5,17
yugoslavia,greece,4,17
yugoslavia,denmark,2,7
*/

